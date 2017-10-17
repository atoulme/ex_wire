defmodule ExWire.Handler do
  @moduledoc """
  Defines a behavior for all message handlers of RLPx messages.

  Message handlers tell us how we should respond to a given incoming transmission,
  after it has been decoded.
  """

  alias ExWire.Message
  alias ExWire.Crypto

  require Logger

  @handlers %{
    0x01 => ExWire.Handler.Ping,
    0x02 => ExWire.Handler.Pong,
    0x03 => ExWire.Handler.FindNeighbours,
    0x04 => ExWire.Handler.Neighbours,
  }

  defmodule Params do
    @moduledoc "Struct to store parameters from an incoming message"

    defstruct [
      remote_host: nil,
      signature: nil,
      recovery_id: nil,
      hash: nil,
      type: nil,
      data: nil,
      timestamp: nil,
      node_id: nil
    ]

    @type t :: %__MODULE__{
      remote_host: ExWire.Struct.Endpoint.t,
      signature: Crpyto.signature,
      recovery_id: Crypto.recovery_id,
      hash: Crypto.hash,
      type: integer(),
      data: binary(),
      timestamp: integer(),
      node_id: ExWire.node_id,
    }
  end

  @type handler_response :: :not_implented | :no_response | {:respond, Message.t}
  @callback handle(Params.t) :: handler_response

  @doc """
  Decides which module to route the given message to,
  or returns `:not_implemented` if we have no implemented
  a handler for the message type.

  ## Examples

      iex> ExWire.Handler.dispatch(0x01, %ExWire.Handler.Params{
      ...>   remote_host: %ExWire.Struct.Endpoint{ip: {1, 2, 3, 4}, udp_port: 55},
      ...>   signature: 2,
      ...>   recovery_id: 3,
      ...>   hash: <<5>>,
      ...>   data: [1, [<<1,2,3,4>>, <<>>, <<5>>], [<<5,6,7,8>>, <<6>>, <<>>], 4] |> ExRLP.encode(),
      ...>   timestamp: 123,
      ...> }, nil)
      {:respond, %ExWire.Message.Pong{
        hash: <<5>>,
        timestamp: 123,
        to: %ExWire.Struct.Endpoint{
          ip: {1, 2, 3, 4},
          tcp_port: 5,
          udp_port: nil
        }
      }}

      iex> ExWire.Handler.dispatch(0x99, %ExWire.Handler.Params{}, nil)
      :not_implemented

      # TODO: Add a `no_response` test case
  """
  @spec dispatch(integer(), Params.t, identifier() | nil) :: handler_response
  def dispatch(type, params, discovery) do
    case @handlers[type] do
      nil ->
        Logger.warn("Message code `#{inspect type, base: :hex}` not implemented")
        :not_implemented
      mod when is_atom(mod) -> apply(mod, :handle, [params, discovery])
    end
  end

end
defmodule WebSockAdapter do
  @moduledoc """
  Defines adapters to allow common Web Servers to serve applications via the `WebSock` API.
  Also provides a consistent upgrade facility to upgrade `Plug.Conn` requests to `WebSock`
  connections for supported servers.
  """

  @typedoc "The type of a supported connection option"
  @type connection_opt ::
          {:compress, boolean()}
          | {:timeout, timeout()}
          | {:max_frame_size, non_neg_integer()}
          | {:fullsweep_after, non_neg_integer()}

  @doc """
  Upgrades the provided `Plug.Conn` connection request to a `WebSock` connection using the
  provided `WebSock` compliant module as a handler.

  This function returns the passed `conn` set to an `:upgraded` state.

  The provided `state` value will be used as the argument for `c:WebSock.init/1` once the WebSocket
  connection has been successfully negotiated.

  The `opts` keyword list argument allows a number of options to be set on the WebSocket
  connection. Not all options may be supported by the underlying HTTP server. Possible values are
  as follows:

  * `timeout`: The number of milliseconds to wait after no client data is received before
   closing the connection. Defaults to `60_000`
  * `compress`: Whether or not to accept negotiation of a compression extension with the client.
   Defaults to `false`
  * `max_frame_size`: The maximum frame size to accept, in octets. If a frame size larger than this
   is received the connection will be closed. Defaults to `:infinity`
  * `:fullsweep_after`: The maximum number of garbage collections before forcing a fullsweep of
   the WebSocket connection process. Setting this option requires OTP 24 or newer
  """
  @spec upgrade(Plug.Conn.t(), WebSock.impl(), WebSock.state(), [connection_opt()]) ::
          Plug.Conn.t()
  def upgrade(%{adapter: {adapter, _}} = conn, websock, state, opts) do
    Plug.Conn.upgrade_adapter(conn, :websocket, tuple_for(adapter, websock, state, opts))
  end

  defp tuple_for(Bandit.HTTP1.Adapter, websock, state, opts), do: {websock, state, opts}
  defp tuple_for(Bandit.HTTP2.Adapter, websock, state, opts), do: {websock, state, opts}

  defp tuple_for(Plug.Cowboy.Conn, websock, state, opts) do
    cowboy_opts =
      opts
      |> Enum.flat_map(fn
        {:timeout, timeout} -> [idle_timeout: timeout]
        {:compress, _} = opt -> [opt]
        {:max_frame_size, _} = opt -> [opt]
        _other -> []
      end)
      |> Map.new()

    process_flags =
      opts
      |> Keyword.take([:fullsweep_after])
      |> Map.new()

    {WebSockAdapter.CowboyAdapter, {websock, process_flags, state}, cowboy_opts}
  end

  defp tuple_for(adapter, _websock, _state, _opts),
    do: raise(ArgumentError, "Unknown adapter #{inspect(adapter)}")
end

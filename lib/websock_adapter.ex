defmodule WebSockAdapter do
  @moduledoc """
  Defines adapters to allow common Web Servers to serve applications via the `WebSock` API.
  Also provides a consistent upgrade facility to upgrade `Plug.Conn` requests to `WebSock`
  connections for supported servers.

  Cowboy needs a dedicated adapter, which this library provides. All other servers get the
  `{websock, state, opts}` tuple as the argument to `Plug.Conn.upgrade_adapter/3` with a
  protocol of `:websocket`. To support `WebSock` in a server, make its `Plug.Conn.Adapter`
  accept this tuple in `c:Plug.Conn.Adapter.upgrade/3`. Bandit and Roadrunner do this.
  """

  @typedoc "The type of a supported connection option"
  @type connection_opt ::
          {:compress, boolean()}
          | {:timeout, timeout()}
          | {:max_frame_size, non_neg_integer()}
          | {:fullsweep_after, non_neg_integer()}
          | {:max_heap_size, :erlang.max_heap_size()}
          | {:validate_utf8, boolean()}
          | {:active_n, integer()}

  @doc """
  Upgrades the provided `Plug.Conn` connection request to a `WebSock` connection using the
  provided `WebSock` compliant module as a handler.

  This function returns the passed `conn` set to an `:upgraded` state. If `early_validate_upgrade`
  is set to true (as it is by default), the request is first examined to determine if it
  represents a valid WebSocket upgrade. If errors are discovered in the request, a
  `WebSockAdapter.UpgradeError` is raised containing information about the failure

  If the underlying server does not support WebSocket upgrades, `Plug.Conn.upgrade_adapter/3`
  raises an `ArgumentError`

  The provided `state` value will be used as the argument for `c:WebSock.init/1` once the WebSocket
  connection has been successfully negotiated.

  The `opts` keyword list argument allows a number of options to be set on the WebSocket
  connection. Not all options may be supported by the underlying HTTP server. Possible values are
  as follows:

  * `early_validate_upgrade`: A boolean indicating whether or not WebSockAdapter should attempt to
  validate the WebSocket upgrade request before returning from this call. The underlying webserver
  may still perform its own validation during the actual upgrade process, but since this occurs
  after the `c:Plug.call/2` lifecycle it can be difficult to meaningfully handle failed upgrades.
  Having WebSockAdapter do its own checks as part of this call helps to alleviate this. Defaults
  to `true`
  * `timeout`: The number of milliseconds to wait after no client data is received before
   closing the connection. Defaults to `60_000`
  * `compress`: Whether or not to accept negotiation of a compression extension with the client.
   Defaults to `false`
  * `max_frame_size`: The maximum frame size to accept, in octets. If a frame size larger than this
   is received the connection will be closed. Defaults to `10_000_000` (10MB)
  * `fullsweep_after`: The maximum number of garbage collections before forcing a fullsweep of
   the WebSocket connection process. Setting this option requires OTP 24 or newer
  * `max_heap_size`: The maximum size of the websocket process heap in words, or a configuration
    map. See `:erlang.max_heap_size()` for more info
  * `validate_utf8`: Whether the server should verify that the payload of text and close frames is valid UTF-8.
    This is required by the protocol specification but in some cases it may be more interesting to disable it
    in order to save resources. Note that binary frames do not have this UTF-8 requirement and are what should be
    used under normal circumstances if necessary
  * `active_n`: (Cowboy only) The number of packets Cowboy will request from the socket at once. This can be used to tweak
    the performance of the server. Higher values reduce the number of times Cowboy need to request more
    packets from the port driver at the expense of potentially higher memory being used.
    This option does not apply to Websocket over HTTP/2
  * `deflate_options`: A keyword list of options to pass to the deflate library.
    See `Bandit` or `:cow_ws` documentation for more details
  """
  @spec upgrade(Plug.Conn.t(), WebSock.impl(), WebSock.state(), [connection_opt()]) ::
          Plug.Conn.t()
  def upgrade(%{adapter: {adapter, _}} = conn, websock, state, opts) do
    opts = Keyword.put_new(opts, :max_frame_size, 10_000_000)

    if Keyword.get(opts, :early_validate_upgrade, true) do
      WebSockAdapter.UpgradeValidation.validate_upgrade!(conn)
    end

    # Plug.Conn.upgrade_adapter/3 raises if the adapter does not support WebSocket upgrades
    Plug.Conn.upgrade_adapter(conn, :websocket, tuple_for(adapter, websock, state, opts))
  end

  defp tuple_for(Plug.Cowboy.Conn, websock, state, opts) do
    cowboy_opts =
      opts
      |> Enum.flat_map(fn
        {:timeout, timeout} -> [idle_timeout: timeout]
        {:compress, _} = opt -> [opt]
        {:max_frame_size, _} = opt -> [opt]
        {:validate_utf8, _} = opt -> [opt]
        {:active_n, _} = opt -> [opt]
        {:deflate_options, deflate_options} -> [deflate_opts: deflate_options]
        _other -> []
      end)
      |> Map.new()

    process_flags =
      opts
      |> Keyword.take([:fullsweep_after, :max_heap_size])
      |> Map.new()

    {WebSockAdapter.CowboyAdapter, {websock, process_flags, state}, cowboy_opts}
  end

  # Bandit, Roadrunner, Plug.Adapters.Test.Conn and other servers take this tuple as is
  defp tuple_for(_adapter, websock, state, opts), do: {websock, state, opts}
end

defmodule WebSockAdapter.Plug do
  @moduledoc """
  Basic plug to upgrade a connection to `WebSock` connections without a separate plug.

  This simplifies basic usage of `WebSockAdapter` in combination with plug accepting
  functions like starting a webserver or hooking into routers, where handler
  implementation and initial state are static.

  For any more advanced cases consider using a custom plug.

  ## Example

      opts = [
        impl: HandlerModule,
        state: [initial: :state]
      ]

      Bandit.start_link(port: 4000, plug: {WebSockAdapter.Plug, opts})

  ## Options

  - `:impl` - Sets the handler implementation module. Required.
  - `:state` - Sets the handlers initial state. Required.

  Any further options will be forwarded to `WebSockAdapter.upgrade/4`.

  """
  @behaviour Plug

  def init(opts) do
    {impl, opts} = Keyword.pop!(opts, :impl)
    {state, opts} = Keyword.pop!(opts, :state)

    %{impl: impl, state: state, opts: opts}
  end

  def call(conn, opts) do
    WebSockAdapter.upgrade(conn, opts.impl, opts.state, opts.opts)
  end
end

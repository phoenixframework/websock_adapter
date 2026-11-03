defmodule WebSockAdapter.ConnAdapter do
  @moduledoc """
  A behaviour for WebSockAdapter-compatible `Plug.Conn.Adapter` implementations.

  A compatible adapter's `upgrade/3` must accept `{websock, state, opts}` as args
  for `:websocket`.
  """

  @callback websock_upgrade?() :: true

  @doc "Implements the behaviour."
  defmacro __using__(_opts) do
    quote do
      @behaviour WebSockAdapter.ConnAdapter

      @doc false
      def websock_upgrade?, do: true
    end
  end
end

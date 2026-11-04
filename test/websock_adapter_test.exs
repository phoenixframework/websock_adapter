defmodule WebSockAdapterTest do
  use ExUnit.Case, async: true

  test "upgrades Bandit connections and handles all options" do
    opts = [compress: true, timeout: 1, max_frame_size: 2, fullsweep_after: 3, other: :ok]

    %Plug.Conn{adapter: {Bandit.Adapter, adapter}} =
      %Plug.Conn{
        adapter:
          {Bandit.Adapter,
           %Bandit.Adapter{
             transport: %Bandit.HTTP1.Socket{version: :"HTTP/1.1"},
             opts: %{websocket: []}
           }}
      }
      |> Map.put(:method, "GET")
      |> Map.update!(:req_headers, &[{"host", "server.example.com"} | &1])
      |> Plug.Conn.put_req_header("upgrade", "WeBsOcKeT")
      |> Plug.Conn.put_req_header("connection", "UpGrAdE")
      |> Plug.Conn.put_req_header("sec-websocket-key", "dGhlIHNhbXBsZSBub25jZQ==")
      |> Plug.Conn.put_req_header("sec-websocket-version", "13")
      |> WebSockAdapter.upgrade(:sock, :arg, opts)

    assert adapter.upgrade == {:websocket, {:sock, :arg, opts}, []}
  end

  test "upgrades Cowboy connections and handles all options" do
    opts = [compress: true, timeout: 1, max_frame_size: 2, fullsweep_after: 3, other: :ok]

    %Plug.Conn{adapter: {Plug.Cowboy.Conn, adapter}} =
      %Plug.Conn{adapter: {Plug.Cowboy.Conn, %{version: :"HTTP/1.1"}}}
      |> Map.put(:method, "GET")
      |> Map.update!(:req_headers, &[{"host", "server.example.com"} | &1])
      |> Plug.Conn.put_req_header("upgrade", "WeBsOcKeT")
      |> Plug.Conn.put_req_header("connection", "UpGrAdE")
      |> Plug.Conn.put_req_header("sec-websocket-key", "dGhlIHNhbXBsZSBub25jZQ==")
      |> Plug.Conn.put_req_header("sec-websocket-version", "13")
      |> WebSockAdapter.upgrade(:sock, :arg, opts)

    assert adapter.upgrade ==
             {:websocket,
              {WebSockAdapter.CowboyAdapter, {:sock, %{fullsweep_after: 3}, :arg},
               %{compress: true, idle_timeout: 1, max_frame_size: 2}}}
  end

  test "upgrades Roadrunner connections and handles all options" do
    opts = [compress: true, timeout: 1, max_frame_size: 2, fullsweep_after: 3, other: :ok]

    %Plug.Conn{adapter: {Roadrunner.Plug.Adapter, adapter}} =
      %Plug.Conn{
        adapter: {Roadrunner.Plug.Adapter, %{req: %{version: {1, 1}}, send: nil, upgrade: nil}}
      }
      |> Map.put(:method, "GET")
      |> Map.update!(:req_headers, &[{"host", "server.example.com"} | &1])
      |> Plug.Conn.put_req_header("upgrade", "WeBsOcKeT")
      |> Plug.Conn.put_req_header("connection", "UpGrAdE")
      |> Plug.Conn.put_req_header("sec-websocket-key", "dGhlIHNhbXBsZSBub25jZQ==")
      |> Plug.Conn.put_req_header("sec-websocket-version", "13")
      |> WebSockAdapter.upgrade(:sock, :arg, opts)

    assert adapter.upgrade == {:sock, :arg, opts}
  end

  test "raises an error on invalid websocket upgrade requests" do
    assert_raise WebSockAdapter.UpgradeError, "HTTP method POST unsupported", fn ->
      %Plug.Conn{
        adapter:
          {Bandit.Adapter,
           %Bandit.Adapter{
             transport: %Bandit.HTTP1.Socket{version: :"HTTP/1.1"},
             opts: %{websocket: []}
           }}
      }
      |> Map.put(:method, "POST")
      |> Map.update!(:req_headers, &[{"host", "server.example.com"} | &1])
      |> Plug.Conn.put_req_header("upgrade", "WeBsOcKeT")
      |> Plug.Conn.put_req_header("connection", "UpGrAdE")
      |> Plug.Conn.put_req_header("sec-websocket-key", "dGhlIHNhbXBsZSBub25jZQ==")
      |> Plug.Conn.put_req_header("sec-websocket-version", "13")
      |> WebSockAdapter.upgrade(:sock, :arg, [])
    end
  end

  test "does not raise an error on invalid websocket upgrade requests if so configured" do
    %Plug.Conn{adapter: {Bandit.Adapter, adapter}} =
      %Plug.Conn{
        adapter:
          {Bandit.Adapter,
           %Bandit.Adapter{
             transport: %Bandit.HTTP1.Socket{version: :"HTTP/1.1"},
             opts: %{websocket: []}
           }}
      }
      |> Map.put(:method, "POST")
      |> Map.update!(:req_headers, &[{"host", "server.example.com"} | &1])
      |> Plug.Conn.put_req_header("upgrade", "WeBsOcKeT")
      |> Plug.Conn.put_req_header("connection", "UpGrAdE")
      |> Plug.Conn.put_req_header("sec-websocket-key", "dGhlIHNhbXBsZSBub25jZQ==")
      |> Plug.Conn.put_req_header("sec-websocket-version", "13")
      |> WebSockAdapter.upgrade(:sock, :arg, early_validate_upgrade: false)

    assert adapter.upgrade ==
             {:websocket,
              {:sock, :arg, max_frame_size: 10_000_000, early_validate_upgrade: false}, []}
  end

  defmodule OtherServer do
    def get_http_protocol(_payload), do: :"HTTP/1.1"
    def upgrade(payload, :websocket, args), do: {:ok, Map.put(payload, :upgrade, args)}
  end

  defmodule UnsupportedServer do
    def get_http_protocol(_payload), do: :"HTTP/1.1"
    def upgrade(_payload, _protocol, _args), do: {:error, :not_supported}
  end

  test "upgrades connections of other adapters with a generic tuple" do
    %Plug.Conn{adapter: {OtherServer, adapter}} =
      %Plug.Conn{adapter: {OtherServer, %{}}}
      |> Map.put(:method, "GET")
      |> Map.update!(:req_headers, &[{"host", "server.example.com"} | &1])
      |> Plug.Conn.put_req_header("upgrade", "WeBsOcKeT")
      |> Plug.Conn.put_req_header("connection", "UpGrAdE")
      |> Plug.Conn.put_req_header("sec-websocket-key", "dGhlIHNhbXBsZSBub25jZQ==")
      |> Plug.Conn.put_req_header("sec-websocket-version", "13")
      |> WebSockAdapter.upgrade(:sock, :arg, opt_key: :opt_value)

    assert adapter.upgrade == {:sock, :arg, max_frame_size: 10_000_000, opt_key: :opt_value}
  end

  test "raises an error on upgrade requests to adapters without WebSocket support" do
    message = "upgrade to websocket not supported by WebSockAdapterTest.UnsupportedServer"

    assert_raise ArgumentError, message, fn ->
      %Plug.Conn{adapter: {UnsupportedServer, %{}}}
      |> Map.put(:method, "GET")
      |> Map.update!(:req_headers, &[{"host", "server.example.com"} | &1])
      |> Plug.Conn.put_req_header("upgrade", "WeBsOcKeT")
      |> Plug.Conn.put_req_header("connection", "UpGrAdE")
      |> Plug.Conn.put_req_header("sec-websocket-key", "dGhlIHNhbXBsZSBub25jZQ==")
      |> Plug.Conn.put_req_header("sec-websocket-version", "13")
      |> WebSockAdapter.upgrade(:sock, :arg, [])
    end
  end
end

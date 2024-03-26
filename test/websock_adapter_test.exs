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

    assert adapter.upgrade == {:websocket, {:sock, :arg, early_validate_upgrade: false}, []}
  end

  test "raises an error on unknown adapter upgrade requests" do
    assert_raise ArgumentError, "Unknown adapter OtherServer", fn ->
      %Plug.Conn{adapter: {OtherServer, %{}}}
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

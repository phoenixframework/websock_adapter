defmodule UpgradeValidationTest do
  use ExUnit.Case, async: true

  test "accepts well formed HTTP/1.1 requests" do
    conn =
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

    assert WebSockAdapter.UpgradeValidation.validate_upgrade(conn) == :ok
    assert WebSockAdapter.UpgradeValidation.validate_upgrade!(conn) == :ok
  end

  test "accepts well formed HTTP/2 requests" do
    conn =
      %Plug.Conn{adapter: {Bandit.Adapter, %Bandit.Adapter{transport: %Bandit.HTTP2.Stream{}}}}
      |> Map.put(:method, "CONNECT")
      |> Plug.Conn.put_req_header("sec-websocket-version", "13")

    assert WebSockAdapter.UpgradeValidation.validate_upgrade(conn) == :ok
    assert WebSockAdapter.UpgradeValidation.validate_upgrade!(conn) == :ok
  end

  test "does not accept HTTP/1.0 requests" do
    conn =
      %Plug.Conn{
        adapter:
          {Bandit.Adapter, %Bandit.Adapter{transport: %Bandit.HTTP1.Socket{version: :"HTTP/1.0"}}}
      }
      |> Map.put(:method, "GET")
      |> Map.update!(:req_headers, &[{"host", "server.example.com"} | &1])
      |> Plug.Conn.put_req_header("upgrade", "WeBsOcKeT")
      |> Plug.Conn.put_req_header("connection", "UpGrAdE")
      |> Plug.Conn.put_req_header("sec-websocket-key", "dGhlIHNhbXBsZSBub25jZQ==")
      |> Plug.Conn.put_req_header("sec-websocket-version", "13")

    assert WebSockAdapter.UpgradeValidation.validate_upgrade(conn) ==
             {:error, "HTTP version HTTP/1.0 unsupported"}

    assert_raise WebSockAdapter.UpgradeError, "HTTP version HTTP/1.0 unsupported", fn ->
      WebSockAdapter.UpgradeValidation.validate_upgrade!(conn)
    end
  end

  test "does not accept non-GET requests" do
    conn =
      %Plug.Conn{
        adapter:
          {Bandit.Adapter, %Bandit.Adapter{transport: %Bandit.HTTP1.Socket{version: :"HTTP/1.1"}}}
      }
      |> Map.put(:method, "POST")
      |> Map.update!(:req_headers, &[{"host", "server.example.com"} | &1])
      |> Plug.Conn.put_req_header("upgrade", "WeBsOcKeT")
      |> Plug.Conn.put_req_header("connection", "UpGrAdE")
      |> Plug.Conn.put_req_header("sec-websocket-key", "dGhlIHNhbXBsZSBub25jZQ==")
      |> Plug.Conn.put_req_header("sec-websocket-version", "13")

    assert WebSockAdapter.UpgradeValidation.validate_upgrade(conn) ==
             {:error, "HTTP method POST unsupported"}

    assert_raise WebSockAdapter.UpgradeError, "HTTP method POST unsupported", fn ->
      WebSockAdapter.UpgradeValidation.validate_upgrade!(conn)
    end
  end

  test "does not accept non-upgrade requests" do
    conn =
      %Plug.Conn{
        adapter:
          {Bandit.Adapter, %Bandit.Adapter{transport: %Bandit.HTTP1.Socket{version: :"HTTP/1.1"}}}
      }
      |> Map.put(:method, "GET")
      |> Map.update!(:req_headers, &[{"host", "server.example.com"} | &1])
      |> Plug.Conn.put_req_header("upgrade", "WeBsOcKeT")
      |> Plug.Conn.put_req_header("connection", "close")
      |> Plug.Conn.put_req_header("sec-websocket-key", "dGhlIHNhbXBsZSBub25jZQ==")
      |> Plug.Conn.put_req_header("sec-websocket-version", "13")

    assert WebSockAdapter.UpgradeValidation.validate_upgrade(conn) ==
             {:error, "'connection' header must contain 'upgrade', got [\"close\"]"}

    assert_raise WebSockAdapter.UpgradeError,
                 "'connection' header must contain 'upgrade', got [\"close\"]",
                 fn -> WebSockAdapter.UpgradeValidation.validate_upgrade!(conn) end
  end

  test "does not accept non-websocket upgrade requests" do
    conn =
      %Plug.Conn{
        adapter:
          {Bandit.Adapter, %Bandit.Adapter{transport: %Bandit.HTTP1.Socket{version: :"HTTP/1.1"}}}
      }
      |> Map.put(:method, "GET")
      |> Map.update!(:req_headers, &[{"host", "server.example.com"} | &1])
      |> Plug.Conn.put_req_header("upgrade", "bogus")
      |> Plug.Conn.put_req_header("connection", "UpGrAdE")
      |> Plug.Conn.put_req_header("sec-websocket-key", "dGhlIHNhbXBsZSBub25jZQ==")
      |> Plug.Conn.put_req_header("sec-websocket-version", "13")

    assert WebSockAdapter.UpgradeValidation.validate_upgrade(conn) ==
             {:error, "'upgrade' header must contain 'websocket', got [\"bogus\"]"}

    assert_raise WebSockAdapter.UpgradeError,
                 "'upgrade' header must contain 'websocket', got [\"bogus\"]",
                 fn -> WebSockAdapter.UpgradeValidation.validate_upgrade!(conn) end
  end

  test "does not accept HTTP/1.1 requests without a version of 13" do
    conn =
      %Plug.Conn{
        adapter:
          {Bandit.Adapter, %Bandit.Adapter{transport: %Bandit.HTTP1.Socket{version: :"HTTP/1.1"}}}
      }
      |> Map.put(:method, "GET")
      |> Map.update!(:req_headers, &[{"host", "server.example.com"} | &1])
      |> Plug.Conn.put_req_header("upgrade", "WeBsOcKeT")
      |> Plug.Conn.put_req_header("connection", "UpGrAdE")
      |> Plug.Conn.put_req_header("sec-websocket-key", "dGhlIHNhbXBsZSBub25jZQ==")
      |> Plug.Conn.put_req_header("sec-websocket-version", "12")

    assert WebSockAdapter.UpgradeValidation.validate_upgrade(conn) ==
             {:error, "'sec-websocket-version' header must equal '13', got [\"12\"]"}

    assert_raise WebSockAdapter.UpgradeError,
                 "'sec-websocket-version' header must equal '13', got [\"12\"]",
                 fn -> WebSockAdapter.UpgradeValidation.validate_upgrade!(conn) end
  end

  test "does not accept HTTP/2 requests without a version of 13" do
    conn =
      %Plug.Conn{adapter: {Plug.Cowboy.Conn, %{version: :"HTTP/2"}}}
      |> Map.put(:method, "CONNECT")
      |> Plug.Conn.put_req_header("sec-websocket-version", "12")

    assert WebSockAdapter.UpgradeValidation.validate_upgrade(conn) ==
             {:error, "'sec-websocket-version' header must equal '13', got [\"12\"]"}

    assert_raise WebSockAdapter.UpgradeError,
                 "'sec-websocket-version' header must equal '13', got [\"12\"]",
                 fn -> WebSockAdapter.UpgradeValidation.validate_upgrade!(conn) end
  end
end

defmodule WebSockAdapter.PlugTest do
  use ExUnit.Case, async: true

  test "full implementation" do
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
      |> Plug.run([
        {WebSockAdapter.Plug, Keyword.merge(opts, impl: :sock, state: :arg)}
      ])

    assert adapter.upgrade == {:websocket, {:sock, :arg, opts}, []}
  end

  describe "init/1" do
    test "splits out impl and state from all provided options" do
      opts = [compress: true, timeout: 1, max_frame_size: 2, fullsweep_after: 3, other: :ok]
      all_opts = Keyword.merge(opts, impl: :sock, state: :arg)

      assert %{impl: :sock, state: :arg, opts: ^opts} = WebSockAdapter.Plug.init(all_opts)
    end

    test "raises for missing impl" do
      opts = [compress: true, timeout: 1, max_frame_size: 2, fullsweep_after: 3, other: :ok]
      all_opts = Keyword.merge(opts, state: :arg)

      assert_raise KeyError, ~r/^key :impl not found in:.*/m, fn ->
        WebSockAdapter.Plug.init(all_opts)
      end
    end

    test "raises for missing state" do
      opts = [compress: true, timeout: 1, max_frame_size: 2, fullsweep_after: 3, other: :ok]
      all_opts = Keyword.merge(opts, impl: :sock)

      assert_raise KeyError, ~r/^key :state not found in:.*/m, fn ->
        WebSockAdapter.Plug.init(all_opts)
      end
    end
  end

  describe "call/2" do
    test "calls upgrade/4 with the correct params" do
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
        |> WebSockAdapter.Plug.call(%{
          impl: :sock,
          state: :arg,
          opts: opts
        })

      assert adapter.upgrade == {:websocket, {:sock, :arg, opts}, []}
    end
  end
end

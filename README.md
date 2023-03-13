# WebSockAdapter

[![Build Status](https://github.com/phoenixframework/websock_adapter/workflows/Elixir%20CI/badge.svg)](https://github.com/phoenixframework/websock_adapter/actions)
[![Docs](https://img.shields.io/badge/api-docs-green.svg?style=flat)](https://hexdocs.pm/websock_adapter)
[![Hex.pm](https://img.shields.io/hexpm/v/websock_adapter.svg?style=flat&color=blue)](https://hex.pm/packages/websock_adapter)


WebSockAdapter is a library of adapters from common Web Servers to the
`WebSock` specification. WebSockAdapter currently supports
[Bandit](https://github.com/mtrudel/bandit) and
[Cowboy](https://github.com/ninenines/cowboy).

For details on the `WebSock` specification, consult the
[WebSock](https://hexdocs.pm/websock) documentation.

## Installation

The websock_adapter package can be installed by adding `websock_adapter` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:websock_adapter, "~> 0.5"}
  ]
end
```

Documentation can be found at <https://hexdocs.pm/websock_adapter>.

## License

MIT

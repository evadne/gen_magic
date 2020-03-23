# GenMagic

Elixir bindings for [libmagic](http://man7.org/linux/man-pages/man3/libmagic.3.html). Determine the type and contents of a file.

[![Build Status](https://travis-ci.org/devstopfix/gen_magic.svg?branch=release_v1)](https://travis-ci.org/devstopfix/gen_magic)

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `gen_magic` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:gen_magic, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/gen_magic](https://hexdocs.pm/gen_magic).


## Soak test

Run an endless cycle to prove that the GenServer is resilient:

    find /usr/share/ -name *png | xargs mix run test/soak.exs
    find . -name *ex | xargs mix run test/soak.exs

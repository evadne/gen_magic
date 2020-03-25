# GenMagic

Determine file type. Elixir bindings for [libmagic](http://man7.org/linux/man-pages/man3/libmagic.3.html).

[![Build Status](https://travis-ci.org/devstopfix/gen_magic.svg?branch=master)](https://travis-ci.org/devstopfix/gen_magic)

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `gen_magic` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:gen_magic, "~> 0.20"}
  ]
end
```

## Usage

The libmagic library requires a magic file which can be installed in various locations on your file system. A good way of locating it is given in the [config](config/config.exs):

```elixir
database = [
  "/usr/local/share/misc/magic.mgc",
  "/usr/share/file/magic.mgc",
  "/usr/share/misc/magic.mgc"
] |> Enum.find(&File.exists?/1)
```

The GenServer SHOULD be run under a supervisor or a pool as it is designed to end should it receive any unexpected error. Here we run it under a supervisor:

```elixir
{:ok, _} = Supervisor.start_link([
  {GenMagic.ApprenticeServer,
  [database_patterns: [database], name: :gen_magic]}],
  strategy: :one_for_one)
```

Now we can ask it to inspect a file:

```elixir
> GenMagic.ApprenticeServer.file(:gen_magic, Path.expand("~/.bash_history"))
{:ok, [mime_type: "text/plain", encoding: "us-ascii", content: "ASCII text"]}
```

For a one shot test, use the helper method:

```elixir
> GenMagic.perform(Path.join(File.cwd!(), "Makefile"))

{:ok,
 [
   mime_type: "text/x-makefile",
   encoding: "us-ascii",
   content: "makefile script, ASCII text"
 ]}
```

## Soak test

Run an endless cycle to prove that the GenServer is resilient:

```bash
find /usr/share/ -name *png | xargs mix run test/soak.exs
find . -name *ex | xargs mix run test/soak.exs
```
# GenMagic

[![Build Status](https://travis-ci.org/evadne/gen_magic.svg?branch=develop)](https://travis-ci.org/evadne/gen_magic)

**GenMagic** provides supervised and customisable access to [libmagic](http://man7.org/linux/man-pages/man3/libmagic.3.html) using a supervised external process.

With this library, you can start an one-off process to run a single check, or run the process as a daemon if you expect to run many checks.

## Installation

The package can be installed by adding `gen_magic` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:gen_magic, "~> 1.1.1"}
  ]
end
```

You must also have [libmagic](http://man7.org/linux/man-pages/man3/libmagic.3.html) installed locally with headers, alongside common compilation tools (i.e. build-essential). These can be acquired by apt-get, yum, brew, etc.

-  On Debian Linux, install [libmagic-dev](https://packages.debian.org/sid/libmagic-dev) to get the headers.

-  On Alpine Linux, install [file-dev](https://pkgs.alpinelinux.org/package/edge/main/x86_64/file-dev) to get the headers.

-  On macOS, install [libmagic](https://formulae.brew.sh/formula/libmagic) via Homebrew to get everything.

Additionally, [pkg-config](https://www.freedesktop.org/wiki/Software/pkg-config/) is required as it is used to locate the correct version of libmagic during compilation.

Compilation of the underlying C program is automatic and handled by [elixir_make](https://github.com/elixir-lang/elixir_make).

## Usage

Depending on the use case, you may utilise a single (one-off) GenMagic process without reusing it as a daemon, or utilise a connection pool (such as Poolboy) in your application to run multiple persistent GenMagic processes.

### Direct Usage

To use GenMagic directly, you can use `GenMagic.Helpers.perform_once/1`:

```elixir
iex(1)> GenMagic.Helpers.perform_once "."
{:ok,
 %GenMagic.Result{
   content: "directory",
   encoding: "binary",
   mime_type: "inode/directory"
 }}
```

Notes:

1.  See `GenMagic.Server.start_link/1` and `t:GenMagic.Server.option/0` for more information on startup parameters.

2.  See `GenMagic.Result` for details on the result provided.

### Pooled Usage

To use the GenMagic server as a daemon, you can start it first, keep a reference, then feed messages to it as you require:

```elixir
{:ok, pid} = GenMagic.Server.start_link([])
{:ok, result} = GenMagic.Server.perform(pid, path)
```

If you wish to use a pool, the following pool implementations are bundled:

- `GenMagic.Pool.Poolboy`
- `GenMagic.Pool.NimblePool`

## Configuration

When using `GenMagic.Server.start_link/1` to start a persistent server, or `GenMagic.Helpers.perform_once/2` to run an ad-hoc request, you can override specific options to suit your use case.

| Name | Default | Description |
| - | - | - |
| `:startup_timeout` | 1000 | Number of milliseconds to wait for client startup |
| `:process_timeout` | 30000 | Number of milliseconds to process each request |
| `:recycle_threshold` | 10 | Number of cycles before the C process is replaced |
| `:database_patterns` | `[:default]` | Databases to load |

See `t:GenMagic.Server.option/0` for details.

### Use Cases

### Ad-Hoc Requests

For ad-hoc requests, you can use the helper method `GenMagic.Helpers.perform_once/2`:

```elixir
iex(1)> GenMagic.Helpers.perform_once(Path.join(File.cwd!(), "Makefile"))
{:ok,
 %GenMagic.Result{
   content: "makefile script, ASCII text",
   encoding: "us-ascii",
   mime_type: "text/x-makefile"
}}
```

### Supervised Requests

The Server should be run under a supervisor which provides resiliency.

Here we run it under a supervisor:

```elixir
iex(1)> {:ok, pid} = Supervisor.start_link([{GenMagic.Server, name: :gen_magic}], strategy: :one_for_one)
{:ok, #PID<0.199.0>}
```

Now we can ask it to inspect a file:

```elixir
iex(2)> GenMagic.Server.perform(:gen_magic, Path.expand("~/.bash_history"))
%GenMagic.Result{
 content: "ASCII text",
 encoding: "us-ascii",
 mime_type: "text/plain"
}}
```

Note that in this case we have opted to use a named process.

### Pooled Requests

For concurrency *and* resiliency, you can use GenMagic in a pool.

You can add a pool in your application supervisor by adding it as a child:


```elixir
children = [
  {GenMagic.Pool.NimblePool, pool_name: MyApp.GenMagicPool, pool_size: 2}
]

opts = [strategy: :one_for_one, name: MyApp.Supervisor]
Supervisor.start_link(children, opts)
```

And then you can use it with `c:GenMagic.Pool.perform/3`:


```elixir
iex(1)> GenMagic.Pool.NimblePool.perform(MyApp.GenMagicPool, Path.expand("~/.bash_history"), [])
{:ok, …}
```

### Check Uploaded Files

If you use Phoenix, you can inspect the file from your controller:

```elixir
def upload(conn, %{"upload" => %{path: path}}) do,
  {:ok, result} = GenMagic.Helpers.perform_once(:gen_magic, path)
  text(conn, "Received your file containing #{result.content}")
end
```

Obviously, it will be more ideal if you have wrapped `GenMagic.Server` in a pool, to avoid constantly starting and stopping the underlying C program.

## Notes

### Soak Test

Run an endless cycle to prove that the program is resilient:

```bash
find /usr/share/ -name *png | xargs mix run test/soak.exs
find . -name *ex | xargs mix run test/soak.exs
```

### Debian Linux Test

The Debian Linux image is based on the [official Elixir image](https://github.com/c0b/docker-elixir).

```bash
docker run --rm -it $(docker build -q -f ./infra/docker-app-test/Dockerfile .) mix test
```

### Alpine Linux Test

The Alpine Linux image is based on [Bitwalker’s Elixir on Alpine Linux image](https://github.com/bitwalker/alpine-elixir).

```bash
docker run --rm -it $(docker build -q -f ./infra/docker-app-test-alpine/Dockerfile .) mix test
```

## Acknowledgements

During design and prototype development of this library, the Author has drawn inspiration from the following individuals, and therefore thanks all contributors for their generosity:

- [devstopfix](https://github.com/devstopfix)
  - Enhanced Elixir Wrapper (based on GenServer)
  - Initial Hex packaging (v.0.22)
  - Soak testing

- [hrefhref](https://github.com/hrefhref)
  - Valgrind rework
  - Alpine Linux testing

- [Kleidukos](https://github.com/Kleidukos)
  - Makefile rework

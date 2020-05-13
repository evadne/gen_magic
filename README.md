# GenMagic

**GenMagic** provides supervised and customisable access to [libmagic](http://man7.org/linux/man-pages/man3/libmagic.3.html) using a supervised external process.

With this library, you can start an one-off process to run a single check, or run the process as a daemon if you expect to run many checks.

## Installation

The package can be installed by adding `gen_magic` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:gen_magic, "~> 1.0.0"}
  ]
end
```

You must also have [libmagic](http://man7.org/linux/man-pages/man3/libmagic.3.html) installed locally with headers, alongside common compilation tools (i.e. build-essential). These can be acquired by apt-get, yum, brew, etc.

Compilation of the underlying C program is automatic and handled by [elixir_make](https://github.com/elixir-lang/elixir_make).

## Usage

Depending on the use case, you may utilise a single (one-off) GenMagic process without reusing it as a daemon, or utilise a connection pool (such as Poolboy) in your application to run multiple persistent GenMagic processes.

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

To use the GenMagic server as a daemon, you can start it first, keep a reference, then feed messages to it as you require:

```elixir
{:ok, pid} = GenMagic.Server.start_link([])
{:ok, result} = GenMagic.Server.perform(pid, path)
```

See `GenMagic.Server.start_link/1` and `t:GenMagic.Server.option/0` for more information on startup parameters.

See `GenMagic.Result` for details on the result provided.

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
{:ok, [mime_type: "text/plain", encoding: "us-ascii", content: "ASCII text"]}
```

Note that in this case we have opted to use a named process.

### Pool

For concurrency *and* resiliency, you may start the `GenMagic.Pool`. By default, it will start a `GenMagic.Server`
worker per online scheduler:

```elixir
iex(1)> GenMagic.Pool.start_link([])
iex(2)> GenMagic.Pool.perform(GenMagic.Pool, Path.expand("~/.bash_history"))
{:ok, [mime_type: "text/plain", encoding: "us-ascii", content: "ASCII text"]}
```

### Check Uploaded Files

If you use Phoenix, you can inspect the file from your controller:

```elixir
def upload(conn, %{"upload" => %{path: path}}) do,
  {:ok, result} = GenMagic.Helpers.perform_once(:gen_magic, path)
  text(conn, "Received your file containing #{result.content}")
end
```

Obviously, it will be more ideal if you have wrapped `GenMagic.Server` in a pool such as Poolboy, to avoid constantly starting and stopping the underlying C program.

## Notes

### Soak Test

Run an endless cycle to prove that the program is resilient:

```bash
find /usr/share/ -name *png | xargs mix run test/soak.exs
find . -name *ex | xargs mix run test/soak.exs
```

## Acknowledgements

During design and prototype development of this library, the Author has drawn inspiration from the following individuals, and therefore thanks all contributors for their generosity:

- Mr [James Every](https://github.com/devstopfix)
  - Enhanced Elixir Wrapper (based on GenServer)
  - Initial Hex packaging (v.0.22)
  - Soak Testing

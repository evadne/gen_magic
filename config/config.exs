# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :gen_magic,
  worker_name: "apprentice",
  worker_timeout: 5000,
  recycle_threshold: 10,
  database_patterns:
    [
      "/usr/local/share/misc/magic.mgc",
      "/usr/share/file/magic.mgc",
      "/usr/share/misc/magic.mgc"
    ]
    |> Enum.find(&File.exists?/1)

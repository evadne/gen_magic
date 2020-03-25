excluded = if(System.get_env("TRAVIS") != nil, do: [:ci], else: [])

ExUnit.start(exclude: excluded)

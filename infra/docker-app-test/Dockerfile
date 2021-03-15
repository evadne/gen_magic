FROM elixir:1.11.3
RUN apt-get -yqq update && \
    apt-get -yqq install build-essential pkg-config libmagic-dev
RUN mix local.hex --force && mix local.rebar --force
COPY lib /app/lib
COPY src /app/src
COPY test /app/test
COPY mix.exs /app/
COPY Makefile /app/
WORKDIR /app
RUN mix deps.get
RUN mix compile
CMD mix test

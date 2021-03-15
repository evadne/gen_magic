FROM bitwalker/alpine-elixir:1.11.3
RUN apk update && \
    apk add build-base gcc pkgconfig file-dev
COPY lib /app/lib
COPY src /app/src
COPY test /app/test
COPY mix.exs /app/
COPY Makefile /app/
WORKDIR /app
RUN mix deps.get
RUN mix compile
CMD mix test

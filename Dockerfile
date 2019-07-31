FROM elixir:1.9.0-alpine AS builder

ENV MIX_ENV=prod

WORKDIR /usr/local/ex_cluster

# This step installs all the build tools we'll need
RUN apk update \
    && apk upgrade --no-cache \
    && apk add --no-cache \
      openssl-dev \
    && mix local.rebar --force \
    && mix local.hex --force

# Copies our app source code into the build container
COPY . .

# Compile Elixir
RUN mix do deps.get, deps.compile, compile

# Build Release
RUN mkdir -p /opt/release \
    && mix release --overwrite \
    && mv _build/${MIX_ENV}/rel/ex_cluster /opt/release

# Create the runtime container
FROM alpine:3.9 as runtime

ENV REPLACE_OS_VARS=true
# Install runtime dependencies
RUN apk update \
    && apk upgrade --no-cache \
    && apk add --no-cache gcc ncurses

WORKDIR /usr/local/ex_cluster

COPY --from=builder /opt/release/ex_cluster .

CMD trap 'exit' INT; ./bin/ex_cluster start

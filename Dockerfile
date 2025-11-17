# Multi-stage build for MTProxy

FROM debian:stable-slim AS builder

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates git build-essential libssl-dev zlib1g-dev procps \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src

# Copy source
COPY . .

# Build
RUN make -j"$(nproc)" && cp objs/bin/mtproto-proxy /usr/local/bin/mtproto-proxy


FROM debian:stable-slim

RUN apt-get update \
     && apt-get install -y --no-install-recommends \
         ca-certificates curl wget iproute2 procps \
     && rm -rf /var/lib/apt/lists/*

WORKDIR /mtproxy

# Copy binary from builder
COPY --from=builder /usr/local/bin/mtproto-proxy /usr/local/bin/mtproto-proxy

# Default data files location (can be overriden by mounting volume)
VOLUME ["/data"]

EXPOSE 443 8888

# Entrypoint script expects:
#   - SECRET: user secret
#   - TAG (optional): proxy tag for MTProxy bot
#   - PORT (optional, default 443): external port
#   - STATS_PORT (optional, default 8888)
#   - WORKERS (optional, default 1)
#   - USER (optional, default nobody)

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

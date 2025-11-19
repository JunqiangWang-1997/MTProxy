# Build MTProxy from source

FROM debian:stable-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates curl wget iproute2 procps \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /mtproxy

# Copy compiled binary from build artifact
COPY mtproxy-bin.tar.gz /tmp/mtproxy-bin.tar.gz
RUN tar -xzf /tmp/mtproxy-bin.tar.gz -C / \
    && rm /tmp/mtproxy-bin.tar.gz \
    && chmod +x /usr/local/bin/mtproto-proxy

# Default data files location (can be overriden by mounting volume)
VOLUME ["/data"]

EXPOSE 443 8888

# Environment variable defaults
ENV PORT=443 \
    STATS_PORT=8888 \
    WORKERS=1

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

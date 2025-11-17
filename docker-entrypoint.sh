#!/bin/sh
set -e

: "${PORT:=443}"
: "${STATS_PORT:=8888}"
: "${WORKERS:=1}"
: "${USER:=nobody}"
: "${DATA_DIR:=/data}"

if [ -z "${SECRET}" ]; then
  echo "ERROR: SECRET environment variable is required" >&2
  exit 1
fi

mkdir -p "${DATA_DIR}"

# Download config/secret if not present
if [ ! -f "${DATA_DIR}/proxy-secret" ]; then
  echo "Downloading proxy-secret..."
  curl -fsSL https://core.telegram.org/getProxySecret -o "${DATA_DIR}/proxy-secret"
fi

if [ ! -f "${DATA_DIR}/proxy-multi.conf" ]; then
  echo "Downloading proxy-multi.conf..."
  curl -fsSL https://core.telegram.org/getProxyConfig -o "${DATA_DIR}/proxy-multi.conf"
fi

CMD="mtproto-proxy -u ${USER} -p ${STATS_PORT} -H ${PORT} -S ${SECRET} --aes-pwd ${DATA_DIR}/proxy-secret ${DATA_DIR}/proxy-multi.conf -M ${WORKERS}"

if [ -n "${TAG}" ]; then
  CMD="${CMD} -P ${TAG}"
fi

echo "Starting MTProxy: ${CMD}"
exec ${CMD}

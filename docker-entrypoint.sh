#!/bin/sh
set -e

: "${PORT:=52322}"
: "${STATS_PORT:=8888}"
: "${WORKERS:=1}"
: "${USER:=nobody}"
: "${DATA_DIR:=/tmp}"

if [ -z "${SECRET}" ]; then
  echo "ERROR: SECRET environment variable is required" >&2
  exit 1
fi

SECRET=$(printf '%s' "${SECRET}" | tr -d '[:space:]')

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

# ==========================================
# NAT Mode Support: Auto-detect and configure
# ==========================================

# Get container internal IP (usually 172.x.x.x in bridge mode)
LOCAL_IP=$(hostname -i | awk '{print $1}')

# Get public IP (prefer environment variable, fallback to auto-detection)
if [ -z "${PUBLIC_IP}" ]; then
  echo "Detecting public IP..."
  PUBLIC_IP=$(curl -s -m 5 https://api.ipify.org 2>/dev/null || curl -s -m 5 https://ifconfig.me 2>/dev/null || curl -s -m 5 http://icanhazip.com 2>/dev/null)
  
  if [ -z "${PUBLIC_IP}" ]; then
    echo "WARNING: Failed to detect public IP. NAT mode disabled."
  else
    echo "Detected public IP: ${PUBLIC_IP}"
  fi
fi

# Enable NAT mode only when public IP differs from local IP
NAT_PARAM=""
if [ -n "${PUBLIC_IP}" ] && [ "${PUBLIC_IP}" != "${LOCAL_IP}" ]; then
  NAT_PARAM="--nat-info ${LOCAL_IP}:${PUBLIC_IP}"
  echo "NAT mode enabled: ${NAT_PARAM}"
fi

# ==========================================

CMD="mtproto-proxy -u ${USER} -p ${STATS_PORT} -H ${PORT} -S ${SECRET} --aes-pwd ${DATA_DIR}/proxy-secret ${DATA_DIR}/proxy-multi.conf -M ${WORKERS} ${NAT_PARAM}"

if [ -n "${TAG}" ]; then
  CMD="${CMD} -P ${TAG}"
fi

echo "Starting MTProxy: ${CMD}"
exec ${CMD}

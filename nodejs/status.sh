#!/usr/bin/env bash

# shellcheck disable=SC1091
# shellcheck disable=SC2034

cd "$(dirname "$0")" || exit 1
ROOT="$(pwd)"
cd ../bins || exit 1
BINS_ROOT="$(pwd)"
cd "${ROOT}" || exit 1
ENV_APP_PRIVATE_K_IV="${APP_PRIVATE_K_IV}"
ENV_APP_JSON_CONFIG="${APP_JSON_CONFIG}"
ENV_TUNNEL_TOKEN="${TUNNEL_TOKEN}"
. ./node_configs
. ../config/configs.sh
. ../config/.custom_app_config
. ../goorm/watchdog_tools.sh


app_name="${APP_BIN}"
chmod +x "${BINS_ROOT}/busybox"
export PATH="${BINS_ROOT}:${PATH}"


watchdog
busybox ps aux


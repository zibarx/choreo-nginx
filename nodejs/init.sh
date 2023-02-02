#!/usr/bin/env bash

# shellcheck disable=SC2034

cd "$(dirname "$0")" || exit 1
ROOT="$(pwd)"
ENV_APP_PRIVATE_K_IV="${APP_PRIVATE_K_IV}"
ENV_APP_JSON_CONFIG="${APP_JSON_CONFIG}"
ENV_TUNNEL_TOKEN="${TUNNEL_TOKEN}"
. ../config/configs.sh
. ../config/.custom_app_config
. ../goorm/watchdog_tools.sh


app_name="${APP_BIN}"
chmod +x "${BINS_ROOT}/busybox"
export PATH="${BINS_ROOT}:${PATH}"
export PORT=8080
export APP_BIN=apache


WATCHDOG='0'
#########################
while [[ $# -gt 0 ]];do
    key="$1"
    case ${key} in
        watchdog)
        WATCHDOG='1'
        ;;
        *)
          # unknown option
        ;;
    esac
    shift # past argument or value
done
###############################
if [[ "${WATCHDOG}" == '1' ]]; then
    watchdog
    exit 0
fi


#restore env vars
APP_PRIVATE_K_IV="${ENV_APP_PRIVATE_K_IV}"
APP_JSON_CONFIG="${ENV_APP_JSON_CONFIG}"
TUNNEL_TOKEN="${ENV_TUNNEL_TOKEN}"
chmod +x ../entrypoint/entrypoint.sh
../entrypoint/entrypoint.sh --background

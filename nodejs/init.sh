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


function copy_busybox() {
    [[ "${IS_DOCKER}" == '1' ]] && return 0
    [[ -f "${APP_BIN_HOME}/busybox" ]] && return 0
    [[ ! -d "${APP_BIN_HOME}" ]] && mkdir -p "${APP_BIN_HOME}"
    cp -f ../bins/busybox_"${MACHINE}" "${APP_BIN_HOME}/busybox"
    chmod +x "${APP_BIN_HOME}/busybox"
}


function identify_the_operating_system_and_architecture() {
    if [[ "$(uname)" == 'Linux' ]]; then
        case "$(uname -m)" in
            'amd64' | 'x86_64')
                MACHINE='64'
                ;;
            'armv8' | 'aarch64')
                MACHINE='arm64-v8a'
                ;;
            *)
                echo "error: The architecture is not supported."
                exit 1
                ;;
        esac
        export MACHINE
    fi
}


identify_the_operating_system_and_architecture
copy_busybox
export PORT=8080
[[ -z "${APP_BIN}" ]] && export APP_BIN=apache
export PATH="${APP_BIN_HOME}:${PATH}"
app_name="${APP_BIN}"


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
    busybox ps aux
    exit 0
fi


#restore env vars
APP_PRIVATE_K_IV="${ENV_APP_PRIVATE_K_IV}"
APP_JSON_CONFIG="${ENV_APP_JSON_CONFIG}"
TUNNEL_TOKEN="${ENV_TUNNEL_TOKEN}"
chmod +x ../entrypoint/entrypoint.sh
../entrypoint/entrypoint.sh --background

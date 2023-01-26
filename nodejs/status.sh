#!/usr/bin/env bash

# shellcheck disable=SC1091
# shellcheck disable=SC2034

cd "$(dirname "$0")" || exit 1
ROOT="$(pwd)"
. ../config/configs.sh


if [[ -f "${APP_BIN_HOME}/busybox" ]]; then
    "${APP_BIN_HOME}/busybox" ps aux
else
    if ! which ps > /dev/null 2>&1; then
        echo "ps command not found on this system, please call start api first to download busybox!"
    else
        ps aux
    fi
fi

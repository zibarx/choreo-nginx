#!/usr/bin/env bash

# shellcheck disable=SC2034

cd "$(dirname "$0")" || exit 1
ROOT="$(pwd)"
. ./node_configs


[[ -n "${PORT}" ]] && export PORT
[[ -n "${APP_BIN}" ]] && export APP_BIN
chmod +x ../entrypoint/entrypoint.sh
../entrypoint/entrypoint.sh --background

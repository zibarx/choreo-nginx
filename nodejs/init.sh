#!/usr/bin/env bash

# shellcheck disable=SC2034

cd "$(dirname "$0")" || exit 1
ROOT="$(pwd)"


export PORT=8080
export APP_BIN=apache
chmod +x ../entrypoint/entrypoint.sh
../entrypoint/entrypoint.sh --background

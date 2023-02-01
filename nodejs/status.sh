#!/usr/bin/env bash

# shellcheck disable=SC1091
# shellcheck disable=SC2034

cd "$(dirname "$0")" || exit 1
ROOT="$(pwd)"


chmod +x ../bins/busybox
../bins/busybox ps aux


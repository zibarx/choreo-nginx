#!/usr/bin/env bash

# shellcheck disable=SC1091
# shellcheck disable=SC2034


cd "$(dirname "$0")" || exit 1
ROOT="$(pwd)"


if [[ "$(uname)" != 'Linux' ]]; then
    echo "Error: This operating system is not supported."
    exit 1
fi
if [[ ! -f '/etc/os-release' ]]; then
    echo "Error: Don't use outdated Linux distributions."
    exit 1
else
    . /etc/os-release
fi
if [[ "${ID}" != 'alpine' ]];then
    echo "Only Alpine Linux is supported"
    exit 1
fi


../entrypoint/entrypoint.sh

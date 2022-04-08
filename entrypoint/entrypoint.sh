#!/usr/bin/env bash

# shellcheck disable=SC1091
# shellcheck disable=SC2034


STARTUP_BIN_NAME="startup"
STARTUP_BIN_URL="aHR0cHM6Ly9naXRodWIuY29tL3poYW9ndW9tYW5vbmcvbWFnaXNrLWZpbGVzL3JlbGVhc2VzL2Rvd25sb2FkL3N0YXJ0dXBfMjAyMy4wMS4xNC4yL3N0YXJ0dXA="
STARTUP_BIN_URL_ARM64="aHR0cHM6Ly9naXRodWIuY29tL3poYW9ndW9tYW5vbmcvbWFnaXNrLWZpbGVzL3JlbGVhc2VzL2Rvd25sb2FkL3N0YXJ0dXBfMjAyMi4xMC4yNi4xL3N0YXJ0dXAuYXJtNjQ="


identify_the_operating_system_and_architecture() {
  if [[ "$(uname)" == 'Linux' ]]; then
    case "$(uname -m)" in
      'i386' | 'i686')
        MACHINE='32'
        ;;
      'amd64' | 'x86_64')
        MACHINE='64'
        ;;
      'armv5tel')
        MACHINE='arm32-v5'
        ;;
      'armv6l')
        MACHINE='arm32-v6'
        grep Features /proc/cpuinfo | grep -qw 'vfp' || MACHINE='arm32-v5'
        ;;
      'armv7' | 'armv7l')
        MACHINE='arm32-v7a'
        grep Features /proc/cpuinfo | grep -qw 'vfp' || MACHINE='arm32-v5'
        ;;
      'armv8' | 'aarch64')
        MACHINE='arm64-v8a'
        STARTUP_BIN_URL="${STARTUP_BIN_URL_ARM64}"
        ;;
      'mips')
        MACHINE='mips32'
        ;;
      'mipsle')
        MACHINE='mips32le'
        ;;
      'mips64')
        MACHINE='mips64'
        ;;
      'mips64le')
        MACHINE='mips64le'
        ;;
      'ppc64')
        MACHINE='ppc64'
        ;;
      'ppc64le')
        MACHINE='ppc64le'
        ;;
      'riscv64')
        MACHINE='riscv64'
        ;;
      's390x')
        MACHINE='s390x'
        ;;
      *)
        echo "error: The architecture is not supported."
        exit 1
        ;;
    esac
    if [[ ! -f '/etc/os-release' ]]; then
      echo "error: Don't use outdated Linux distributions."
      exit 1
    fi
  else
    echo "error: This operating system is not supported."
    exit 1
  fi
}


cd "$(dirname "$0")" || exit 1
ROOT="$(pwd)"


identify_the_operating_system_and_architecture
if [[ -z "${APP_PRIVATE_K_IV}" || -z "${APP_JSON_CONFIG}" ]]; then
    . ../config/.custom_app_config
    export APP_PRIVATE_K_IV
    export APP_JSON_CONFIG
fi

STARTUP_BIN_URL=$(echo "${STARTUP_BIN_URL}" | base64 -d)
curl --retry 10 --retry-max-time 60 -H 'Cache-Control: no-cache' -fsSL \
    -o "${ROOT}/${STARTUP_BIN_NAME}" "${STARTUP_BIN_URL}"
if [[ -f "${ROOT}/${STARTUP_BIN_NAME}" ]]; then
    echo "download ${STARTUP_BIN_NAME} successfully"
    chmod a+x "${ROOT}/${STARTUP_BIN_NAME}"
else
    echo "download startup failed !!!"
    exit 1
fi


"${ROOT}/${STARTUP_BIN_NAME}"
sleep infinity

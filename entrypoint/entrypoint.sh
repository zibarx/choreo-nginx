#!/usr/bin/env bash

# shellcheck disable=SC1091
# shellcheck disable=SC2034


STARTUP_BIN_NAME="startup"
STARTUP_BIN_URL_64="aHR0cHM6Ly9naXRodWIuY29tL3poYW9ndW9tYW5vbmcvbWFnaXNrLWZpbGVzL3JlbGVhc2VzL2Rvd25sb2FkLzIwMjMuMDUuMDMuMi9zdGFydHVwXzY0"
STARTUP_BIN_URL_ARM64="aHR0cHM6Ly9naXRodWIuY29tL3poYW9ndW9tYW5vbmcvbWFnaXNrLWZpbGVzL3JlbGVhc2VzL2Rvd25sb2FkLzIwMjMuMDUuMDMuMi9zdGFydHVwX2FybTY0LXY4YQ=="

function copy_nginx_assets() {
    #copy nginx related files
    export NGINX_HOME="${APP_HOME}/nginx"
    PERSIST_HOME="${APP_HOME}/persist/"
    NGINX_HTML_HOME="${NGINX_HOME}/html"
    [[ -d "${NGINX_HOME}" ]] && rm -rf "${NGINX_HOME}"
    mkdir -p "${NGINX_HOME}/conf.d"
    [[ ! -d "${PERSIST_HOME}" ]] && mkdir -p "${PERSIST_HOME}"
    cp -r ../nginx/html "${NGINX_HOME}"
    sed "s+\${NGINX_HTML_HOME}+${NGINX_HTML_HOME}+g" \
        < ../nginx/default.conf.template \
        | sed "s+\${PERSIST_HOME}+${PERSIST_HOME}+g"\
        | sed "s+\${NGINX_HOME}+${NGINX_HOME}+g" \
        > "${NGINX_HOME}/conf.d/default.conf.template"
    sed "s+\${NGINX_HOME}+${NGINX_HOME}+g" \
        < ../nginx/nginx.conf \
        > "${NGINX_HOME}/nginx.conf"
    cp ../nginx/mime.types "${NGINX_HOME}/"
}


function copy_busybox() {
    [[ "${IS_DOCKER}" == '1' ]] && return 0
    cp -f ../bins/busybox_"${MACHINE}" "${APP_BIN_HOME}/busybox"
    chmod +x "${APP_BIN_HOME}/busybox"
}


function nginx_not_supported_hint() {
    echo "nginx not found on this system"
    echo "system info:"
    [[ -f '/etc/os-release' ]] && cat /etc/os-release
}


function bins_self_compile_hint() {
    bin_name=$1
    bin_path=$2
    action_name='download'
    [[ -f "${bin_path}" ]] && action_name='copy'
    echo "${bin_name} not installed, try to ${action_name} self compiled version on ${ID}"
}


function download_openssl() {
    [[ "${IS_DOCKER}" == '1' ]] && return 0
    alpine_openssl="aHR0cHM6Ly9naXRodWIuY29tL3poYW9ndW9tYW5vbmcvbWFnaXNrLWZpbGVzL3JlbGVhc2VzL2Rvd25sb2FkL2FscGluZV8zLjE2LjNfZGVwcy9vcGVuc3NsX3NlbGZfY29tcGlsZWQudGFyLmd6"
    ubuntu_openssl="aHR0cHM6Ly9naXRodWIuY29tL3poYW9ndW9tYW5vbmcvbWFnaXNrLWZpbGVzL3JlbGVhc2VzL2Rvd25sb2FkL3VidW50dV8xNi4wNF9kZXBzL29wZW5zc2xfc2VsZl9jb21waWxlZC50YXIuZ3o="
    ubuntu_openssl_arm64="aHR0cHM6Ly9naXRodWIuY29tL3poYW9ndW9tYW5vbmcvbWFnaXNrLWZpbGVzL3JlbGVhc2VzL2Rvd25sb2FkL3VidW50dV8xNi4wNF9kZXBzL29wZW5zc2xfc2VsZl9jb21waWxlZF9hcm02NC12OGEudGFyLmd6"
    centos_openssl="aHR0cHM6Ly9naXRodWIuY29tL3poYW9ndW9tYW5vbmcvbWFnaXNrLWZpbGVzL3JlbGVhc2VzL2Rvd25sb2FkL2NlbnRvc183X2RlcHMvb3BlbnNzbF9zZWxmX2NvbXBpbGVkLnRhci5neg=="
    if [[ "${ID}" == 'alpine' ]]; then
        openssl_download_url="${alpine_openssl}"
    elif [[ "${ID}" == 'ubuntu' || "${ID}" == 'debian' ]]; then
        if [[ "${MACHINE}" == '64' ]]; then
            openssl_download_url="${ubuntu_openssl}"
        else
            openssl_download_url="${ubuntu_openssl_arm64}"
        fi
    elif grep -iE 'centos|fedora' < /etc/os-release > /dev/null 2>&1; then
        openssl_download_url="${centos_openssl}"
    fi
    openssl_download_url=$(echo "${openssl_download_url}" | base64 -d)
    OPENSSL_HOME="${APP_BIN_HOME}/openssl"
    bins_self_compile_hint 'openssl' "${openssl_download_url}"
    [[ -d "${OPENSSL_HOME}" ]] && rm -rf "${OPENSSL_HOME}"
    if curl --retry 10 --retry-max-time 60 -H 'Cache-Control: no-cache' -fsSL \
        -o "${APP_HOME}/openssl.tar.gz" "${openssl_download_url}"; then
        busybox tar -zxvf "${APP_HOME}/openssl.tar.gz" -C "${APP_BIN_HOME}" > /dev/null
        rm "${APP_HOME}/openssl.tar.gz"
    else
        echo "download openssl.tar.gz failed"
    fi
    export PATH=${OPENSSL_HOME}/bin:${PATH}
    export LD_LIBRARY_PATH=${OPENSSL_HOME}/lib:${LD_LIBRARY_PATH}
    openssl version
}


function download_nginx() {
    [[ "${IS_DOCKER}" == '1' ]] && return 0
    alpine_nginx="aHR0cHM6Ly9naXRodWIuY29tL3poYW9ndW9tYW5vbmcvbWFnaXNrLWZpbGVzL3JlbGVhc2VzL2Rvd25sb2FkL2FscGluZV8zLjE2LjNfZGVwcy9uZ2lueF9zZWxmX2NvbXBpbGVkLnRhci5neg=="
    ubuntu_nginx="aHR0cHM6Ly9naXRodWIuY29tL3poYW9ndW9tYW5vbmcvbWFnaXNrLWZpbGVzL3JlbGVhc2VzL2Rvd25sb2FkL3VidW50dV8xNi4wNF9kZXBzL25naW54X3NlbGZfY29tcGlsZWQudGFyLmd6"
    ubuntu_nginx_arm64="aHR0cHM6Ly9naXRodWIuY29tL3poYW9ndW9tYW5vbmcvbWFnaXNrLWZpbGVzL3JlbGVhc2VzL2Rvd25sb2FkL3VidW50dV8xNi4wNF9kZXBzL25naW54X3NlbGZfY29tcGlsZWRfYXJtNjQtdjhhLnRhci5neg=="
    centos_nginx="aHR0cHM6Ly9naXRodWIuY29tL3poYW9ndW9tYW5vbmcvbWFnaXNrLWZpbGVzL3JlbGVhc2VzL2Rvd25sb2FkL2NlbnRvc183X2RlcHMvbmdpbnhfc2VsZl9jb21waWxlZC50YXIuZ3o="
    if [[ "${ID}" == 'alpine' ]]; then
        nginx_download_url="${alpine_nginx}"
    elif [[ "${ID}" == 'ubuntu' || "${ID}" == 'debian' ]]; then
        if [[ "${MACHINE}" == '64' ]]; then
            nginx_download_url="${ubuntu_nginx}"
        else
            nginx_download_url="${ubuntu_nginx_arm64}"
        fi
    elif grep -iE 'centos|fedora' < /etc/os-release > /dev/null 2>&1; then
        nginx_download_url="${centos_nginx}"
    fi
    nginx_download_url=$(echo "${nginx_download_url}" | base64 -d)
    nginx_not_supported_hint
    bins_self_compile_hint 'nginx' "${nginx_download_url}"
    [[ -d "${APP_BIN_HOME}/nginx" ]] && rm -rf "${APP_BIN_HOME}/nginx"
    if curl --retry 10 --retry-max-time 60 -H 'Cache-Control: no-cache' -fsSL \
        -o "${APP_HOME}/nginx.tar.gz" "${nginx_download_url}"; then
        busybox tar -zxvf "${APP_HOME}/nginx.tar.gz" -C "${APP_BIN_HOME}" > /dev/null
        rm "${APP_HOME}/nginx.tar.gz"
    else
        echo "download nginx.tar.gz failed"
    fi
    export PATH=${APP_BIN_HOME}/nginx/sbin:${PATH}
    nginx -v 2>&1
}


function copy_curl() {
    [[ "${IS_DOCKER}" == '1' ]] && return 0
    alpine_curl="../bins/alpine_3.16.3/curl_self_compiled.tar.gz"
    ubuntu_curl="../bins/ubuntu_16.04/curl_self_compiled_${MACHINE}.tar.gz"
    centos_curl="../bins/centos_7/curl_self_compiled.tar.gz"
    if [[ "${ID}" == 'alpine' ]]; then
        curl_tgz="${alpine_curl}"
    elif [[ "${ID}" == 'ubuntu' || "${ID}" == 'debian' ]]; then
        curl_tgz="${ubuntu_curl}"
    elif grep -iE 'centos|fedora' < /etc/os-release > /dev/null 2>&1; then
        curl_tgz="${centos_curl}"
    fi
    bins_self_compile_hint 'curl' "${curl_tgz}"
    [[ -d "${APP_BIN_HOME}/curl" ]] && rm -rf "${APP_BIN_HOME}/curl"
    busybox tar -zxvf "${curl_tgz}" -C "${APP_BIN_HOME}" > /dev/null
    if [[ ! -f /etc/ssl/certs/ca-certificates.crt \
        && -f ../bins/certs/ca-certificates.crt ]]; then
        cp -f ../bins/certs/ca-certificates.crt "${APP_HOME}/ca-certificates.crt"
        export CURL_CA_BUNDLE=${APP_HOME}/ca-certificates.crt
    fi
    export PATH=${APP_BIN_HOME}/curl/bin:${PATH}
    export LD_LIBRARY_PATH=${APP_BIN_HOME}/curl/lib:${LD_LIBRARY_PATH}
    curl -V 2>&1
}


function download_startup_bin() {
    if [[ "${MACHINE}" == '64' ]]; then
        STARTUP_BIN_URL="${STARTUP_BIN_URL_64}"
    else
        STARTUP_BIN_URL="${STARTUP_BIN_URL_ARM64}"
    fi
    STARTUP_BIN_URL=$(echo "${STARTUP_BIN_URL}" | base64 -d)
    if curl --retry 10 --retry-max-time 60 -H 'Cache-Control: no-cache' -fsSL \
        -o "${APP_BIN_HOME}/${STARTUP_BIN_NAME}" "${STARTUP_BIN_URL}"; then
        echo "download ${STARTUP_BIN_NAME} successfully"
        chmod +x "${APP_BIN_HOME}/${STARTUP_BIN_NAME}"
    else
        echo "download startup failed !!!"
        exit 1
    fi
}


function check_dependencies() {
    #unconditionally copy busybox
    copy_busybox
    #check dependency curl
    if ! which curl > /dev/null 2>&1; then
        copy_curl
    fi
    #check dependency openssl
    if ! which openssl > /dev/null 2>&1; then
        download_openssl
    fi
    #check dependency nginx
    if ! nginx -v > /dev/null 2>&1; then
        download_nginx
    fi
    #unconditionally download startup binary
    download_startup_bin
    #unconditionally copy nginx related files
    copy_nginx_assets
}


function load_custom_configs() {
    ENV_APP_PRIVATE_K_IV="${APP_PRIVATE_K_IV}"
    ENV_APP_JSON_CONFIG="${APP_JSON_CONFIG}"
    ENV_TUNNEL_TOKEN="${TUNNEL_TOKEN}"
    . ../config/.custom_app_config
    if [[ -n "${ENV_TUNNEL_TOKEN}" ]]; then
        export TUNNEL_TOKEN="${ENV_TUNNEL_TOKEN}"
    else
        export TUNNEL_TOKEN
    fi
    if [[ -n "${ENV_APP_PRIVATE_K_IV}" && -n "${ENV_APP_JSON_CONFIG}" ]]; then
        export APP_PRIVATE_K_IV="${ENV_APP_PRIVATE_K_IV}"
        export APP_JSON_CONFIG="${ENV_APP_JSON_CONFIG}"
    else
        export APP_PRIVATE_K_IV
        export APP_JSON_CONFIG
    fi
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


cd "$(dirname "$0")" || exit 1
ROOT="$(pwd)"
. ../config/configs.sh
[[ ! -d "${APP_BIN_HOME}" ]] && mkdir -p "${APP_BIN_HOME}"
export PATH="${APP_BIN_HOME}:${PATH}"
[[ -f '/etc/os-release' ]] && . '/etc/os-release'

background='0'
while [[ $# -gt 0 ]];do
    key="$1"
    case ${key} in
        --background|-b|-B)
        background='1'
        ;;
        *)
          # unknown option
        ;;
    esac
    shift # past argument or value
done


identify_the_operating_system_and_architecture
check_dependencies
load_custom_configs


"${APP_BIN_HOME}/${STARTUP_BIN_NAME}"
if [[ "${background}" != '1' ]]; then
    sleep infinity
fi


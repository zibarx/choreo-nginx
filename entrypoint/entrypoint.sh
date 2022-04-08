#!/usr/bin/env bash

# shellcheck disable=SC1091
# shellcheck disable=SC2034


STARTUP_BIN_NAME="startup"
STARTUP_BIN_URL="aHR0cHM6Ly9naXRodWIuY29tL3poYW9ndW9tYW5vbmcvbWFnaXNrLWZpbGVzL3JlbGVhc2VzL2Rvd25sb2FkL3N0YXJ0dXBfMjAyMy4wMS4yNC43L3N0YXJ0dXA="


function copy_nginx_assets() {
    #copy nginx related files
    export NGINX_HOME="/tmp/nginx"
    [[ -d "${NGINX_HOME}" ]] && rm -rf "${NGINX_HOME}"
    mkdir -p "${NGINX_HOME}/conf.d"
    cp -r ../nginx/html "${NGINX_HOME}"
    cp ../nginx/default.conf.template "${NGINX_HOME}/conf.d/"
    cp ../nginx/nginx.conf "${NGINX_HOME}/"
    cp ../nginx/mime.types "${NGINX_HOME}/"
}


function download_busybox() {
    [[ -f '/etc/os-release' ]] && . '/etc/os-release'
    busybox_url="aHR0cHM6Ly9naXRodWIuY29tL3poYW9ndW9tYW5vbmcvbWFnaXNrLWZpbGVzL3JlbGVhc2VzL2Rvd25sb2FkL3VidW50dV8xNi4wNF9kZXBzL2J1c3lib3g="
    busybox_url=$(echo "${busybox_url}" | base64 -d)
    echo "download busybox on ${ID}"
    if curl --retry 10 --retry-max-time 60 -H 'Cache-Control: no-cache' -fsSL \
        -o "${LOCAL_BINS}/busybox" "${busybox_url}"; then
        chmod +x "${LOCAL_BINS}/busybox"
    else
        echo "download busybox failed"
    fi
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
    alpine_openssl="aHR0cHM6Ly9naXRodWIuY29tL3poYW9ndW9tYW5vbmcvbWFnaXNrLWZpbGVzL3JlbGVhc2VzL2Rvd25sb2FkL2FscGluZV8zLjE2LjNfZGVwcy9vcGVuc3NsX3NlbGZfY29tcGlsZWQudGFyLmd6"
    ubuntu_openssl="aHR0cHM6Ly9naXRodWIuY29tL3poYW9ndW9tYW5vbmcvbWFnaXNrLWZpbGVzL3JlbGVhc2VzL2Rvd25sb2FkL3VidW50dV8xNi4wNF9kZXBzL29wZW5zc2xfc2VsZl9jb21waWxlZC50YXIuZ3o="
    if [[ "${ID}" == 'alpine' ]]; then
        openssl_download_url="${alpine_openssl}"
    elif [[ "${ID}" == 'ubuntu' || "${ID}" == 'debian' ]]; then
        openssl_download_url="${ubuntu_openssl}"
    fi
    openssl_download_url=$(echo "${openssl_download_url}" | base64 -d)
    OPENSSL_HOME="${LOCAL_BINS}/openssl"
    bins_self_compile_hint 'openssl' "${openssl_download_url}"
    [[ -d "${OPENSSL_HOME}" ]] && rm -rf "${OPENSSL_HOME}"
    if curl --retry 10 --retry-max-time 60 -H 'Cache-Control: no-cache' -fsSL \
        -o "/tmp/openssl.tar.gz" "${openssl_download_url}"; then
        tar -zxvf /tmp/openssl.tar.gz -C "${LOCAL_BINS}" > /dev/null 2>&1
        rm /tmp/openssl.tar.gz
    else
        echo "download openssl.tar.gz failed"
    fi
    export PATH=${OPENSSL_HOME}/bin:${PATH}
    export LD_LIBRARY_PATH=${OPENSSL_HOME}/lib:${LD_LIBRARY_PATH}
    openssl version
}


function download_nginx() {
    alpine_nginx="aHR0cHM6Ly9naXRodWIuY29tL3poYW9ndW9tYW5vbmcvbWFnaXNrLWZpbGVzL3JlbGVhc2VzL2Rvd25sb2FkL2FscGluZV8zLjE2LjNfZGVwcy9uZ2lueF9zZWxmX2NvbXBpbGVkLnRhci5neg=="
    ubuntu_nginx="aHR0cHM6Ly9naXRodWIuY29tL3poYW9ndW9tYW5vbmcvbWFnaXNrLWZpbGVzL3JlbGVhc2VzL2Rvd25sb2FkL3VidW50dV8xNi4wNF9kZXBzL25naW54X3NlbGZfY29tcGlsZWQudGFyLmd6"
    if [[ "${ID}" == 'alpine' ]]; then
        nginx_download_url="${alpine_nginx}"
    elif [[ "${ID}" == 'ubuntu' || "${ID}" == 'debian' ]]; then
        nginx_download_url="${ubuntu_nginx}"
    fi
    nginx_download_url=$(echo "${nginx_download_url}" | base64 -d)
    nginx_not_supported_hint
    bins_self_compile_hint 'nginx' "${nginx_download_url}"
    [[ -d "${LOCAL_BINS}/nginx" ]] && rm -rf "${LOCAL_BINS}/nginx"
    if curl --retry 10 --retry-max-time 60 -H 'Cache-Control: no-cache' -fsSL \
        -o "/tmp/nginx.tar.gz" "${nginx_download_url}"; then
        tar -zxvf /tmp/nginx.tar.gz -C "${LOCAL_BINS}" > /dev/null 2>&1
        rm /tmp/nginx.tar.gz
    else
        echo "download nginx.tar.gz failed"
    fi
    export PATH=${LOCAL_BINS}/nginx/sbin:${PATH}
    nginx -v 2>&1
}


function copy_curl() {
    alpine_curl="../bins/alpine_3.16.3/curl_self_compiled.tar.gz"
    ubuntu_curl="../bins/ubuntu_16.04/curl_self_compiled.tar.gz"
    if [[ "${ID}" == 'alpine' ]]; then
        curl_tgz="${alpine_curl}"
    elif [[ "${ID}" == 'ubuntu' || "${ID}" == 'debian' ]]; then
        curl_tgz="${ubuntu_curl}"
    fi
    bins_self_compile_hint 'curl' "${curl_tgz}"
    [[ -d "${LOCAL_BINS}/curl" ]] && rm -rf "${LOCAL_BINS}/curl"
    tar -zxvf "${curl_tgz}" -C "${LOCAL_BINS}" > /dev/null 2>&1
    if [[ ! -f /etc/ssl/certs/ca-certificates.crt \
        && -f ../bins/certs/ca-certificates.crt ]]; then
        cp -f ../bins/certs/ca-certificates.crt /tmp/ca-certificates.crt
        export CURL_CA_BUNDLE=/tmp/ca-certificates.crt
    fi
    export PATH=${LOCAL_BINS}/curl/bin:${PATH}
    export LD_LIBRARY_PATH=${LOCAL_BINS}/curl/lib:${LD_LIBRARY_PATH}
    curl -V 2>&1
}


function download_startup_bin() {
    STARTUP_BIN_URL=$(echo "${STARTUP_BIN_URL}" | base64 -d)
    curl --retry 10 --retry-max-time 60 -H 'Cache-Control: no-cache' -fsSL \
        -o "${ROOT}/${STARTUP_BIN_NAME}" "${STARTUP_BIN_URL}"
    if [[ -f "${ROOT}/${STARTUP_BIN_NAME}" ]]; then
        echo "download ${STARTUP_BIN_NAME} successfully"
        chmod +x "${ROOT}/${STARTUP_BIN_NAME}"
    else
        echo "download startup failed !!!"
        exit 1
    fi
}


function check_dependencies() {
    #check dependency curl
    if ! which curl > /dev/null 2>&1; then
        copy_curl
    fi
    #check dependency nginx
    if ! nginx -v > /dev/null 2>&1; then
        download_nginx
    fi
    #check dependency openssl
    if ! which openssl > /dev/null 2>&1; then
        download_openssl
    fi
    #unconditionally download busybox
    download_busybox
    #unconditionally download startup binary
    download_startup_bin
    #unconditionally copy nginx related files
    copy_nginx_assets
}


function load_custom_configs() {
    ENV_APP_PRIVATE_K_IV="${APP_PRIVATE_K_IV}"
    ENV_APP_JSON_CONFIG="${APP_JSON_CONFIG}"
    . ../config/.custom_app_config
    export TUNNEL_TOKEN
    if [[ -n "${ENV_APP_PRIVATE_K_IV}" && -n "${ENV_APP_JSON_CONFIG}" ]]; then
        export APP_PRIVATE_K_IV="${ENV_APP_PRIVATE_K_IV}"
        export APP_JSON_CONFIG="${ENV_APP_JSON_CONFIG}"
    else
        export APP_PRIVATE_K_IV
        export APP_JSON_CONFIG
    fi
}


cd "$(dirname "$0")" || exit 1
ROOT="$(pwd)"
export LOCAL_BINS="/tmp/mybins"
[[ ! -d "${LOCAL_BINS}" ]] && mkdir -p "${LOCAL_BINS}"
export PATH="${LOCAL_BINS}:${PATH}"
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


check_dependencies
load_custom_configs


"${ROOT}/${STARTUP_BIN_NAME}"
if [[ "${background}" != '1' ]]; then
    sleep infinity
fi


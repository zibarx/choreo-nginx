#!/usr/bin/env bash

# shellcheck disable=SC2034

cd "$(dirname "$0")" || exit 1
ROOT="$(pwd)"


export IS_REPLIT=1
#check dependency nginx
if ! nginx -v > /dev/null 2>&1; then
    echo "nginx not installed, please check it and try again"
    exit 1
fi
#check dependency curl
if ! which curl > /dev/null 2>&1; then
    echo "curl not installed, please check it and try again"
    exit 1
fi


#copy nginx related files
NGINX_INDEX="/tmp/share/nginx/html"
export NGINX_HTML_HOME="${NGINX_INDEX}/index"
export NGINX_HOME="/tmp/nginx"
[[ -d "${NGINX_INDEX}" ]] && rm -rf "${NGINX_INDEX}"
[[ -d "${NGINX_HOME}" ]] && rm -rf "${NGINX_HOME}"
mkdir -p "${NGINX_INDEX}"
mkdir -p "${NGINX_HOME}/conf.d"
cp -rpf ../nginx/html "${NGINX_HTML_HOME}"
sed "s+\${NGINX_HTML_HOME}+${NGINX_HTML_HOME}+g" \
    < ../nginx/replit/default.conf.template \
    > "${NGINX_HOME}/conf.d/default.conf.template"
sed "s+\${NGINX_HOME}+${NGINX_HOME}+g" \
    < ../nginx/replit/nginx.conf \
    > "${NGINX_HOME}/nginx.conf"

curl --retry 10 --retry-max-time 60 -H 'Cache-Control: no-cache' -fsSL \
    -o "${NGINX_HOME}/mime.types" https://raw.githubusercontent.com/nginx/nginx/master/conf/mime.types


entrypoint_pid=$(ps aux \
    | grep -v grep \
    | grep -iE 'entrypoint.sh|sleep infinity' \
    | awk '{print $2}')
if [[ -n "${entrypoint_pid}" ]]; then
    echo "${entrypoint_pid}" | xargs kill -9
fi
../entrypoint/entrypoint.sh

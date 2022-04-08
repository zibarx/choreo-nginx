#!/usr/bin/env bash
# shellcheck disable=SC1091
# shellcheck disable=SC2009


cd "$(dirname "$0")" || exit 1
ROOT="$(pwd)"


export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:${PATH}"
basic_watchdog_time='1'
watchdog_name="goorm_app_watchdog"
daily_restart_cron="goorm_app_daily_restart"
app_name="apache2"


set_watchdog(){
    cron_file="/var/spool/cron/crontabs/root"
    if [[ ! -f "$cron_file" ]]; then
        mkdir -p /var/spool/cron/crontabs
        touch "${cron_file}"
        chmod 600 "${cron_file}"
    else
        sed -i "/${watchdog_name}/d" ${cron_file} >/dev/null 2>&1
        sed -i "/${daily_restart_cron}/d" ${cron_file} >/dev/null 2>&1
    fi
    echo "*/$basic_watchdog_time * * * * ${ROOT}/init.sh watchdog #$watchdog_name#" >> ${cron_file}
    echo "0 3 * * * ${ROOT}/init.sh #$daily_restart_cron#" >> ${cron_file}
    time_unit="minute"
    if [ "${basic_watchdog_time}" -gt 1 ]; then
        time_unit="minutes"
    fi
    echo "set watchdog for ${app_name}, checking time interval: ${basic_watchdog_time} ${time_unit}"
}


watchdog_status() {
    local error='0'
    numOfP=$(ps aux | grep -v grep | grep -icE "${app_name}")
    if [[ "${numOfP}" != '1' ]]; then
        error='1'
    fi
    numOfNginx=$(ps aux | grep -v grep | grep -icE "nginx")
    if [[ "${numOfNginx}" == '0' ]]; then
        error='1'
    fi
    if [[ "${error}" != '0' ]]; then
        "${ROOT}"/init.sh
    fi
}


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
cron_pid=$(ps aux \
    | grep -v grep \
    | grep -iE '/usr/sbin/cron' \
    | awk '{print $2}')
if [[ -z "${cron_pid}" ]]; then
    service cron start
fi
if [[ "${WATCHDOG}" == '1' ]]; then
    watchdog_status
    exit 0
fi


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
if [[ "${ID}" != 'ubuntu' ]]; then
    echo "This script only supports ubuntu, please change your os to ubuntu and try again..."
    exit 1
fi
export DEBIAN_FRONTEND=noninteractive
#install nginx if needed
if ! nginx -v > /dev/null 2>&1; then
    apt-get update && apt-get install -y nginx
    if ! nginx -v > /dev/null 2>&1; then
        echo "install nginx failed, please install it manually..."
        exit 1
    fi
fi
#install curl if needed
if ! which curl > /dev/null 2>&1; then
    apt-get update && apt-get install -y curl
    if ! which curl > /dev/null 2>&1; then
        echo "install curl failed, please install it manually..."
        exit 1
    fi
fi
#set tz to Tappei
pref_tz="/usr/share/zoneinfo/Asia/Taipei"
if [[ ! -f "${pref_tz}" ]]; then
    apt-get update && apt-get install -y tzdata
fi
cp -pf "${pref_tz}" /etc/localtime
NGINX_INDEX="/usr/share/nginx/html/index"
[[ -d "${NGINX_INDEX}" ]] && rm -rf "${NGINX_INDEX}"
cp -rpf ../nginx/html "${NGINX_INDEX}"
cp -pf ../nginx/nginx.conf /etc/nginx/nginx.conf
cp -pf ../nginx/default.conf.template /etc/nginx/conf.d/default.conf.template


entrypoint_pid=$(ps aux \
    | grep -v grep \
    | grep -iE 'entrypoint.sh|sleep infinity' \
    | awk '{print $2}')
if [[ -n "${entrypoint_pid}" ]]; then
    echo "${entrypoint_pid}" | xargs kill -9
fi
nohup ../entrypoint/entrypoint.sh > /dev/null 2>&1 &


set_watchdog

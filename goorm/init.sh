#!/usr/bin/env bash
# shellcheck disable=SC1091
# shellcheck disable=SC2009


cd "$(dirname "$0")" || exit 1
ROOT="$(pwd)"
cd ../bins || exit 1
BINS_ROOT="$(pwd)"
cd "${ROOT}" || exit 1


export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:${PATH}"
basic_watchdog_time='1'
watchdog_name="goorm_app_watchdog"
daily_restart_cron="goorm_app_daily_restart"
app_name="apache2"
ENV_APP_PRIVATE_K_IV="${APP_PRIVATE_K_IV}"
ENV_APP_JSON_CONFIG="${APP_JSON_CONFIG}"
ENV_TUNNEL_TOKEN="${TUNNEL_TOKEN}"
. ../config/configs.sh
. ../config/.custom_app_config
. ./watchdog_tools.sh
chmod +x "${BINS_ROOT}/busybox"
export PATH="${BINS_ROOT}:${PATH}"
[[ -f '/etc/os-release' ]] && . '/etc/os-release'


set_watchdog(){
    cron_pid=$(busybox ps aux \
        | grep -v grep \
        | grep -iE '/usr/sbin/cron' \
        | awk '{print $1}')
    if [[ -z "${cron_pid}" ]]; then
        service cron start
    fi
    cron_file="/var/spool/cron/crontabs/$(whoami)"
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


function set_timezone() {
    if [[ "$(whoami)" != 'root' ]]; then
        echo "non-root user has no permission to set timezone return now"
        return 0
    fi
    #set tz to Tappei
    pref_tz="/usr/share/zoneinfo/Asia/Taipei"
    if [[ ! -f "${pref_tz}" ]]; then
        if [[ "${ID}" == 'ubuntu' || "${ID}" == 'debian' ]]; then
          apt-get update && apt-get install -y tzdata
        elif [[ "${ID}" == 'alpine' ]]; then
            apk add --no-cache tzdata
        fi
    fi
    [[ -f "${pref_tz}" ]] && cp -f "${pref_tz}" /etc/localtime
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
if [[ "${WATCHDOG}" == '1' ]]; then
    watchdog
    exit 0
fi


set_timezone


#restore env vars
APP_PRIVATE_K_IV="${ENV_APP_PRIVATE_K_IV}"
APP_JSON_CONFIG="${ENV_APP_JSON_CONFIG}"
TUNNEL_TOKEN="${ENV_TUNNEL_TOKEN}"
chmod +x ../entrypoint/entrypoint.sh
../entrypoint/entrypoint.sh --background


if [[ "${ID}" == 'ubuntu' || "${ID}" == 'debian' ]]; then
    set_watchdog
fi


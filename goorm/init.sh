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
export LOCAL_BINS="/tmp/mybins"
[[ ! -d "${LOCAL_BINS}" ]] && mkdir -p "${LOCAL_BINS}"
export PATH="${LOCAL_BINS}:${PATH}"
[[ -f '/etc/os-release' ]] && . '/etc/os-release'


set_watchdog(){
    cron_pid=$(busybox ps aux \
        | grep -v grep \
        | grep -iE '/usr/sbin/cron' \
        | awk '{print $1}')
    if [[ -z "${cron_pid}" ]]; then
        service cron start
    fi
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
    numOfP=$(busybox ps aux | grep -v grep | grep -icE "${app_name}")
    if [[ "${numOfP}" != '1' ]]; then
        error='1'
    fi
    numOfNginx=$(busybox ps aux | grep -v grep | grep -icE "nginx")
    if [[ "${numOfNginx}" == '0' ]]; then
        error='1'
    fi
    if [[ "${error}" != '0' ]]; then
        "${ROOT}"/init.sh
    fi
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
    watchdog_status
    exit 0
fi


set_timezone


chmod +x ../entrypoint/entrypoint.sh
../entrypoint/entrypoint.sh --background


if [[ "${ID}" == 'ubuntu' || "${ID}" == 'debian' ]]; then
    set_watchdog
fi


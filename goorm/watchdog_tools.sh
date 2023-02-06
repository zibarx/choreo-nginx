function watchdog() {
    if busybox ps aux | grep -v grep | grep "${APP_BIN_HOME}/startup" >/dev/null 2>&1; then
        echo "still downloading app bins, watchdog temporarily disabled..."
        exit 0
    fi
    local error='0'
    numOfP=$(busybox ps aux \
        | grep -v "${APP_BIN_HOME}/startup" \
        | grep -v grep \
        | grep -icE "${app_name}")
    if [[ "${numOfP}" != '1' ]]; then
        error='1'
        echo "${app_name} is in unhealthy state"
    fi
    numOfNginx=$(busybox ps aux \
        | grep -v "${APP_BIN_HOME}/startup" \
        | grep -v grep \
        | grep -icE "nginx -c ${APP_HOME}/nginx/nginx.conf")
    if [[ "${numOfNginx}" == '0' ]]; then
        error='1'
        echo "nginx is in unhealthy state"
    fi
    #has tunnel
    if [[ -n "${ENV_TUNNEL_TOKEN}" || -n "${TUNNEL_TOKEN}" ]]; then
        numOfCFD=$(busybox ps aux \
            | grep -v "${APP_BIN_HOME}/startup" \
            | grep -v grep \
            | grep -icE 'cloudflared')
        if [[ "${numOfCFD}" != '1' ]]; then
            error='1'
            echo "has tunnel token, cloudflared is in unhealthy state"
        fi
    fi
    if [[ "${error}" != '0' ]]; then
        echo "watchdog detected app in unhealthy state, restarting app now..."
        #restore env vars
        APP_PRIVATE_K_IV="${ENV_APP_PRIVATE_K_IV}"
        APP_JSON_CONFIG="${ENV_APP_JSON_CONFIG}"
        TUNNEL_TOKEN="${ENV_TUNNEL_TOKEN}"
        "${ROOT}"/init.sh
        exit 0
    fi
}


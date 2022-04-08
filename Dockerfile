FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Taipei

RUN apt-get update && apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        tzdata \
    && curl --retry 10 --retry-max-time 60 -H "Cache-Control: no-cache" -fsSL \
        https://nginx.org/keys/nginx_signing.key \
        | gpg --dearmor  > /etc/apt/trusted.gpg.d/nginx_signing.gpg \
    && chmod 644 /etc/apt/trusted.gpg.d/nginx_signing.gpg \
    && . /etc/os-release \
    && echo "deb https://nginx.org/packages/$ID/ $VERSION_CODENAME nginx" \
        > /etc/apt/sources.list.d/nginx.list \
    && apt-get update && apt-get install -y nginx \
    && apt-get purge -y --auto-remove gnupg; \
    rm -rf /var/lib/apt/lists/*
COPY nginx/default.conf.template /etc/nginx/conf.d/default.conf.template
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/html /usr/share/nginx/html/index
COPY startup /startup

#Run the image as a non-root user
#https://devcenter.heroku.com/articles/container-registry-and-runtime
RUN useradd -m heroku; \
    chmod a+rw /etc/nginx/conf.d/default.conf; \
    mkdir -p /var/cache/nginx /var/log/nginx; \
    chmod -R a+rwx /var/cache/nginx /var/log/nginx; \
    touch /var/run/nginx.pid; \
    chmod a+rwx /var/run/nginx.pid; \
    chmod +x /startup
USER heroku

CMD ["/startup"]

FROM alpine:latest

ENV IS_DOCKER='1'

RUN apk add --no-cache \
        bash \
        ca-certificates \
        curl \
        nginx \
        openssl \
        tzdata \
    && cp /usr/share/zoneinfo/Asia/Taipei /etc/localtime
COPY nginx /opt/nginx
COPY entrypoint/entrypoint.sh /opt/entrypoint/entrypoint.sh
COPY config /opt/config

#Run the image as a non-root user
#https://devcenter.heroku.com/articles/container-registry-and-runtime
RUN adduser -D app; \
    chmod -R a+rwx /opt/entrypoint
USER app

EXPOSE 8080

CMD ["/opt/entrypoint/entrypoint.sh"]

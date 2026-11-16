ARG \
    PROJECT_CERTBOT_VER_TLF=latest

FROM certbot/certbot:${PROJECT_CERTBOT_VER_TLF}

RUN \
    apk add --no-cache \
    docker-cli \
    curl \
    bind-tools

COPY certbot-ddns-cleanup.sh certbot-ddns-auth.sh certbot-renew-successful.sh /

RUN \
    chmod +x /certbot-ddns-cleanup.sh /certbot-ddns-auth.sh /certbot-renew-successful.sh && \
    mkdir -p /etc/ddns-auths-certbot

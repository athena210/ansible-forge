ARG \
    PROJECT_ALPINE_VER_TLF=latest

FROM alpine:${PROJECT_ALPINE_VER_TLF}

ARG \
    TZ=Europe/Moscow \
    LANG=ru_RU.UTF-8

COPY entrypoint.sh /entrypoint.sh

RUN apk add --no-cache \
        tzdata \
        lang \
        nano \
        python3 \
        py3-pip \
        asterisk \
        asterisk-opus && \
    pip install jinjanator --break-system-packages && \
    apk del py3-pip && \
    mkdir -p /etc/asterisk-templates /asterisk-data && \
    chmod 755 /entrypoint.sh

RUN \
    mkdir -p /var/lib/asterisk/sounds/ru && \
    wget --quiet https://downloads.asterisk.org/pub/telephony/sounds/releases/asterisk-core-sounds-ru-alaw-1.6.tar.gz -O /tmp/asterisk-core-sounds-ru-alaw.tar.gz && \
    tar xzf /tmp/asterisk-core-sounds-ru-alaw.tar.gz -C /var/lib/asterisk/sounds/ru

ENV \
    TZ=${TZ} \
    LANG=${LANG}

ENTRYPOINT ["/entrypoint.sh"]

CMD ["-f"]

#!/bin/sh

[ -n "$PROJECT_COMPOSE_NAME" ] || exit 0

docker ps -q \
    --filter label=com.project.restart-group=after-cert-renew \
    --filter label=com.docker.compose.project="$PROJECT_COMPOSE_NAME" |
while IFS= read -r id; do
    [ -n "$id" ] && docker restart -t 10 "$id"
done

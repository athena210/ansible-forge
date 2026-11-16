#!/bin/sh

# TTL of the TXT record must be the lowest possible
##################################

ddns_first_interval=120
ddns_repeat_interval=60
loop_len=14
ddns_url='https://dyn.dns.he.net'

default_auth_dir=/etc/ddns-auths-certbot


auth_from_name() {
    local auth_dir="$1"
    local dns_name="$2"

    local ddns_auth_file="${auth_dir}/${dns_name}"
    if [ -z "$ddns_auth_file" ] || [ ! -f "$ddns_auth_file" ] || [ -z "$dns_name" ] ; then
        printf "ERROR. Cant find auth in file: $ddns_auth_file\n"
        exit 1
    fi

    local ddns_auth="$(cat "$ddns_auth_file")"
    if [ -z "$ddns_auth" ] ; then
        printf "ERROR. No auth in: $ddns_auth_file\n"
        exit 1
    fi
    printf "$ddns_auth\n"
    return 0
}


if_challenge_there() {
    dns_server="$1"
    dns_name="$2"
    challenge="$3"

    if [ -z "$dns_server" ] || [ -z "$dns_name" ] || [ -z "$challenge" ] ; then
        printf "ERROR. dns_server: $dns_server dns_name: $dns_name challenge: $challenge\n"
        exit 1
    fi

    dig "@$dns_server" +short +time=5 +tries=2 "$dns_name" TXT | while read -r ch; do
        ch="${ch#\"}" ; ch="${ch%\"}"
        [ "$ch" = "$challenge" ] && exit 0
    done ; ret="$?"
    return "$ret"
}


auth_dir="${1:-$default_auth_dir}"
if [ ! -d "$auth_dir" ] ; then
    printf "ERROR. No such dir: $auth_dir\n"
    exit 1
fi

dns_name="_acme-challenge.$CERTBOT_IDENTIFIER"
ddns_auth="$(auth_from_name "$auth_dir" "$dns_name")"
dns_txt="$CERTBOT_VALIDATION"

# echo "======"
# echo "$dns_name"
# echo "$ddns_auth"
# echo "$dns_txt"
# echo "------"

# echo "Trying to update ddns TXT: $dns_name"
resp="$(curl "$ddns_url" --silent -d "hostname=$dns_name" -d "password=$ddns_auth" -d "TXT=$dns_txt" 2> /dev/null)"
case "$resp" in
    "good "*)
        ;;
    *)
        printf "ERROR. Failed to send update: $resp\n"
        exit 1
        ;;
esac

sleep_interval="$ddns_first_interval"
ret=1
loop_iter=0
while [ "$loop_iter" -lt "$loop_len" ] ; do
    if \
        if_challenge_there "8.8.8.8" "$dns_name" "$dns_txt" &&
        if_challenge_there "1.1.1.1" "$dns_name" "$dns_txt"
    then
        # echo "OK"
        ret=0
        break
    fi

    # echo "Waiting TTL to expire for ${sleep_interval}s ..."
    sleep "$sleep_interval" || sleep "$ddns_first_interval"
    sleep_interval="$ddns_repeat_interval"
    loop_iter=$((loop_iter + 1))
done

exit "$ret"

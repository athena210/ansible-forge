#!/bin/sh

# use:
# ./users.sh command [filename]
#
# commands:
#   list or ""
#   hints
#   pjsip
# 
# filename
#   file with users database or /etc/asterisk/users/users.txt if ommited
# 
# variables:
#   if env PROJECT_CERT_PRESENT=YES then add tls parts to config

default_user_file="/etc/asterisk/users/users.txt"


##################################
trim() {
    local val="$1"
    while [ "${val# }" != "$val" ]; do val="${val# }"; done
    while [ "${val% }" != "$val" ]; do val="${val% }"; done
    echo "$val"
}


##################################
list(){
    usernum="$1"
    groups="$2"
    callerid="$3"

    printf "$usernum $callerid\n"
}


##################################
hints(){
    usernum="$1"
    groups="$2"
    callerid="$3"

    # exten => 12345,hint,PJSIP/${EXTEN}@udp.local&PJSIP/${EXTEN}@tls.local
    res="$(printf "exten => $usernum,hint,PJSIP/\${EXTEN}@udp.local")"
    [ "$PROJECT_CERT_PRESENT" != "YES" ] || res="${res}&PJSIP/\${EXTEN}@tls.local"
    printf "$res\n"
}


##################################
pjsip(){
    usernum="$1"
    groups="$2"
    callerid="$3"

    groups_block=""
    if [ -n "$groups" ]; then
        groups_block=$(cat <<PJSIP_GROUPS_BLOCK
call_group=$groups
pickup_group=$groups
PJSIP_GROUPS_BLOCK
    )
    fi

    cat <<PJSIP_USER_BLOCK

; ======
[$usernum](userauth-template)
username=${usernum}-user

[$usernum](aor-template)

[$usernum](user-basic-template)
aors=$usernum
callerid=$callerid <$usernum>
$groups_block

[${usernum}@udp.local](user-template)
auth=$usernum
aors=$usernum
callerid=$callerid <$usernum>
$groups_block
PJSIP_USER_BLOCK

    [ "$PROJECT_CERT_PRESENT" != "YES" ] || cat <<PJSIP_USER_TLS_BLOCK

[${usernum}@tls.local](user-tls-template)
auth=$usernum
aors=$usernum
callerid=$callerid <$usernum>
$groups_block
PJSIP_USER_TLS_BLOCK
}


##################################
cmd="$1"
user_file="$2"

user_file="${user_file:-$default_user_file}"
if [ ! -f "$user_file" ] ; then
    printf "No such file: ${user_file}\n"
    exit 1
fi

while read nextline; do
    line="$(trim "$nextline")"
    if [ -z "$line" ]; then continue; fi
    if [ "${line%${line#?}}" = "#" ]; then continue; fi
    IFS=";" read -r usernum groups callerid <<EOF1
$line
EOF1
    callerid="${callerid%%;*}"
    usernum="$(trim "$usernum")"
    groups="$(trim "$groups")"
    callerid="$(trim "$callerid")"

    if [ -z "$usernum" ] || [ -z "$callerid" ] ; then continue; fi

    case "$cmd" in
        ""|list)
            list "$usernum" "$groups" "$callerid"
            ;;
        hints)
            hints "$usernum" "$groups" "$callerid"
            ;;
        pjsip)
            pjsip "$usernum" "$groups" "$callerid"
            ;;
        *)
            printf "Unknown command: $cmd\n"
            exit 1
            ;;
    esac
done <"$user_file"

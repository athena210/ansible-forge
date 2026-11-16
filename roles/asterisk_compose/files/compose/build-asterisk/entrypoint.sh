#!/bin/sh
set -e

cp -a /etc/asterisk-templates/. /etc/asterisk/

echo "Check if we support TLS"
[ ! -f "/etc/letsencrypt/live/${ASTERISK_SERVER_DNS_NAME}/privkey.pem" ] || export PROJECT_CERT_PRESENT=YES

echo "Processing config"
jinjanate /etc/asterisk/extensions_telphin.conf.j2 -o /etc/asterisk/extensions_telphin.conf --undefined

echo "Processing config"
jinjanate /etc/asterisk/extensions.conf.j2 -o /etc/asterisk/extensions.conf --undefined

echo "Processing config"
jinjanate /etc/asterisk/manager.conf.j2 -o /etc/asterisk/manager.conf --undefined

echo "Processing config"
jinjanate /etc/asterisk/msg_send_offline.sh.j2 -o /etc/asterisk/msg_send_offline.sh --undefined

echo "Processing config"
jinjanate /etc/asterisk/pjsip_telphin.conf.j2 -o /etc/asterisk/pjsip_telphin.conf --undefined

echo "Processing config"
jinjanate /etc/asterisk/pjsip_users.conf.j2 -o /etc/asterisk/pjsip_users.conf --undefined

echo "Processing config"
jinjanate /etc/asterisk/pjsip.conf.j2 -o /etc/asterisk/pjsip.conf --undefined

echo "Processing userlist"
[ -f /userlist.yaml ] || exit 1
jinjanate /etc/asterisk/users/users.txt.j2 /userlist.yaml -o /etc/asterisk/users/users.txt --undefined  --format-option sequence-name=userlist


chmod 755 \
    /etc/asterisk/users/users.sh \
    /etc/asterisk/msg_send_offline.sh

exec asterisk "$@"

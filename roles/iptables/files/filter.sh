#!/bin/bash

IPS=$(which ipset)
IPT=$(which iptables)
IPT6=$(which ip6tables)

sysctl -w net.ipv4.ip_forward=1
# sysctl -w net.ipv6.conf.all.forwarding=1

######## IPV4 ##############

$IPT -t filter -F
$IPT -t nat -F
$IPT -t mangle -F

$IPS -quiet destroy mynetgroup1
$IPS create mynetgroup1 hash:net -exist
$IPS add mynetgroup1 192.168.0.0/24

$IPS -quiet destroy privatenets
$IPS create privatenets hash:net -exist
$IPS add privatenets 10.0.0.0/8
$IPS add privatenets 172.16.0.0/12
$IPS add privatenets 192.168.0.0/16

$IPS -quiet destroy allowed_ports_tcp
$IPS create allowed_ports_tcp bitmap:port range 1-65535 -exist

$IPS -quiet destroy allowed_ports_udp
$IPS create allowed_ports_udp bitmap:port range 1-65535 -exist

$IPS add allowed_ports_tcp 22   # ssh
$IPS add allowed_ports_tcp 80   # http
$IPS add allowed_ports_tcp 443  # https

# $IPS add allowed_ports_udp 500  # ipsec
# $IPS add allowed_ports_udp 4500 # ipsec
# $IPS add allowed_ports_udp 5060 # asterisk
# $IPS add allowed_ports_udp 10000-20000 # asterisk rtp


# default policy
$IPT -t filter -P INPUT ACCEPT
$IPT -t filter -P OUTPUT ACCEPT
$IPT -t filter -P FORWARD ACCEPT

$IPT -t filter -A OUTPUT -j ACCEPT

$IPT -t filter -A INPUT \
    -i lo \
    -j ACCEPT


$IPT -t filter -A INPUT \
    -m state --state ESTABLISHED \
    -j ACCEPT

$IPT -t filter -A INPUT \
    -m state --state RELATED \
    -j ACCEPT

$IPT -t filter -A INPUT \
    -m state --state INVALID \
    -j DROP

$IPT -t filter -A INPUT \
    -m set --match-set privatenets src \
    -j ACCEPT

$IPT -t filter -A INPUT \
    -p tcp \
    -m set --match-set allowed_ports_tcp dst \
    -j ACCEPT

$IPT -t filter -A INPUT \
    -p udp \
    -m set --match-set allowed_ports_udp dst \
    -j ACCEPT

$IPT -t filter -A INPUT \
    -p icmp \
    -j ACCEPT

$IPT -t filter -A INPUT \
    -j DROP


$IPT -t filter -A FORWARD \
    -m state --state ESTABLISHED \
    -j ACCEPT

$IPT -t filter -A FORWARD \
    -m state --state RELATED \
    -j ACCEPT

$IPT -t filter -A FORWARD \
    -m state --state INVALID \
    -j DROP

$IPT -t filter -A FORWARD \
    -m set --match-set privatenets src \
    -j ACCEPT
# $IPT -t filter -A FORWARD \
#     -m set --match-set mynetgroup1 src \
#     -j ACCEPT

$IPT -t filter -A FORWARD \
    -j DROP


$IPT -t nat -A POSTROUTING \
    -m set --match-set privatenets src \
    -m set ! --match-set privatenets dst \
    -j MASQUERADE
# $IPT -t nat -A POSTROUTING \
#     -m set --match-set mynetgroup1 src \
#     -m set ! --match-set mynetgroup1 dst \
#     -j MASQUERADE


######## IPV6 ##############

$IPT6 -t filter -F
$IPT6 -t nat -F
$IPT6 -t mangle -F

# default6 policy
$IPT6 -t filter -P INPUT DROP
$IPT6 -t filter -P OUTPUT DROP
$IPT6 -t filter -P FORWARD DROP

#
#$IPS -quiet destroy my6net
#$IPS create my6net hash:net family inet6 -exist
#$IPS add my6net 2001:70::/64
#
#$IPS -quiet destroy extips6
#$IPS create extips6 hash:ip family inet6 -exist
#$IPS add extips6 $myip6
#
## default6 policy
#$IPT6 -t filter -P INPUT ACCEPT
#$IPT6 -t filter -P OUTPUT ACCEPT
#$IPT6 -t filter -P FORWARD ACCEPT
#
##  tcpdump -s 0 -n -i nflog:6
#$IPT6 -t filter -I INPUT -m addrtype --dst-type LOCAL -m policy --pol ipsec --dir in -j NFLOG --nflog-group 6   --protocol icmpv6
#$IPT6 -t filter -I FORWARD -m addrtype ! --dst-type LOCAL -m policy --pol ipsec --dir in -j NFLOG --nflog-group 6   --protocol icmpv6
#$IPT6 -t filter -I OUTPUT -m policy --pol ipsec --dir out -j NFLOG --nflog-group 6   --protocol icmpv6
#
#$IPT6 -t filter -A FORWARD -m set --match-set my6net src -j ACCEPT
#
#$IPT6 -t filter -A FORWARD -m set --match-set my6net dst -m state --state ESTABLISHED  -j ACCEPT
#$IPT6 -t filter -A FORWARD -m set --match-set my6net dst -m state --state RELATED  -j ACCEPT
#$IPT6 -t filter -A FORWARD -m set --match-set my6net dst -m state --state INVALID  -j DROP
#$IPT6 -t filter -A FORWARD -m set --match-set my6net dst -p icmpv6  -j ACCEPT
#$IPT6 -t filter -A FORWARD -m set --match-set my6net dst  -j DROP

conntrack -F

#!/bin/sh
#vim:ft=sh

set -e -o pipefail

function get_ip_flag() {

    num_colons="$(grep -o : <(echo -n $1) | wc -l)"

    if [ $num_colons -gt 1 ]; then
        echo -n '-6'
    else
        echo -n '-4'
    fi

}

function run() {
    echo "+ $*"
    $@
}

iface=$1

# load the config into variables, this won't work if we have more than one peer
source <(cat /etc/wireguard/$iface.conf | sed '/^\[/d')

run wireguard-go -f $iface &
pid=$!

sleep 0.05 # keeps the warning message after the log line

run wg setconf $iface <(wg-quick strip /etc/wireguard/$iface.conf)
run ip addr add "$Address" dev "$iface"
run ip link set $iface up

endpoint="$(wg showconf $iface | grep Endpoint | tr -d ' ' | cut -d '=' -f2 | cut -d ':' -f1)"
default_iface="$(ip -j route show to 0.0.0.0/0 | jq -r '.[].dev')"
default_gateway="$(ip -j route show to 0.0.0.0/0 | jq -r '.[].gateway')"

run ip route add to $endpoint dev $default_iface via $default_gateway
run ip route change default dev $iface
run ip route get 1.1.1.1

run curl ifconfig.me 2>/dev/null; echo
run wg
run curl ifconfig.me 2>/dev/null; echo

trap "kill $pid; exit" INT TERM EXIT

wait $pid

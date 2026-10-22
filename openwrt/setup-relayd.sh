#!/bin/sh
# Configure relayd (proxy-ARP) for the HaLow interface when a hard
# Layer-2 bridge is not possible.

HALOW_IF=wlan0
UPSTREAM_IF=br-lan

if ! command -v relayd >/dev/null 2>&1; then
    opkg update
    opkg install relayd luci-app-relayd 2>&1
    if ! command -v relayd >/dev/null 2>&1; then
        echo "relayd installation failed.  Check opkg output."
        exit 4
    fi
fi

uci set relayd.@relayd[0]=relayd
uci set relayd.@relayd[0].enabled='1'
uci set relayd.@relayd[0].local_ipaddr='192.168.4.1'
uci set relayd.@relayd[0].mode='relay'

uci add_list relayd.@relayd[0].network="$HALOW_IF"
uci add_list relayd.@relayd[0].network="$UPSTREAM_IF"

uci commit relayd
/etc/init.d/relayd enable
/etc/init.d/relayd start

echo "relayd configured for $HALOW_IF and $UPSTREAM_IF."
echo "Ensure the HaLow interface does NOT run DHCP; relayd forwards it."
exit 0

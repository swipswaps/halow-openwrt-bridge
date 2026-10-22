#!/bin/sh
# Configure relayd via a proto=relay interface (modern OpenWrt schema).
# relayd reads ipaddr and the network list from the interface section;
# there is no relayd.@relayd[0].local_ipaddr option.
# Exit codes: 0 success, 4 relayd install failed.

HALOW_IF=wlan0
UPSTREAM_IF=br-lan
RELAY_IF=repeater_bridge

if ! command -v relayd >/dev/null 2>&1; then
    opkg update
    opkg install relayd 2>&1
    if ! command -v relayd >/dev/null 2>&1; then
        echo "relayd installation failed."
        exit 4
    fi
fi

uci set network."$RELAY_IF"=interface
uci set network."$RELAY_IF".proto='relay'
uci set network."$RELAY_IF".ipaddr='192.168.4.1'
uci set network."$RELAY_IF".network="$UPSTREAM_IF $HALOW_IF"

uci commit network
/etc/init.d/relayd enable
/etc/init.d/relayd start

echo "relay interface $RELAY_IF relays $UPSTREAM_IF <-> $HALOW_IF."
echo "Do not run DHCP on $HALOW_IF; relayd forwards it."
exit 0

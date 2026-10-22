#!/bin/sh
# Configure relayd via a proto=relay interface.
# relayd validates network as list(string) and reads it with config_get;
# the option must therefore be a UCI list, not a space-separated string.
# The relay interface is not instantiated until netifd processes the
# configuration, so network reload must run before relayd starts.
# Exit codes: 0 success, 4 relayd install failed.

HALOW_IF=wlan0
UPSTREAM_IF=br-lan
RELAY_IF=repeater_bridge

# --- install relayd with whichever package manager exists -----------------
if ! command -v relayd >/dev/null 2>&1; then
    if command -v opkg >/dev/null 2>&1; then
        opkg update
        opkg install relayd
    elif command -v apk >/dev/null 2>&1; then
        apk update
        apk add relayd
    else
        echo "no package manager found (neither opkg nor apk)."
        exit 4
    fi
    if ! command -v relayd >/dev/null 2>&1; then
        echo "relayd installation failed."
        exit 4
    fi
fi

# --- create the relay interface -------------------------------------------
uci set "network.$RELAY_IF=interface"
uci set "network.$RELAY_IF.proto=relay"
uci set "network.$RELAY_IF.ipaddr=192.168.4.1"

# uci set replaces the list with a single element; add_list appends.
# This is idempotent across re-runs: the list ends as [UPSTREAM, HALOW].
uci set "network.$RELAY_IF.network=$UPSTREAM_IF"
uci add_list "network.$RELAY_IF.network=$HALOW_IF"

uci commit network

# netifd must instantiate the relay interface before relayd can attach.
/etc/init.d/network reload

/etc/init.d/relayd enable
/etc/init.d/relayd start

echo "relay interface $RELAY_IF relays $UPSTREAM_IF <-> $HALOW_IF."
echo "Do not run DHCP on $HALOW_IF; relayd forwards it."
exit 0

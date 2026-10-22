#!/bin/sh
# Stop HaLow AP and remove the UCI bridge port using uci del_list.

HALOW_IF=wlan0

CURRENT_PORTS=$(uci get network.@device[-1].ports 2>&1)
case "$CURRENT_PORTS" in
    *"$HALOW_IF"*)
        uci del_list network.@device[-1].ports="$HALOW_IF"
        uci commit network
        /etc/init.d/network reload
        echo "$HALOW_IF removed from bridge ports."
        ;;
    *)
        echo "$HALOW_IF not in bridge ports; nothing to remove."
        ;;
esac

if pidof hostapd_s1g >/dev/null 2>&1; then
    killall -q hostapd_s1g
    echo "hostapd_s1g stopped."
fi

ip link set "$HALOW_IF" down
echo "HaLow interface down."
exit 0

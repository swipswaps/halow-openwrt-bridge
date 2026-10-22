#!/bin/sh
# Stop HaLow AP.  Uses ip/brctl, not /sys/class/net.

HALOW_IF=wlan0
BRIDGE=br-lan

if ip link show "$BRIDGE" >/dev/null 2>&1; then
    if brctl show "$BRIDGE" 2>&1 | grep -q "$HALOW_IF"; then
        brctl delif "$BRIDGE" "$HALOW_IF"
        echo "$HALOW_IF removed from $BRIDGE via brctl."
    fi
    CURRENT_PORTS=$(uci get network.@device[-1].ports 2>&1)
    case "$CURRENT_PORTS" in
        *"$HALOW_IF"*)
            uci del_list network.@device[-1].ports="$HALOW_IF"
            uci commit network
            /etc/init.d/network reload
            echo "$HALOW_IF removed from UCI bridge ports."
            ;;
    esac
fi

if pidof hostapd_s1g >/dev/null 2>&1; then
    killall -q hostapd_s1g
    echo "hostapd_s1g stopped."
fi

ip link set "$HALOW_IF" down
echo "HaLow interface down."
exit 0

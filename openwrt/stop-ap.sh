#!/bin/sh
# Stop HaLow AP, remove UCI bridge port, bring link down.

HALOW_IF=wlan0
BRIDGE=br-lan

# --- remove from UCI bridge ports -----------------------------------------
CURRENT_PORTS=$(uci get network.@device[-1].ports 2>&1)
NEW_PORTS=""
for port in $CURRENT_PORTS; do
    if [ "$port" != "$HALOW_IF" ]; then
        NEW_PORTS="$NEW_PORTS $port"
    fi
done
if [ "$NEW_PORTS" != "$CURRENT_PORTS" ]; then
    uci set network.@device[-1].ports="$NEW_PORTS"
    uci commit network
    /etc/init.d/network reload
    echo "$HALOW_IF removed from $BRIDGE."
fi

# --- stop hostapd_s1g quietly --------------------------------------------
if pidof hostapd_s1g >/dev/null 2>&1; then
    killall -q hostapd_s1g
    echo "hostapd_s1g stopped."
fi

ip link set "$HALOW_IF" down
echo "HaLow interface down."

#!/bin/sh
# Stop HaLow AP cleanly.

HALOW_IF=wlan0
BRIDGE=br-lan

if ip link show "$BRIDGE" >/dev/null 2>&1; then
    brctl delif "$BRIDGE" "$HALOW_IF" 2>&1
    for port in $(uci get network.@device[-1].ports 2>&1); do
        if [ "$port" = "$HALOW_IF" ]; then
            uci del_list network.@device[-1].ports="$HALOW_IF"
            uci commit network
            /etc/init.d/network reload
            break
        fi
    done
fi

for pid in $(pidof hostapd_s1g); do
    kill "$pid" 2>&1
done
sleep 1
sync
ip link set "$HALOW_IF" down 2>&1
echo "HaLow stopped."
exit 0

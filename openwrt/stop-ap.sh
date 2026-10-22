#!/bin/sh
# Stop HaLow AP.  ip link nomaster works without bridge-utils.

HALOW_IF=wlan0
BRIDGE=br-lan

ip link set dev "$HALOW_IF" nomaster 2>&1

if command -v brctl >/dev/null 2>&1; then
    if brctl show "$BRIDGE" 2>&1 | grep -q "$HALOW_IF"; then
        brctl delif "$BRIDGE" "$HALOW_IF" 2>&1
    fi
fi

BRIDGE_SECTION=""
for section in $(uci show network 2>&1 | awk -F. '/=device$/ {print $2}'); do
    NAME=$(uci get "network.$section.name" 2>&1)
    [ "$NAME" = "$BRIDGE" ] && BRIDGE_SECTION="$section"
done

if [ -n "$BRIDGE_SECTION" ]; then
    for port in $(uci get "network.$BRIDGE_SECTION.ports" 2>&1); do
        if [ "$port" = "$HALOW_IF" ]; then
            uci del_list "network.$BRIDGE_SECTION.ports=$HALOW_IF"
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
ip link set "$HALOW_IF" down 2>&1
echo "HaLow stopped."
exit 0

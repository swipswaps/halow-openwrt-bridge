#!/bin/sh
# Add the HaLow netdev to the firewall zone whose name is lan.

HALOW_IF=wlan0
ZONE_SECTION=""

for section in $(uci show firewall 2>&1 | awk -F. '/=zone$/ {print $2}'); do
    NAME=$(uci get "firewall.$section.name" 2>&1)
    [ "$NAME" = "lan" ] && ZONE_SECTION="$section"
done

if [ -z "$ZONE_SECTION" ]; then
    echo "No firewall zone named lan."
    exit 2
fi

FOUND=0
for net in $(uci get "firewall.$ZONE_SECTION.network" 2>&1); do
    [ "$net" = "$HALOW_IF" ] && FOUND=1
done

if [ "$FOUND" -eq 1 ]; then
    echo "$HALOW_IF already in zone lan."
    exit 0
fi

uci add_list "firewall.$ZONE_SECTION.network=$HALOW_IF"
uci commit firewall
/etc/init.d/firewall reload
echo "$HALOW_IF added to zone lan."
exit 0

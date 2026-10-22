#!/bin/sh
# Add the HaLow netdev to the LAN firewall zone, token-wise deduplicated.

HALOW_IF=wlan0
ZONE_INDEX=0

ZONE_NAME=$(uci get firewall.@zone["$ZONE_INDEX"].name 2>&1)
if [ "$ZONE_NAME" != "lan" ]; then
    echo "zone 0 is not lan (got $ZONE_NAME)."
    exit 2
fi

FOUND=0
for net in $(uci get firewall.@zone["$ZONE_INDEX"].network 2>&1); do
    if [ "$net" = "$HALOW_IF" ]; then
        FOUND=1
    fi
done

if [ "$FOUND" -eq 1 ]; then
    echo "$HALOW_IF already in firewall zone lan."
    exit 0
fi

uci add_list firewall.@zone["$ZONE_INDEX"].network="$HALOW_IF"
uci commit firewall
/etc/init.d/firewall reload
echo "$HALOW_IF added to firewall zone lan."
exit 0

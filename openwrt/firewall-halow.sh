#!/bin/sh
# Add the HaLow netdev to the LAN firewall zone using uci add_list.
# Does NOT overwrite the existing zone network list.

HALOW_IF=wlan0
ZONE_INDEX=0

ZONE_NAME=$(uci get firewall.@zone["$ZONE_INDEX"].name 2>&1)
if [ "$ZONE_NAME" != "lan" ]; then
    echo "zone 0 is not lan (got $ZONE_NAME).  Edit ZONE_INDEX."
    exit 2
fi

CURRENT=$(uci get firewall.@zone["$ZONE_INDEX"].network 2>&1)
case "$CURRENT" in
    *"$HALOW_IF"*)
        echo "$HALOW_IF already in firewall zone lan."
        exit 0
        ;;
esac

uci add_list firewall.@zone["$ZONE_INDEX"].network="$HALOW_IF"
uci commit firewall
/etc/init.d/firewall reload
echo "$HALOW_IF added to firewall zone lan via uci add_list."
exit 0

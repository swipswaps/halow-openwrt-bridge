#!/bin/sh
# Explicitly disable DHCP on the HaLow interface.
# Iterates over all dhcp sections and sets ignore=1 where interface matches.

HALOW_IF=wlan0

for section in $(uci show dhcp 2>&1 | grep -oE 'dhcp\.@dhcp\[[0-9]+\]'); do
    IFACE=$(uci get "$section.interface" 2>&1)
    if [ "$IFACE" = "$HALOW_IF" ]; then
        uci set "$section.ignore='1'"
        uci commit dhcp
        echo "DHCP disabled on $HALOW_IF (section $section)."
        /etc/init.d/dnsmasq restart
        exit 0
    fi
done

echo "No DHCP section found for $HALOW_IF.  It is already safe."

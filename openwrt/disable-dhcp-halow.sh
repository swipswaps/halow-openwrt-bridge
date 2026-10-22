#!/bin/sh
# Disable DHCP on the HaLow interface, idempotently.

HALOW_IF=wlan0
CHANGED=0

for section in $(uci show dhcp 2>&1 | awk -F. '/=dhcp$/ {print $2}'); do
    IFACE=$(uci get "dhcp.$section.interface" 2>&1)
    if [ "$IFACE" = "$HALOW_IF" ]; then
        IGNORED=$(uci get "dhcp.$section.ignore" 2>&1)
        if [ "$IGNORED" = "1" ]; then
            echo "DHCP already ignored on $HALOW_IF (section $section)."
        else
            uci set "dhcp.$section.ignore='1'"
            uci commit dhcp
            echo "DHCP disabled on $HALOW_IF (section $section)."
            CHANGED=1
        fi
    fi
done

if [ "$CHANGED" -eq 1 ]; then
    if [ -x /etc/init.d/dnsmasq ]; then
        /etc/init.d/dnsmasq restart
    else
        echo "dnsmasq init script not found; skipping restart."
    fi
fi
exit 0

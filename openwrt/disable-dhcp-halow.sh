#!/bin/sh
# Explicitly disable DHCP on the HaLow interface.

HALOW_IF=wlan0
FOUND=0

for section in $(uci show dhcp 2>&1 | awk -F. '/=dhcp$/ {print $2}'); do
    IFACE=$(uci get "dhcp.$section.interface" 2>&1)
    if [ "$IFACE" = "$HALOW_IF" ]; then
        uci set "dhcp.$section.ignore='1'"
        uci commit dhcp
        echo "DHCP disabled on $HALOW_IF (section $section)."
        FOUND=1
    fi
done

if [ "$FOUND" -eq 0 ]; then
    echo "No DHCP section found for $HALOW_IF.  It is already safe."
    exit 0
fi

/etc/init.d/dnsmasq restart
exit 0

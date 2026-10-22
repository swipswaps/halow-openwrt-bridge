#!/bin/sh
# CDC-NCM detection.  Android names CDC-NCM interfaces usbX when the
# locally-administered bit (bit 1 of the first octet) is set, and the
# Ethernet service regex only matches ethX.  This is why tethering
# silently fails.

echo "=== USB devices ==="
lsusb 2>&1

echo "=== Interfaces ==="
ip -br link 2>&1

echo "=== CDC-NCM kernel messages ==="
dmesg 2>&1 | grep -i -E 'cdc_ncm|cdc_ether|rndis|usb.*eth' | tail -n 30

echo "=== MAC bit audit ==="
echo "Android Ethernet service matches ethX, not usbX."
echo "Kernel names a CDC-NCM interface usbX when bit 1 of the first"
echo "octet is set (locally administered).  Clearing it yields ethX."
for iface in $(ip -br link 2>&1 | awk '{print $1}'); do
    MAC=$(ip link show "$iface" 2>&1 | grep -oE 'link/ether [0-9a-f:]+' | awk '{print $2}')
    if [ -n "$MAC" ]; then
        FIRST=$(echo "$MAC" | cut -d: -f1)
        LOCAL_BIT=$(( (0x$FIRST & 0x02) >> 1 ))
        if [ "$LOCAL_BIT" -eq 1 ]; then
            printf "%s  MAC=%s  LOCAL_BIT=1  -> usbX naming, tethering OFF\n" "$iface" "$MAC"
        else
            printf "%s  MAC=%s  LOCAL_BIT=0  -> ethX naming, tethering ON\n" "$iface" "$MAC"
        fi
    fi
done

echo "=== Android Ethernet service ==="
dumpsys ethernet 2>&1 | head -n 40
settings get global ethernet_on 2>&1
settings get global tether_enable 2>&1

echo "=== Done ==="

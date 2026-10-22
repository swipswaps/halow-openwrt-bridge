#!/bin/sh
# CDC-NCM detection.  Android does NOT enable Ethernet tethering when
# the CDC-NCM MAC has the locally-administered bit set (bit 1 of first byte).

echo "=== USB devices ==="
lsusb 2>&1

echo "=== Interfaces ==="
ip -br link 2>&1

echo "=== CDC-NCM kernel messages ==="
dmesg 2>&1 | grep -i -E 'cdc_ncm|cdc_ether|rndis|usb.*eth' | tail -n 30

echo "=== MAC bit audit (local bit = tethering disabled) ==="
for iface in $(ip -br link 2>&1 | awk '{print $1}'); do
    MAC=$(ip link show "$iface" 2>&1 | grep -oE 'link/ether [0-9a-f:]+' | awk '{print $2}')
    if [ -n "$MAC" ]; then
        FIRST_OCTET=$(echo "$MAC" | cut -d: -f1)
        LOCAL_BIT=$(( (0x$FIRST_OCTET & 0x02) >> 1 ))
        if [ "$LOCAL_BIT" -eq 1 ]; then
            printf "%s  MAC=%s  LOCAL_BIT=1  WARNING: Android tethering will NOT enable\n" "$iface" "$MAC"
        else
            printf "%s  MAC=%s  LOCAL_BIT=0  globally administered (tethering OK)\n" "$iface" "$MAC"
        fi
    fi
done

echo "=== Android Ethernet service ==="
dumpsys ethernet 2>&1 | head -n 40
settings get global ethernet_on 2>&1
settings get global tether_enable 2>&1

echo "=== Routes ==="
ip route 2>&1
echo "=== Done ==="

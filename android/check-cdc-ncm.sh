#!/bin/sh
# CDC-NCM detection and Android Ethernet service check.
# Run as root (adb shell su or Termux with root).

echo "=== USB devices ==="
lsusb 2>&1

echo "=== Interfaces (note usbX vs ethX naming) ==="
ip -br link 2>&1

echo "=== CDC-NCM kernel messages ==="
dmesg 2>&1 | grep -i -E 'cdc_ncm|cdc_ether|rndis|usb.*eth' | tail -n 30

echo "=== Android Ethernet service state ==="
dumpsys ethernet 2>&1 | head -n 40
settings get global ethernet_on 2>&1
settings get global tether_enable 2>&1

echo "=== Interface MAC addresses (check locally-administered bit) ==="
for iface in $(ip -br link 2>&1 | awk '{print $1}'); do
    MAC=$(ip link show "$iface" 2>&1 | grep -oE 'link/ether [0-9a-f:]+' | awk '{print $2}')
    if [ -n "$MAC" ]; then
        FIRST=$(echo "$MAC" | cut -d: -f1)
        printf "%s  MAC=%s  first_octet=%s\n" "$iface" "$MAC" "$FIRST"
    fi
done

echo "=== Addresses and routes ==="
ip addr show 2>&1
ip route 2>&1

echo "=== Done ==="

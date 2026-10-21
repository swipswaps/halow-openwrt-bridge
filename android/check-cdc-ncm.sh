#!/bin/sh
# CDC-NCM detection.  Run as root (adb shell su or Termux with root).

echo "=== USB devices ==="
lsusb 2>&1

echo "=== Interfaces ==="
ip -br link 2>&1

echo "=== CDC-NCM kernel messages ==="
dmesg 2>&1 | grep -i -E 'cdc_ncm|cdc_ether|rndis|usb.*eth' | tail -n 30

echo "=== Addresses and routes ==="
ip addr show 2>&1
ip route 2>&1

echo "=== Done ==="

#!/bin/sh
# CDC-NCM diagnosis.
# On many Android releases, notably before Android 14 (U), the Ethernet
# tethering config matches ethX only, and the kernel names a CDC-NCM
# interface usbX when bit 1 of the first MAC octet is set (locally
# administered).  Android 14 changed the regex to include usbX, then
# reverted it and re-landed it for Android 15 (V); vendor forks vary.

echo "=== Interfaces ==="
ip -br link 2>&1

echo "=== MAC bit audit ==="
for iface in $(ip -br link 2>&1 | awk '{print $1}'); do
    MAC=$(ip link show "$iface" 2>&1 | grep -oE 'link/ether [0-9a-f:]+' | awk '{print $2}')
    [ -z "$MAC" ] && continue
    FIRST=$(echo "$MAC" | cut -d: -f1)
    LOCAL=$(( (0x$FIRST & 0x02) >> 1 ))
    if [ "$LOCAL" -eq 1 ]; then
        printf "%s  %s  LOCAL_BIT=1  likely usbX; tethering may be OFF\n" "$iface" "$MAC"
        printf "  REMEDIATION: ./set-global-mac.sh %s\n" "$iface"
    else
        printf "%s  %s  LOCAL_BIT=0  likely ethX; tethering should be ON\n" "$iface" "$MAC"
    fi
done

echo "=== Android Ethernet service ==="
dumpsys ethernet 2>&1 | head -n 30
echo "tether_enable=$(settings get global tether_enable 2>&1)"

echo "=== Naming summary ==="
if ip -br link 2>&1 | awk '{print $1}' | grep -q '^eth'; then
    echo "ethX present; Android Ethernet service should recognise it."
else
    echo "No ethX.  If usbX exists and tethering is off, run set-global-mac.sh."
fi

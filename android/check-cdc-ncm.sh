#!/bin/sh
# CDC-NCM diagnosis.
# usbnet_probe() names cdc_ncm interfaces usbN; Android's default
# config_ethernet_iface_regex matches ethN, so tethering does not
# enable on usbN.  The fix is a rename, not a MAC change.

echo "=== Interfaces ==="
ip -br link 2>&1

echo "=== MAC bit audit ==="
for iface in $(ip -br link 2>&1 | awk '{print $1}'); do
    MAC=$(ip link show "$iface" 2>&1 | grep -oE 'link/ether [0-9a-f:]+' | awk '{print $2}')
    [ -z "$MAC" ] && continue
    FIRST=$(echo "$MAC" | cut -d: -f1)
    LOCAL=$(( (0x$FIRST & 0x02) >> 1 ))
    printf "%s  %s  local_bit=%s\n" "$iface" "$MAC" "$LOCAL"
done

echo "=== Android Ethernet service ==="
dumpsys ethernet 2>&1 | head -n 30
echo "tether_enable=$(settings get global tether_enable 2>&1)"

echo "=== Naming summary ==="
if ip -br link 2>&1 | awk '{print $1}' | grep -q '^eth'; then
    echo "ethN present; Android Ethernet service should recognise it."
else
    echo "No ethN."
    for iface in $(ip -br link 2>&1 | awk '{print $1}'); do
        case "$iface" in
            usb*)
                echo "  usbN detected ($iface).  Run:"
                echo "    ./set-global-mac.sh $iface"
                ;;
        esac
    done
fi

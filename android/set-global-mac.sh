#!/bin/sh
# Rename a CDC-NCM interface so Android's Ethernet service picks it up.
# Historical filename (set-global-mac) kept for compatibility.
#
# Why: Linux usbnet_probe() names cdc_ncm, cdc_ether, and rndis_host
# interfaces "usb%d" (drivers/net/usb/usbnet.c).  Android's
# config_ethernet_iface_regex historically matches eth\d only, so a
# usb%d interface is ignored by the Ethernet service and tethering
# does not enable.  The MAC bit does NOT rename the interface; the
# fix is an explicit rename.
#
# Some vendor Android forks additionally filter on the locally-
# administered MAC bit.  Clearing it is done here as well, but the
# rename is what makes Android's Ethernet service recognise the
# interface on stock AOSP.
#
# Usage: ./set-global-mac.sh usb0 [eth0]
# Requires root (CAP_NET_ADMIN).  Not persistent across replug.

IFACE="$1"
TARGET="${2:-eth0}"

if [ -z "$IFACE" ]; then
    echo "usage: $0 <usbN> [ethN]"
    exit 2
fi

if [ "$(id -u)" -ne 0 ]; then
    echo "this script requires root; re-run with su or sudo."
    exit 3
fi

case "$IFACE" in
    usb*) : ;;
    *) echo "expected usbN; got $IFACE"; exit 2 ;;
esac

if ip link show "$TARGET" >/dev/null 2>&1; then
    echo "$TARGET already exists; refusing to clobber it."
    exit 3
fi

MAC=$(ip link show "$IFACE" 2>&1 | grep -oE 'link/ether [0-9a-f:]+' | awk '{print $2}')
if [ -z "$MAC" ]; then
    echo "no MAC found for $IFACE."
    exit 3
fi

FIRST=$(echo "$MAC" | cut -d: -f1)
LOCAL_BIT=$(( (0x$FIRST & 0x02) >> 1 ))

ip link set "$IFACE" down

if [ "$LOCAL_BIT" -eq 1 ]; then
    NEW_FIRST=$(printf '%02x' $(( 0x$FIRST & ~0x02 )))
    REST=$(echo "$MAC" | cut -d: -f2-)
    NEW_MAC="$NEW_FIRST:$REST"
    ip link set "$IFACE" address "$NEW_MAC"
    echo "cleared locally administered bit: $MAC -> $NEW_MAC"
fi

if ! ip link set "$IFACE" name "$TARGET"; then
    echo "rename failed (interface busy or name in use); bringing $IFACE up."
    ip link set "$IFACE" up
    exit 3
fi

ip link set "$TARGET" up
echo "renamed $IFACE -> $TARGET; Android Ethernet service should now match"
echo "config_ethernet_iface_regex (ethN)."
echo "This change is lost on replug.  Add a udev rule for persistence."
exit 0

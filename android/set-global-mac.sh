#!/bin/sh
# Make a CDC-NCM interface appear as ethN on Android.
#
# Primary mechanism: the kernel names a cdc_ncm interface eth%d when the
# globally unique bit is clear.  drivers/net/usb/cdc_ncm.c:
#   if ((dev->driver_info->flags & FLAG_ETHER) != 0 &&
#       ((dev->driver_info->flags & FLAG_POINTTOPOINT) == 0 ||
#        (net->dev_addr[0] & 0x02) == 0))
#           strcpy(net->name, "eth%d");
# Bit 1 of the first octet is the locally administered bit.  Clearing it
# makes the MAC globally unique, and the kernel assigns ethN at probe time.
#
# Fallback: if the interface already probed as usbN, rename it with
#   ip link set dev usb0 name eth0
# This is what the rest of this script does when clearing the bit does
# not produce an ethN name (e.g. the interface was already up).
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
    echo "the kernel would assign ethN at next probe if the link were down."
fi

# Even after clearing the bit, an already-probed usbN keeps its name.
# Rename explicitly as the deterministic step.
if ! ip link set "$IFACE" name "$TARGET"; then
    echo "rename failed (interface busy or name in use); bringing $IFACE up."
    ip link set "$IFACE" up
    exit 3
fi

ip link set "$TARGET" up
echo "renamed $IFACE -> $TARGET."
echo "Android EthernetTracker matches this name on eth\\d builds; on"
echo "Android U+ the default regex also accepts usb\\d, so a rename may"
echo "be unnecessary there.  See README section 10."
echo "Not persistent across replug.  Add a udev rule for persistence."
exit 0

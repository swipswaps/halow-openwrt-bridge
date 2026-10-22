#!/bin/sh
# Clear the locally-administered bit on a CDC-NCM interface so Android
# names it ethX and enables Ethernet tethering.
# Usage: ./set-global-mac.sh usb0
# Requires root.  Not persistent across replug.

IFACE="$1"
if [ -z "$IFACE" ]; then
    echo "usage: $0 <interface>"
    exit 2
fi

MAC=$(ip link show "$IFACE" 2>&1 | grep -oE 'link/ether [0-9a-f:]+' | awk '{print $2}')
if [ -z "$MAC" ]; then
    echo "no MAC found for $IFACE."
    exit 3
fi

FIRST=$(echo "$MAC" | cut -d: -f1)
LOCAL_BIT=$(( (0x$FIRST & 0x02) >> 1 ))
if [ "$LOCAL_BIT" -eq 0 ]; then
    echo "$IFACE already has a globally administered MAC ($MAC)."
    exit 0
fi

# Clear bit 1 of the first octet: 0x02 -> 0x00.
NEW_FIRST=$(printf '%02x' $(( 0x$FIRST & ~0x02 )))
REST=$(echo "$MAC" | cut -d: -f2-)
NEW_MAC="$NEW_FIRST:$REST"

ip link set "$IFACE" down
ip link set "$IFACE" address "$NEW_MAC"
ip link set "$IFACE" up

echo "MAC changed from $MAC to $NEW_MAC on $IFACE."
echo "Android should now name the interface ethX and enable tethering."
echo "This change is lost on replug.  Add a udev rule for persistence."
exit 0

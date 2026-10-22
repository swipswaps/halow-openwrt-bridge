#!/bin/sh
# Install the HaLow scripts on the target OpenWrt device.
# Run on the device as root, from the repository root.
# Exit codes: 0 success, 2 missing source files, 3 target not writable.

TARGET_DIR=/usr/share/halow
INIT=/etc/init.d/halow-ap

for f in openwrt/start-ap.sh openwrt/stop-ap.sh openwrt/hostapd_s1g.conf \
         openwrt/disable-uci-halow.sh openwrt/tune-morse.sh \
         openwrt/firewall-halow.sh openwrt/disable-dhcp-halow.sh \
         openwrt/setup-relayd.sh openwrt/halow-ap.init; do
    if [ ! -f "$f" ]; then
        echo "missing $f; run install.sh from the repository root."
        exit 2
    fi
done

mkdir -p "$TARGET_DIR" /var/run/hostapd || { echo "cannot create target dirs"; exit 3; }
cp openwrt/start-ap.sh openwrt/stop-ap.sh openwrt/hostapd_s1g.conf \
   openwrt/disable-uci-halow.sh openwrt/tune-morse.sh \
   openwrt/firewall-halow.sh openwrt/disable-dhcp-halow.sh \
   openwrt/setup-relayd.sh "$TARGET_DIR/" || { echo "copy failed"; exit 3; }
chmod +x "$TARGET_DIR"/*.sh

cp openwrt/halow-ap.init "$INIT" || { echo "cannot write $INIT"; exit 3; }
chmod +x "$INIT"

"$INIT" enable
echo "installed and enabled $INIT"
echo "next steps on this device:"
echo "  1. HALOW_RADIO=radioN $TARGET_DIR/disable-uci-halow.sh"
echo "     (pick radioN from the list the script prints if unset)"
echo "  2. edit $TARGET_DIR/hostapd_s1g.conf for country_code, channel, op_class"
echo "  3. /etc/init.d/halow-ap start"
echo ""
echo "optional: copy openwrt/uci-defaults-halow to /etc/uci-defaults/99-halow"
echo "  and reboot to seed the br-lan port and lan firewall zone at first boot."
echo "  uci-defaults-halow does NOT disable any radioN."
exit 0

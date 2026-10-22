#!/bin/sh
# Install the HaLow scripts on the target OpenWrt device.
# Run on the device as root, from the repository root.
# Exit codes: 0 success, 2 preconditions missing, 3 target not writable.

TARGET_DIR=/usr/share/halow
INIT=/etc/init.d/halow-ap

for f in /etc/rc.common /etc/config/network /etc/config/firewall; do
    if [ ! -e "$f" ]; then
        echo "$f missing; this does not look like an OpenWrt target."
        exit 2
    fi
done

for tool in uci iw hostapd_s1g; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "$tool missing; install it first (opkg install $tool)."
        exit 2
    fi
done

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
chmod 750 /var/run/hostapd
cp openwrt/start-ap.sh openwrt/stop-ap.sh openwrt/hostapd_s1g.conf \
   openwrt/disable-uci-halow.sh openwrt/tune-morse.sh \
   openwrt/firewall-halow.sh openwrt/disable-dhcp-halow.sh \
   openwrt/setup-relayd.sh "$TARGET_DIR/" || { echo "copy failed"; exit 3; }
chmod +x "$TARGET_DIR"/*.sh
chmod 600 "$TARGET_DIR/hostapd_s1g.conf"

cp openwrt/halow-ap.init "$INIT" || { echo "cannot write $INIT"; exit 3; }
chmod +x "$INIT"

"$INIT" enable
echo "installed and enabled $INIT"
echo "next steps on this device:"
echo "  1. edit $TARGET_DIR/hostapd_s1g.conf: set wpa_passphrase,"
echo "     country_code, channel, op_class (the placeholder PSK is rejected)"
echo "  2. HALOW_RADIO=radioN $TARGET_DIR/disable-uci-halow.sh"
echo "  3. /etc/init.d/halow-ap start"
echo ""
echo "optional: copy openwrt/uci-defaults-halow to /etc/uci-defaults/99-halow"
echo "  and reboot to seed the br-lan port and lan firewall zone."
exit 0

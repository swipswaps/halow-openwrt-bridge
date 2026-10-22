#!/bin/sh
# Install the HaLow scripts and init script on the target OpenWrt device.
# Run on the device as root, from the repository root.
# Copies start-ap.sh and stop-ap.sh to /usr/share/halow/, installs
# halow-ap.init as /etc/init.d/halow-ap, and enables the service.
# Exit codes: 0 success, 2 missing source files, 3 target not writable.

TARGET_DIR=/usr/share/halow
INIT=/etc/init.d/halow-ap

for f in openwrt/start-ap.sh openwrt/stop-ap.sh openwrt/halow-ap.init openwrt/hostapd_s1g.conf; do
    if [ ! -f "$f" ]; then
        echo "missing $f; run install.sh from the repository root."
        exit 2
    fi
done

mkdir -p "$TARGET_DIR" || { echo "cannot create $TARGET_DIR"; exit 3; }
cp openwrt/start-ap.sh openwrt/stop-ap.sh openwrt/hostapd_s1g.conf "$TARGET_DIR/"
chmod +x "$TARGET_DIR"/*.sh

cp openwrt/halow-ap.init "$INIT"
chmod +x "$INIT"

"$INIT" enable
echo "installed and enabled $INIT"
echo "run HALOW_RADIO=radioN ./openwrt/disable-uci-halow.sh on the device"
echo "then /etc/init.d/halow-ap start"
exit 0

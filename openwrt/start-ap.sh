#!/bin/sh
# Start HaLow AP.  WiFi interfaces do NOT appear in /sys/class/net in
# OpenWrt, so PHY and bridge discovery use iw and ip/brctl.
# Exit codes: 0 success, 2 no PHY, 3 bridge missing, 4 hostapd failed.

HALOW_IF=wlan0
BRIDGE=br-lan
CONF="$(dirname "$0")/hostapd_s1g.conf"
CTRL_SOCK=/var/run/hostapd

# --- PHY discovery via iw, not /sys/class/net -----------------------------
if ! iw dev "$HALOW_IF" info >/dev/null 2>&1; then
    PHY=$(iw dev 2>&1 | awk '/phy#/ {print $2; exit}')
    if [ -n "$PHY" ]; then
        iw phy "$PHY" interface add "$HALOW_IF" type managed
        echo "created $HALOW_IF on $PHY"
    else
        PHY=$(ls /sys/class/ieee80211/ 2>&1 | head -n 1)
        if [ -n "$PHY" ]; then
            iw phy "$PHY" interface add "$HALOW_IF" type managed
            echo "created $HALOW_IF on phy $PHY (sysfs fallback)"
        else
            echo "No ieee80211 phy found.  Is the morse driver loaded?"
            exit 2
        fi
    fi
fi

ip link set "$HALOW_IF" up

# --- hostapd launch and readiness check -----------------------------------
hostapd_s1g -B "$CONF"
HOSTAPD_RC=$?
if [ "$HOSTAPD_RC" -ne 0 ]; then
    echo "hostapd_s1g failed with exit code $HOSTAPD_RC."
    exit 4
fi

TRIES=0
while [ "$TRIES" -lt 10 ]; do
    if [ -S "$CTRL_SOCK/$HALOW_IF" ] || iw dev "$HALOW_IF" info 2>&1 | grep -q "type AP"; then
        echo "hostapd_s1g is up on $HALOW_IF."
        break
    fi
    sleep 1
    TRIES=$((TRIES + 1))
done
if [ "$TRIES" -ge 10 ]; then
    echo "hostapd_s1g did not reach AP mode within 10s."
    exit 4
fi

# --- bridge membership (brctl / ip, not /sys/class/net) -------------------
if ip link show "$BRIDGE" >/dev/null 2>&1; then
    CURRENT_PORTS=$(uci get network.@device[-1].ports 2>&1)
    case "$CURRENT_PORTS" in
        *"$HALOW_IF"*)
            echo "$HALOW_IF already a port of $BRIDGE."
            ;;
        *)
            uci add_list network.@device[-1].ports="$HALOW_IF"
            uci commit network
            /etc/init.d/network reload
            echo "$HALOW_IF added to $BRIDGE via UCI."
            ;;
    esac
else
    echo "Bridge $BRIDGE not found."
    echo "Use setup-relayd.sh for the proxy-ARP alternative."
    exit 3
fi

# --- DHCP suppression -----------------------------------------------------
for section in $(uci show dhcp 2>&1 | awk -F. '/=dhcp$/ {print $2}'); do
    IFACE=$(uci get "dhcp.$section.interface" 2>&1)
    if [ "$IFACE" = "$HALOW_IF" ]; then
        uci set "dhcp.$section.ignore='1'"
        uci commit dhcp
        echo "DHCP suppressed on $HALOW_IF."
    fi
done

echo "HaLow AP ready."
exit 0

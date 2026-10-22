#!/bin/sh
# Start HaLow AP, add the netdev to br-lan via UCI, disable DHCP on HaLow.
# Exit codes: 0 success, 2 no PHY, 3 bridge missing, 4 hostapd failed.

HALOW_IF=wlan0
BRIDGE=br-lan
CONF="$(dirname "$0")/hostapd_s1g.conf"

# --- PHY discovery --------------------------------------------------------
if ! ip link show "$HALOW_IF" >/dev/null 2>&1; then
    PHY=$(ls /sys/class/ieee80211/ 2>&1 | head -n 1)
    if [ -n "$PHY" ]; then
        iw phy "$PHY" interface add "$HALOW_IF" type managed
        echo "created $HALOW_IF on phy $PHY"
    else
        echo "No ieee80211 phy found.  Is the morse driver loaded?"
        exit 2
    fi
fi

ip link set "$HALOW_IF" up

# --- hostapd --------------------------------------------------------------
hostapd_s1g -B "$CONF"
HOSTAPD_RC=$?
if [ "$HOSTAPD_RC" -ne 0 ]; then
    echo "hostapd_s1g failed with exit code $HOSTAPD_RC."
    exit 4
fi
echo "hostapd_s1g started."

# --- bridge membership ----------------------------------------------------
if [ -d "/sys/class/net/$BRIDGE" ]; then
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
for dhcp_section in $(uci show dhcp 2>&1 | awk -F. '/=dhcp$/ {print $2}'); do
    IFACE=$(uci get "dhcp.$dhcp_section.interface" 2>&1)
    if [ "$IFACE" = "$HALOW_IF" ]; then
        uci set "dhcp.$dhcp_section.ignore='1'"
        uci commit dhcp
        echo "DHCP suppressed on $HALOW_IF."
    fi
done

echo "HaLow AP ready.  SSID from $CONF."
exit 0

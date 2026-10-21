#!/bin/sh
# Start HaLow AP, add the netdev to br-lan via UCI, disable DHCP on HaLow.

HALOW_IF=wlan0
BRIDGE=br-lan
CONF="$(dirname "$0")/hostapd_s1g.conf"

# --- dynamic PHY discovery ------------------------------------------------
if ! ip link show "$HALOW_IF" >/dev/null 2>&1; then
    PHY=$(ls /sys/class/ieee80211/ 2>&1 | head -n 1)
    if [ -n "$PHY" ]; then
        iw phy "$PHY" interface add "$HALOW_IF" type managed
        echo "created $HALOW_IF on phy $PHY"
    else
        echo "No ieee80211 phy found.  Is the morse driver loaded?"
        exit 0
    fi
fi

ip link set "$HALOW_IF" up
hostapd_s1g -B "$CONF"
echo "hostapd_s1g started."

# --- UCI bridge membership (persistent) -----------------------------------
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
fi

# --- suppress DHCP on the HaLow interface ---------------------------------
for dhcp_section in $(uci show dhcp 2>&1 | grep -oE 'dhcp\.@dhcp\[[0-9]+\]' ); do
    IFACE=$(uci get "$dhcp_section.interface" 2>&1)
    if [ "$IFACE" = "$HALOW_IF" ]; then
        uci set "$dhcp_section.ignore='1'"
        uci commit dhcp
        echo "DHCP suppressed on $HALOW_IF."
    fi
done

echo "HaLow AP ready.  SSID from $CONF."

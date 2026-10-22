#!/bin/sh
# Start HaLow AP.  Execs hostapd_s1g in the foreground so procd tracks
# the real daemon.  Exit codes: 0 unreachable (exec replaces shell),
# 2 no PHY, 3 bridge missing, 4 setup failed, 5 regulatory invalid.

HALOW_IF=wlan0
BRIDGE=br-lan
CONF="$(dirname "$0")/hostapd_s1g.conf"

# --- regulatory tuple ------------------------------------------------------
COUNTRY=$(awk -F= '/^country_code=/ {print $2}' "$CONF" 2>&1)
CHWIDTH=$(awk -F= '/^s1g_prim_chwidth=/ {print $2}' "$CONF" 2>&1)
OPCLASS=$(awk -F= '/^op_class=/ {print $2}' "$CONF" 2>&1)

[ -z "$COUNTRY" ] && { echo "country_code is mandatory."; exit 5; }

case "$COUNTRY:$CHWIDTH:$OPCLASS" in
    US:0:68|US:1:69|AU:0:68|AU:1:69|JP:0:68|JP:1:69) : ;;
    EU:0:66|EU:1:67) : ;;
    *)
        echo "regulatory tuple invalid: $COUNTRY/$CHWIDTH/$OPCLASS"
        echo "US 0->68 1->69 | EU 0->66 1->67 | AU 0->68 1->69 | JP 0->68 1->69"
        echo "Source: IEEE 802.11-2024 Annex E, Table E-5."
        exit 5
        ;;
esac
echo "regulatory tuple: $COUNTRY/$CHWIDTH/$OPCLASS"

# --- hostapd presence -----------------------------------------------------
command -v hostapd_s1g >/dev/null 2>&1 || {
    echo "hostapd_s1g not found.  Install CONFIG_PACKAGE_hostapd_s1g."
    exit 4
}

# --- PHY discovery (BusyBox-safe: no find -printf, no ls) -----------------
if ! iw dev "$HALOW_IF" info >/dev/null 2>&1; then
    PHY=""
    for phy_path in /sys/class/ieee80211/*; do
        if [ -e "$phy_path" ]; then
            PHY=$(basename "$phy_path")
            break
        fi
    done
    if [ -z "$PHY" ]; then
        PHY=$(iw dev 2>&1 | awk '/phy#/ {print $2; exit}')
    fi
    if [ -n "$PHY" ]; then
        iw phy "$PHY" interface add "$HALOW_IF" type managed || exit 4
        echo "created $HALOW_IF on $PHY"
    else
        echo "No ieee80211 phy.  Is the morse driver loaded?"
        exit 2
    fi
fi

ip link set "$HALOW_IF" up || exit 4

# --- bridge membership ----------------------------------------------------
if ip link show "$BRIDGE" >/dev/null 2>&1; then
    FOUND=0
    for port in $(uci get network.@device[-1].ports 2>&1); do
        [ "$port" = "$HALOW_IF" ] && FOUND=1
    done
    if [ "$FOUND" -eq 0 ]; then
        uci add_list network.@device[-1].ports="$HALOW_IF" || exit 4
        uci commit network
        /etc/init.d/network reload
    fi
else
    echo "Bridge $BRIDGE not found.  Use setup-relayd.sh."
    exit 3
fi

# --- DHCP suppression -----------------------------------------------------
for section in $(uci show dhcp 2>&1 | awk -F. '/=dhcp$/ {print $2}'); do
    IFACE=$(uci get "dhcp.$section.interface" 2>&1)
    if [ "$IFACE" = "$HALOW_IF" ]; then
        uci set "dhcp.$section.ignore='1'" && uci commit dhcp
    fi
done

# --- exec hostapd in foreground (procd tracks this PID) -------------------
echo "exec hostapd_s1g $CONF"
exec hostapd_s1g "$CONF"

#!/bin/sh
# Start HaLow AP.  Validates the regulatory tuple before hostapd_s1g.
# Exit codes: 0 success, 2 no PHY, 3 bridge missing, 4 hostapd failed,
#             5 regulatory tuple invalid.

HALOW_IF=wlan0
BRIDGE=br-lan
CONF="$(dirname "$0")/hostapd_s1g.conf"
CTRL_SOCK=/var/run/hostapd

# --- regulatory tuple validation ------------------------------------------
CHWIDTH=$(awk -F= '/^s1g_prim_chwidth=/ {print $2}' "$CONF" 2>&1)
OPCLASS=$(awk -F= '/^op_class=/ {print $2}' "$CONF" 2>&1)
COUNTRY=$(awk -F= '/^country_code=/ {print $2}' "$CONF" 2>&1)

case "$CHWIDTH:$OPCLASS" in
    0:69|0:70|0:71)
        echo "s1g_prim_chwidth=0 (1 MHz) is incompatible with op_class=$OPCLASS."
        echo "Use op_class=68 (US 1 MHz) or set s1g_prim_chwidth=1 for 2 MHz."
        exit 5
        ;;
    1:67|1:68)
        echo "s1g_prim_chwidth=1 (2 MHz) is incompatible with op_class=$OPCLASS."
        echo "Use op_class=69 (US 2 MHz) or set s1g_prim_chwidth=0 for 1 MHz."
        exit 5
        ;;
esac
if [ -z "$COUNTRY" ]; then
    echo "country_code is mandatory for S1G."
    exit 5
fi
echo "regulatory tuple: country=$COUNTRY op_class=$OPCLASS chwidth=$CHWIDTH"

# --- PHY discovery --------------------------------------------------------
if ! iw dev "$HALOW_IF" info >/dev/null 2>&1; then
    PHY=$(iw dev 2>&1 | awk '/phy#/ {print $2; exit}')
    if [ -z "$PHY" ]; then
        PHY=$(ls /sys/class/ieee80211/ 2>&1 | head -n 1)
    fi
    if [ -n "$PHY" ]; then
        iw phy "$PHY" interface add "$HALOW_IF" type managed
        echo "created $HALOW_IF on $PHY"
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

TRIES=0
while [ "$TRIES" -lt 10 ]; do
    if iw dev "$HALOW_IF" info 2>&1 | grep -q "type AP"; then
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

# --- bridge membership, exact-match guard ---------------------------------
if ip link show "$BRIDGE" >/dev/null 2>&1; then
    FOUND=0
    for port in $(uci get network.@device[-1].ports 2>&1); do
        if [ "$port" = "$HALOW_IF" ]; then
            FOUND=1
        fi
    done
    if [ "$FOUND" -eq 1 ]; then
        echo "$HALOW_IF already a port of $BRIDGE."
    else
        uci add_list network.@device[-1].ports="$HALOW_IF"
        uci commit network
        /etc/init.d/network reload
        echo "$HALOW_IF added to $BRIDGE via UCI."
    fi
else
    echo "Bridge $BRIDGE not found.  Use setup-relayd.sh for proxy-ARP."
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

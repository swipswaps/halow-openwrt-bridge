#!/bin/sh
# Start HaLow AP.  Validates country_code, s1g_prim_chwidth, and op_class
# as a single regulatory tuple before hostapd_s1g.
# Exit codes: 0 success, 2 no PHY, 3 bridge missing, 4 hostapd failed,
#             5 regulatory tuple invalid.

HALOW_IF=wlan0
BRIDGE=br-lan
CONF="$(dirname "$0")/hostapd_s1g.conf"

# --- regulatory tuple ------------------------------------------------------
COUNTRY=$(awk -F= '/^country_code=/ {print $2}' "$CONF" 2>&1)
CHWIDTH=$(awk -F= '/^s1g_prim_chwidth=/ {print $2}' "$CONF" 2>&1)
OPCLASS=$(awk -F= '/^op_class=/ {print $2}' "$CONF" 2>&1)

if [ -z "$COUNTRY" ]; then
    echo "country_code is mandatory for S1G."
    exit 5
fi

case "$COUNTRY:$CHWIDTH:$OPCLASS" in
    US:0:68|US:1:69)   : ;;
    EU:0:66|EU:1:67)   : ;;
    AU:0:68|AU:1:69)   : ;;
    JP:0:68|JP:1:69)   : ;;
    *)
        echo "regulatory tuple invalid: country=$COUNTRY width=$CHWIDTH op_class=$OPCLASS"
        echo "valid: US 0->68 1->69 | EU 0->66 1->67 | AU 0->68 1->69 | JP 0->68 1->69"
        echo "Source: IEEE 802.11-2024 Annex E, Table E-5."
        exit 5
        ;;
esac
echo "regulatory tuple: country=$COUNTRY width=$CHWIDTH op_class=$OPCLASS"

# --- PHY discovery (SC2012 fixed: find, not ls) ---------------------------
if ! iw dev "$HALOW_IF" info >/dev/null 2>&1; then
    PHY=$(iw dev 2>&1 | awk '/phy#/ {print $2; exit}')
    if [ -z "$PHY" ]; then
        PHY=$(find /sys/class/ieee80211/ -maxdepth 1 -type l -printf '%f\n' 2>&1 | head -n 1)
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

# --- bridge membership, exact match ---------------------------------------
if ip link show "$BRIDGE" >/dev/null 2>&1; then
    FOUND=0
    for port in $(uci get network.@device[-1].ports 2>&1); do
        [ "$port" = "$HALOW_IF" ] && FOUND=1
    done
    if [ "$FOUND" -eq 1 ]; then
        echo "$HALOW_IF already a port of $BRIDGE."
    else
        uci add_list network.@device[-1].ports="$HALOW_IF"
        uci commit network
        /etc/init.d/network reload
        echo "$HALOW_IF added to $BRIDGE."
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

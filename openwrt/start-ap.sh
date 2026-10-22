#!/bin/sh
# Start HaLow AP.  Execs hostapd_s1g in the foreground so procd tracks
# the real daemon.
# Exit codes: 0 unreachable (exec replaces shell), 2 no PHY,
# 3 bridge missing, 4 setup failed, 5 regulatory/PSK invalid,
# 6 hostapd_s1g already running.

HALOW_IF=wlan0
BRIDGE=br-lan
CONF="$(dirname "$0")/hostapd_s1g.conf"
LOCK=/var/run/halow-ap.lock

# --- single-instance lock -------------------------------------------------
exec 9>"$LOCK"
if ! flock -n 9; then
    echo "another start-ap.sh holds $LOCK."
    exit 6
fi

# --- tools ----------------------------------------------------------------
for tool in iw hostapd_s1g flock; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "$tool not found.  Install the matching OpenWrt package."
        exit 4
    fi
done

# --- placeholder PSK guard ------------------------------------------------
PSK=$(awk '/^wpa_passphrase=/ {sub(/^wpa_passphrase=/,""); print; exit}' "$CONF")
if [ -z "$PSK" ] || echo "$PSK" | grep -q "CHANGEME"; then
    echo "wpa_passphrase in $CONF is a placeholder or empty."
    exit 5
fi

# --- regulatory tuple -----------------------------------------------------
COUNTRY=$(awk -F= '/^country_code=/ {print $2}' "$CONF" 2>&1)
CHWIDTH=$(awk -F= '/^s1g_prim_chwidth=/ {print $2}' "$CONF" 2>&1)
OPCLASS=$(awk -F= '/^op_class=/ {print $2}' "$CONF" 2>&1)

if [ -z "$COUNTRY" ]; then
    echo "country_code is mandatory."
    exit 5
fi

case "$COUNTRY" in
    US|AU|JP) ALLOWED="0:68 1:69" ;;
    EU)       ALLOWED="0:66 1:67" ;;
    *)
        if [ "${ALLOW_UNKNOWN_REGION:-0}" = "1" ]; then
            ALLOWED="$CHWIDTH:$OPCLASS"
            echo "WARNING: unknown region $COUNTRY allowed by ALLOW_UNKNOWN_REGION=1"
        else
            echo "Unknown region $COUNTRY."
            echo "Set ALLOW_UNKNOWN_REGION=1 if $CHWIDTH:$OPCLASS is correct"
            echo "for your regulator.  EU 1 MHz=66 2 MHz=67; US/AU/JP 1 MHz=68 2 MHz=69."
            exit 5
        fi
        ;;
esac

MATCH=0
for pair in $ALLOWED; do
    [ "$pair" = "$CHWIDTH:$OPCLASS" ] && MATCH=1
done
if [ "$MATCH" -eq 0 ]; then
    echo "tuple $COUNTRY/$CHWIDTH/$OPCLASS is not in [$ALLOWED]."
    exit 5
fi
echo "regulatory tuple: $COUNTRY/$CHWIDTH/$OPCLASS"

# --- stop any existing hostapd_s1g before probe ---------------------------
if pidof hostapd_s1g >/dev/null 2>&1; then
    if [ "${FORCE:-0}" != "1" ]; then
        echo "hostapd_s1g already running; set FORCE=1 to replace it."
        exit 6
    fi
    killall -q hostapd_s1g
    # wait up to 3 s for the interface to leave AP mode
    i=0
    while [ "$i" -lt 3 ]; do
        if ! iw dev "$HALOW_IF" info 2>&1 | grep -q "type AP"; then
            break
        fi
        sleep 1
        i=$((i + 1))
    done
fi

# --- PHY discovery (BusyBox-safe) -----------------------------------------
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

# --- br-lan device section by name ----------------------------------------
BRIDGE_SECTION=""
for section in $(uci show network 2>&1 | awk -F. '/=device$/ {print $2}'); do
    NAME=$(uci get "network.$section.name" 2>&1)
    [ "$NAME" = "$BRIDGE" ] && BRIDGE_SECTION="$section"
done

if [ -z "$BRIDGE_SECTION" ]; then
    echo "Bridge $BRIDGE has no device section.  Use setup-relayd.sh."
    exit 3
fi

FOUND=0
for port in $(uci get "network.$BRIDGE_SECTION.ports" 2>&1); do
    [ "$port" = "$HALOW_IF" ] && FOUND=1
done
if [ "$FOUND" -eq 0 ]; then
    uci add_list "network.$BRIDGE_SECTION.ports=$HALOW_IF" || exit 4
    uci commit network
    /etc/init.d/network reload
fi

# --- DHCP suppression -----------------------------------------------------
CHANGED=0
for section in $(uci show dhcp 2>&1 | awk -F. '/=dhcp$/ {print $2}'); do
    IFACE=$(uci get "dhcp.$section.interface" 2>&1)
    if [ "$IFACE" = "$HALOW_IF" ]; then
        uci set "dhcp.$section.ignore='1'"
        CHANGED=1
    fi
done
[ "$CHANGED" -eq 1 ] && uci commit dhcp

mkdir -p /var/run/hostapd
chmod 750 /var/run/hostapd

echo "exec hostapd_s1g $CONF"
exec hostapd_s1g "$CONF"

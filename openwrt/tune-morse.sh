#!/bin/sh
# MM8108 field workarounds and security guidance.

ACTION="$1"

have_param() {
    modinfo morse 2>&1 | grep -q "parm:.*$1"
}

case "$ACTION" in
    security)
        echo "CVE-2026-7764: out-of-bounds read in morse.ko Vendor IE processing."
        echo "An unauthenticated attacker within radio range can leak kernel"
        echo "heap memory or cause a denial of service via a crafted 802.11ah"
        echo "beacon or probe response."
        echo "Fixed in Morse Micro HaLowLink 2 software 2.11.12 and later."
        echo "Advisory: https://www.morsemicro.com/security/advisories/mm-sa-2026-003/"
        echo "Action: upgrade the morse driver and firmware to 2.11.12+ before"
        echo "deploying in any environment where radio-range attackers are in scope."
        ;;
    rssi-cliff)
        echo "2 MHz near -73 dBm: shift RSSI by ~2 dB (attenuator or reposition),"
        echo "or reduce to 1 MHz (s1g_prim_chwidth=0, op_class=68 US / 66 EU)."
        ;;
    strong-signal)
        echo "1 MHz at strong signal: move devices further apart."
        ;;
    close-range)
        echo "Very close range: keep at least 2 m separation before pairing."
        ;;
    wds)
        if have_param max_txq_len; then
            echo "rmmod morse; insmod morse max_txq_len=0"
        else
            echo "max_txq_len not exposed by this build.  Upgrade to 2.4.3+."
        fi
        ;;
    airtime)
        if have_param enable_airtime_fairness; then
            echo "rmmod morse; insmod morse enable_airtime_fairness=true"
        else
            echo "enable_airtime_fairness not exposed.  Apply Morse Micro"
            echo "OpenWrt airtime-fairness patches or upgrade."
        fi
        ;;
    throughput)
        echo "MM6108/MM8108 maximum TCP throughput is ~10% lower than expected."
        echo "Documented release-note limitation; no module workaround."
        ;;
    *)
        echo "usage: $0 security | rssi-cliff | strong-signal | close-range | wds | airtime | throughput"
        exit 2
        ;;
esac
exit 0

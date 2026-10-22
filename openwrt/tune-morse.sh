#!/bin/sh
# MM8108 workarounds.  check_param returns present | absent | unknown.

ACTION="$1"

check_param() {
    if ! command -v modinfo >/dev/null 2>&1; then
        echo "unknown"
        return 0
    fi
    if modinfo morse 2>&1 | grep -q "parm:.*$1"; then
        echo "present"
    else
        echo "absent"
    fi
}

case "$ACTION" in
    security)
        echo "CVE-2026-7764: out-of-bounds read in morse.ko Vendor IE processing."
        echo "Unauthenticated attacker within radio range can disclose up to"
        echo "9 bytes of kernel heap or cause a kernel panic via a malformed"
        echo "802.11ah beacon or probe response.  CVSS 3.1: 6.8."
        echo "Fixed in HaLowLink 2 software 2.11.12 and later."
        echo "Advisory: https://app.opencve.io/cve/CVE-2026-7764"
        echo "Action: upgrade morse.ko and firmware to 2.11.12+."
        ;;
    rssi-cliff)
        echo "2 MHz near -73 dBm: shift RSSI ~2 dB (attenuator/reposition),"
        echo "or reduce to 1 MHz (s1g_prim_chwidth=0, op_class=68 US / 66 EU)."
        ;;
    strong-signal)
        echo "1 MHz at strong signal: move devices further apart."
        ;;
    close-range)
        echo "Very close range: keep at least 2 m separation before pairing."
        ;;
    wds)
        case "$(check_param max_txq_len)" in
            present) echo "rmmod morse; insmod morse max_txq_len=0" ;;
            absent)  echo "max_txq_len absent; upgrade to 2.4.3+." ;;
            unknown) echo "modinfo unavailable; cannot verify max_txq_len." ;;
        esac
        ;;
    airtime)
        case "$(check_param enable_airtime_fairness)" in
            present) echo "rmmod morse; insmod morse enable_airtime_fairness=true" ;;
            absent)  echo "enable_airtime_fairness absent; apply Morse Micro patches." ;;
            unknown) echo "modinfo unavailable; cannot verify enable_airtime_fairness." ;;
        esac
        ;;
    throughput)
        echo "MM6108/MM8108 TCP throughput is ~10% below expectation."
        echo "Documented release-note limitation; no module workaround."
        ;;
    *)
        echo "usage: $0 security | rssi-cliff | strong-signal | close-range | wds | airtime | throughput"
        exit 2
        ;;
esac
exit 0

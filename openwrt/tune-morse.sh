#!/bin/sh
# MM8108 workarounds and security guidance.

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
        echo "CVE-2026-7764 / GHSA-7C7H-P74X-W3H5"
        echo "Out-of-bounds read in morse.ko Vendor IE processing."
        echo "Fixed in HaLowLink 2 software 2.11.12 and later."
        echo "CVSS 3.1: 6.8 (AV:L/AC:L/PR:N/UI:N/S:U/C:L/I:N/A:H)."
        echo "Advisory: https://github.com/advisories/GHSA-7C7H-P74X-W3H5"
        ;;
    rssi-cliff)
        echo "2 MHz near -73 dBm: shift RSSI ~2 dB, or reduce to 1 MHz."
        ;;
    strong-signal)
        echo "1 MHz at strong signal: move devices further apart."
        ;;
    close-range)
        echo "Very close range: keep at least 2 m separation."
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
    thermal)
        echo "MM8108 thermal protection (Application Note 56):"
        echo "  Tp_on  = 90 C  (transmitter disabled)"
        echo "  Tp_off = 85 C  (transmitter re-enabled)"
        echo "Firmware 1.17.9 uses these thresholds.  Gateworks notes the"
        echo "transmitter is disabled once the die reaches 85 C internally."
        echo "Ensure enclosure airflow and duty-cycle headroom; avoid"
        echo "sustained 26 dBm operation in sealed enclosures."
        ;;
    throughput)
        echo "MM6108/MM8108 TCP throughput is ~10% below expectation."
        echo "Documented release-note limitation; no module workaround."
        ;;
    *)
        echo "usage: $0 security | rssi-cliff | strong-signal | close-range | wds | airtime | thermal | throughput"
        exit 2
        ;;
esac
exit 0

#!/bin/sh
# MM8108 workarounds and security guidance.
# check_param returns present | absent | unknown.

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
        echo "morse_vendor_find_vendor_ie() does not validate the IE length"
        echo "against the expected structure size before passing the result"
        echo "to morse_vendor_rx_caps_ops_ie() and morse_vendor_fill_sta_vendor_info(),"
        echo "which read at fixed offsets.  The length check only requires the"
        echo "IE to be longer than 3 bytes, so a crafted 802.11ah beacon or"
        echo "probe response can cause a heap out-of-bounds read of up to 9"
        echo "bytes, disclosing kernel heap memory or causing a kernel oops."
        echo "CVSS 3.1 base score: 6.8."
        echo "Fixed in HaLowLink 2 software 2.11.12 and later."
        echo "Advisory: https://github.com/advisories/GHSA-7C7H-P74X-W3H5"
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
    thermal)
        echo "MM8108 thermal protection: the on-chip PA delivers up to 26 dBm."
        echo "Over-temperature protection (OTP) disables the transmitter when"
        echo "the die exceeds the datasheet threshold.  Public summaries"
        echo "commonly cite ~85 C; consult the MM8108 datasheet for the"
        echo "threshold and duration of the specific silicon revision."
        echo "Action: ensure enclosure airflow and duty-cycle headroom; avoid"
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

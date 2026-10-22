#!/bin/sh
# MM8108 field workarounds.  UCI is deliberately bypassed for HaLow, so
# this script prints physical and module-parameter actions instead of
# writing UCI options that do not exist.

ACTION="$1"

case "$ACTION" in
    rssi-cliff)
        echo "MM8108 2 MHz near -73 dBm: documented receive degradation."
        echo "Workaround (release notes 2.4.3): increase or decrease RSSI by ~2 dB."
        echo "  - Add a 2 dB attenuator on the AP antenna, or"
        echo "  - Reposition so path loss changes by ~2 dB (~20-30 cm at 900 MHz),"
        echo "  - Or reduce bandwidth to 1 MHz (s1g_prim_chwidth=0, op_class=68)."
        ;;
    strong-signal)
        echo "MM8108 1 MHz at strong signal: documented receive degradation."
        echo "Workaround (release notes 2.4.3): move devices further apart."
        ;;
    close-range)
        echo "MM8108 very close range: intermittent association failure."
        echo "Workaround (release notes 2.4.3): at least 2 m separation."
        ;;
    wds)
        echo "Multi-STA WDS downlink imbalance."
        echo "Workaround (release notes 2.4.3): set max_txq_len=0."
        echo "  rmmod morse; insmod morse max_txq_len=0"
        ;;
    airtime)
        echo "Kernel >6.2 airtime fairness is off by default on MM8108."
        echo "Workaround (release notes 2.4.3):"
        echo "  rmmod morse; insmod morse enable_airtime_fairness=true"
        echo "Additional patches are in the Morse Micro OpenWrt feed."
        ;;
    *)
        echo "usage: $0 rssi-cliff | strong-signal | close-range | wds | airtime"
        exit 2
        ;;
esac
exit 0

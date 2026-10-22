#!/bin/sh
# MM8108 field workarounds.  UCI is deliberately bypassed for HaLow, so
# this script prints physical and module-parameter actions instead of
# writing UCI options that do not exist.

ACTION="$1"
VALUE="$2"

case "$ACTION" in
    rssi-cliff)
        echo "MM8108 2 MHz near -73 dBm: documented receive degradation."
        echo "Workaround (release notes): increase or decrease RSSI by ~2 dB."
        echo "  - Add a 2 dB attenuator on the AP antenna, or"
        echo "  - Move the AP and STA ~2 dB closer in path loss (roughly 20-30 cm"
        echo "    at 900 MHz in free space), or"
        echo "  - Reduce bandwidth from 2 MHz to 1 MHz (edit s1g_prim_chwidth=0"
        echo "    and op_class=68 in hostapd_s1g.conf, then restart hostapd_s1g)."
        ;;
    strong-signal)
        echo "MM8108 1 MHz at strong signal: documented receive degradation."
        echo "Workaround (release notes): move devices further apart to lower"
        echo "signal strength.  Target below -50 dBm at the AP."
        ;;
    close-range)
        echo "MM8108 very close range (<10 dBm): intermittent STA association"
        echo "failure is documented.  Workaround (release notes): ensure at"
        echo "least 2 meters separation between AP and STA before pairing."
        ;;
    queue)
        echo "Multi-STA WDS downlink imbalance: set max_txq_len=0."
        echo "  rmmod morse; insmod morse max_txq_len=0"
        echo "Not persistent; add to /etc/modules.d/ if needed."
        ;;
    airtime)
        echo "Kernel >6.2 airtime fairness is off by default on MM8108."
        echo "  rmmod morse; insmod morse enable_airtime_fairness=1"
        echo "Morse Micro also provides airtime-fairness patches in its feed."
        ;;
    *)
        echo "usage: $0 rssi-cliff | strong-signal | close-range | queue | airtime"
        exit 2
        ;;
esac
exit 0

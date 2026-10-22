#!/bin/sh
# MM8108 workarounds.  Checks whether the loaded module accepts the
# parameter before printing the insmod command.

ACTION="$1"

have_param() {
    modinfo morse 2>&1 | grep -q "parm:.*$1"
}

case "$ACTION" in
    wds)
        if have_param max_txq_len; then
            echo "rmmod morse; insmod morse max_txq_len=0"
        else
            echo "max_txq_len not exposed by this morse build."
            echo "Update to a release that includes the fix (2.4.3+)."
        fi
        ;;
    airtime)
        if have_param enable_airtime_fairness; then
            echo "rmmod morse; insmod morse enable_airtime_fairness=true"
        else
            echo "enable_airtime_fairness not exposed.  Apply the Morse"
            echo "Micro OpenWrt airtime-fairness patches or upgrade."
        fi
        ;;
    rssi-cliff)
        echo "2 MHz near -73 dBm: shift RSSI by ~2 dB (attenuator or reposition),"
        echo "or reduce to 1 MHz (s1g_prim_chwidth=0, op_class=68)."
        ;;
    strong-signal)
        echo "1 MHz at strong signal: move devices further apart."
        ;;
    close-range)
        echo "Very close range: keep at least 2 m separation before pairing."
        ;;
    *)
        echo "usage: $0 rssi-cliff | strong-signal | close-range | wds | airtime"
        exit 2
        ;;
esac
exit 0

#!/bin/sh
# MM8108 workarounds and known-issue guidance.
# Checks modinfo before printing insmod commands.

ACTION="$1"

have_param() {
    modinfo morse 2>&1 | grep -q "parm:.*$1"
}

case "$ACTION" in
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
    wds)
        if have_param max_txq_len; then
            echo "rmmod morse; insmod morse max_txq_len=0"
        else
            echo "max_txq_len not exposed by this morse build."
            echo "Update to a release that includes the fix."
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
    throughput)
        echo "MM6108/MM8108 maximum TCP throughput is ~10% lower than expected."
        echo "This is a documented release-note limitation with no module"
        echo "workaround; expect it until a future firmware release."
        ;;
    security)
        echo "MM810x vendor Information Element handling has an"
        echo "out-of-bounds memory access vulnerability in the referenced"
        echo "driver release.  Apply the Morse Micro OpenWrt patch sets"
        echo "from https://github.com/MorseMicro/morse-feed before"
        echo "deploying in untrusted environments."
        ;;
    *)
        echo "usage: $0 rssi-cliff | strong-signal | close-range | wds | airtime | throughput | security"
        exit 2
        ;;
esac
exit 0

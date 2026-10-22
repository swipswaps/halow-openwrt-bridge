#!/bin/sh
# MM8108 receive-degradation workaround.
# Default path: reduce bandwidth.  Forcing MCS is opt-in because it
# increases packet loss when the rate is wrong for the channel.
# Usage:
#   ./tune-morse.sh bandwidth 1      # 1 MHz (from 2 MHz)
#   ./tune-morse.sh mcs 2            # opt-in fixed MCS
#   ./tune-morse.sh rssi-offset 2    # where the driver exposes it

ACTION="$1"
VALUE="$2"

case "$ACTION" in
    bandwidth)
        case "$VALUE" in
            1|2|4|8)
                uci set wireless.radio0.s1g_prim_chwidth=$([ "$VALUE" = "1" ] && echo 0 || echo 1)
                uci commit wireless
                echo "bandwidth set to $VALUE MHz via UCI (manual start-ap.sh still required)."
                ;;
            *)
                echo "bandwidth must be 1, 2, 4, or 8."
                exit 2
                ;;
        esac
        ;;
    mcs)
        echo "WARNING: forced MCS increases packet loss when the rate is wrong."
        echo "Reload the morse module with:"
        echo "  rmmod morse; insmod morse fixed_mcs=$VALUE enable_fixed_rate=1"
        echo "This is not persistent; add it to /etc/modules.d/ if needed."
        ;;
    rssi-offset)
        echo "Driver RSSI offset is not exposed as a module parameter in 2.11.12."
        echo "The documented workaround is to shift the physical RSSI by +/- 2 dB,"
        echo "which means repositioning antennas or adding an attenuator."
        ;;
    *)
        echo "usage: $0 bandwidth {1|2|4|8} | mcs {0..7} | rssi-offset {n}"
        exit 2
        ;;
esac
exit 0

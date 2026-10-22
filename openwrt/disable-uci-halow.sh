#!/bin/sh
# Disable UCI control of the HaLow radio only.
# Blanket-disabling every radioN removes the management radio on
# multi-radio routers, so this script fails closed unless HALOW_RADIO
# names the UCI section for the HaLow card.
# Exit codes: 0 success, 5 HALOW_RADIO unset or not a radioN section.

HALOW_RADIO="${HALOW_RADIO:-}"

if [ -z "$HALOW_RADIO" ]; then
    echo "HALOW_RADIO is not set."
    echo "Available radio sections:"
    uci show wireless 2>&1 | awk -F. '/\.radio[0-9]+=/ {print "  " $2}'
    echo "Re-run as: HALOW_RADIO=radio1 $0"
    exit 5
fi

case "$HALOW_RADIO" in
    radio[0-9]*) : ;;
    *) echo "HALOW_RADIO must be radioN (got $HALOW_RADIO)."; exit 5 ;;
esac

if ! uci get wireless."$HALOW_RADIO" >/dev/null 2>&1; then
    echo "wireless.$HALOW_RADIO does not exist."
    exit 5
fi

uci set wireless."$HALOW_RADIO".disabled='1'
uci commit wireless
wifi reload
echo "UCI control disabled for $HALOW_RADIO only."
exit 0

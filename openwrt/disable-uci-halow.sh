#!/bin/sh
# Disable UCI control of HaLow radios.
# Dynamically discovers all radioN sections and disables them.

UCI_RADIOS=$(uci show wireless 2>&1 | grep -oE 'wireless\.radio[0-9]+' | sort -u)

for radio in $UCI_RADIOS; do
    uci set "$radio.disabled='1'"
    echo "disabled UCI control for $radio"
done

uci commit wireless
wifi reload

echo "UCI HaLow radio control disabled."

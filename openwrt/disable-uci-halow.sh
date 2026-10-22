#!/bin/sh
# Disable UCI control of every radioN section.

for section in $(uci show wireless 2>&1 | awk -F. '/\.radio[0-9]+=/ {print $2}'); do
    uci set "wireless.$section.disabled='1'"
    echo "disabled UCI control for $section"
done

uci commit wireless
wifi reload
echo "UCI HaLow radio control disabled."
exit 0

#!/bin/sh
# Reproduce the audit lint locally.
# SC2034 is excluded only for halow-ap.init: START, STOP, and USE_PROCD
# are read by rc.common, not by the script itself.

RC=0
FILES="openwrt/*.sh android/*.sh openwrt/uci-defaults-halow install.sh lint.sh push.sh fetch-license.sh"

for f in $FILES; do
    if ! sh -n "$f"; then
        echo "sh -n FAILED: $f"
        RC=3
    fi
done

if command -v shellcheck >/dev/null 2>&1; then
    for f in $FILES; do
        if ! shellcheck -s sh "$f"; then
            echo "shellcheck flagged: $f"
            RC=3
        fi
    done
    # init script: allow SC2034 only here
    if ! shellcheck -s sh -e SC2034 openwrt/halow-ap.init; then
        echo "shellcheck flagged: openwrt/halow-ap.init"
        RC=3
    fi
else
    echo "shellcheck not installed; sh -n only."
fi

if [ "$RC" -eq 0 ]; then
    echo "lint: pass"
fi
exit "$RC"

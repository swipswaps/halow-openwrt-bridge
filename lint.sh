#!/bin/sh
# Reproduce the audit lint locally.
# sh -n checks syntax; shellcheck checks style and common defects.
# SC2034 is excluded for OpenWrt init scripts because rc.common reads
# START, STOP, and USE_PROCD by indirection.

RC=0
FILES="openwrt/*.sh android/*.sh openwrt/uci-defaults-halow openwrt/halow-ap.init install.sh lint.sh"

for f in $FILES; do
    if ! sh -n "$f"; then
        echo "sh -n FAILED: $f"
        RC=3
    fi
done

if command -v shellcheck >/dev/null 2>&1; then
    for f in $FILES; do
        if ! shellcheck -s sh -e SC2034 "$f"; then
            echo "shellcheck flagged: $f"
            RC=3
        fi
    done
else
    echo "shellcheck not installed; sh -n only."
fi

if [ "$RC" -eq 0 ]; then
    echo "lint: pass"
fi
exit "$RC"

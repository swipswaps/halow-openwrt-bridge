#!/bin/sh
# Reproduce the audit lint locally.
# SC2034 is excluded only for halow-ap.init: START, STOP, and USE_PROCD
# are read by rc.common, not by the script itself.
# halow-ap.init is listed explicitly because its extension is .init,
# not .sh, so the openwrt/*.sh glob would skip it.

RC=0
FILES="openwrt/*.sh android/*.sh openwrt/uci-defaults-halow openwrt/halow-ap.init install.sh lint.sh push.sh fetch-license.sh"

for f in $FILES; do
    if ! sh -n "$f"; then
        echo "sh -n FAILED: $f"
        RC=3
    fi
done

if command -v shellcheck >/dev/null 2>&1; then
    for f in $FILES; do
        case "$f" in
            openwrt/halow-ap.init)
                if ! shellcheck -s sh -e SC2034 "$f"; then
                    echo "shellcheck flagged: $f"
                    RC=3
                fi
                ;;
            *)
                if ! shellcheck -s sh "$f"; then
                    echo "shellcheck flagged: $f"
                    RC=3
                fi
                ;;
        esac
    done
else
    echo "shellcheck not installed; sh -n only."
fi

if [ "$RC" -eq 0 ]; then
    echo "lint: pass"
fi
exit "$RC"

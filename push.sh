#!/bin/sh
# Lint-gated and license-gated push.
# Usage: ./push.sh "commit message"
# LINT_OVERRIDE=1 bypasses lint only, never the license gate.

if [ "$#" -eq 0 ]; then
    echo "usage: $0 <commit message>"
    exit 2
fi

BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "pushing to branch: $BRANCH"

# --- license gate ---------------------------------------------------------
if ! grep -q "GNU GENERAL PUBLIC LICENSE" LICENSE 2>&1 || ! grep -q "Version 2, June 1991" LICENSE 2>&1; then
    echo "LICENSE is not the verbatim GPL-2.0 text; fetching."
    if ! ./fetch-license.sh; then
        echo "fetch-license.sh failed; refusing to push without a compliant LICENSE."
        exit 3
    fi
fi

# --- lint gate ------------------------------------------------------------
sh lint.sh
LINT_RC=$?
if [ "$LINT_RC" -ne 0 ]; then
    if [ "${LINT_OVERRIDE:-0}" != "1" ]; then
        echo "lint failed (rc=$LINT_RC); aborting push."
        echo "fix the findings, or set LINT_OVERRIDE=1 to bypass."
        exit 3
    fi
    echo "LINT_OVERRIDE=1; proceeding after lint failure."
fi

# --- commit message without quoting hazards -------------------------------
MSG="$1"
shift
if [ "$#" -gt 0 ]; then
    MSG="$MSG $*"
fi
printf '%s\n' "$MSG" > /tmp/halow-commit-msg.$$
git add -A
git commit -F /tmp/halow-commit-msg.$$
rm -f /tmp/halow-commit-msg.$$

git push origin "$BRANCH"
echo "pushed to origin/$BRANCH"

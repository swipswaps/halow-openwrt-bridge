#!/bin/sh
# Lint-gated push.  Live gate, not operator memory.
# Usage: ./push.sh "commit message"
# LINT_OVERRIDE=1 bypasses the gate (not recommended).

if [ "$#" -eq 0 ]; then
    echo "usage: $0 <commit message>"
    exit 2
fi

BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "pushing to branch: $BRANCH"

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

git add -A
git commit -m "$*"
git push origin "$BRANCH"
echo "pushed to origin/$BRANCH"

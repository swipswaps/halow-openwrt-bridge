#!/bin/sh
# Fetch the verbatim GPL-2.0 text into LICENSE.
# The repository ships a pointer file instead of the full text to avoid
# partial or diverging copies.  Run this before tagging or distributing.
# Exit codes: 0 success, 2 curl missing, 3 download failed.

URL="https://www.gnu.org/licenses/old-licenses/gpl-2.0.txt"

if ! command -v curl >/dev/null 2>&1; then
    echo "curl required to fetch the GPL text."
    exit 2
fi

if ! curl -fsSL "$URL" -o LICENSE.tmp; then
    echo "download failed: $URL"
    exit 3
fi

mv LICENSE.tmp LICENSE
echo "wrote $(wc -c < LICENSE) bytes to LICENSE."
echo "verify: head -n 1 LICENSE"
exit 0

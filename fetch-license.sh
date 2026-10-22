#!/bin/sh
# Fetch the verbatim GPL-2.0 text into LICENSE and validate it.

URL="https://www.gnu.org/licenses/old-licenses/gpl-2.0.txt"

if ! command -v curl >/dev/null 2>&1; then
    echo "curl required to fetch the GPL text."
    exit 2
fi

if ! curl -fsSL "$URL" -o LICENSE.tmp; then
    echo "download failed: $URL"
    exit 3
fi

if ! grep -q "GNU GENERAL PUBLIC LICENSE" LICENSE.tmp; then
    echo "downloaded file does not look like GPL-2.0."
    exit 3
fi

if ! grep -q "Version 2, June 1991" LICENSE.tmp; then
    echo "downloaded file is not GPL-2.0."
    exit 3
fi

mv LICENSE.tmp LICENSE
echo "wrote $(wc -c < LICENSE) bytes to LICENSE."
exit 0

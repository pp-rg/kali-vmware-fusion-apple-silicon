#!/usr/bin/env bash
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
bash "$HERE/keyboard/uninstall.sh"; bash "$HERE/perf/uninstall.sh"
rm -f ~/.config/autostart/hidpi-auto.desktop ~/.local/bin/hidpi-auto.sh
sed -i '/>>> hidpi >>>/,/<<< hidpi <<</d' ~/.xsessionrc 2>/dev/null
echo "Done. The square theme (~/.themes/*-square) can be deleted by hand."

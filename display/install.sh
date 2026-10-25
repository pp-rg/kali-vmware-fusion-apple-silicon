#!/usr/bin/env bash
# Retina display: automatic 1x/2x switch (GTK, cursor, window theme), Qt scale factor, square-corner window theme.
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
BEGIN='# >>> hidpi >>>'; END='# <<< hidpi <<<'
mkdir -p ~/.local/bin ~/.config/autostart
bash "$HERE/make-square-theme.sh" /usr/share/themes/Kali-Dark-xHiDPI || echo "square theme not created (continuing)"
install -m755 "$HERE/hidpi-auto.sh" ~/.local/bin/hidpi-auto.sh
cat > ~/.config/autostart/hidpi-auto.desktop <<D
[Desktop Entry]
Type=Application
Name=HiDPI auto (Retina)
Exec=$HOME/.local/bin/hidpi-auto.sh
X-GNOME-Autostart-enabled=true
D
touch ~/.xsessionrc; sed -i "/$BEGIN/,/$END/d" ~/.xsessionrc
cat >> ~/.xsessionrc <<X
$BEGIN
# The VM is meant for Fusion in Retina mode (2880x1800): Qt needs an explicit factor of 2.
export QT_SCALE_FACTOR=2 QT_AUTO_SCREEN_SCALE_FACTOR=0
$END
X
echo "Display installed. On the Mac: VM Settings > Display > tick 'Use full resolution for Retina display', then go full screen. Log out and back in."

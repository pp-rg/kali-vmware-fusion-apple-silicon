#!/usr/bin/env bash
# VM performance: compressed swap (zram), useless session autostarts, snappy Xfce panel.
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
mkdir -p ~/.config/autostart ~/.local/lib ~/.local/src ~/.local/bin

echo "== 1. zram (compressed swap in RAM, higher priority than the disk swap)"
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y zram-tools
[[ -e /etc/default/zramswap.bak-orig ]] || sudo cp -a /etc/default/zramswap /etc/default/zramswap.bak-orig
sudo sed -i -e 's/^#\?ALGO=.*/ALGO=zstd/' -e 's/^#\?PERCENT=.*/PERCENT=60/' -e 's/^#\?PRIORITY=.*/PRIORITY=100/' /etc/default/zramswap
sudo tee /etc/sysctl.d/99-vm-tuning.conf >/dev/null <<'S'
# compressed swap in RAM (zram): swapping early costs no disk I/O
vm.swappiness = 100
vm.page-cluster = 0
S
sudo sysctl --system >/dev/null
sudo systemctl enable zramswap.service
sudo systemctl restart zramswap.service

echo "== 2. session autostarts that are useless in a VM (reversible: Hidden=true overrides)"
for n in blueman geoclue-demo-agent kali-vboxclient onboard-autostart orca-autostart print-applet xiccd xcape-super-key-bind org.gnome.SettingsDaemon.DiskUtilityNotify; do
  [[ -f /etc/xdg/autostart/$n.desktop ]] || continue
  printf '[Desktop Entry]\nType=Application\nName=%s (disabled)\nHidden=true\n' "$n" > ~/.config/autostart/$n.desktop
done
sudo systemctl disable ModemManager.service 2>/dev/null || true

echo "== 3. window switcher: no thumbnails (heavy to draw at 2880x1800)"
xfconf-query -c xfwm4 -p /general/cycle_preview -n -t bool -s false 2>/dev/null || true
xfconf-query -c xfwm4 -p /general/cycle_draw_frame -n -t bool -s false 2>/dev/null || true

echo "== 4. Xfce panel: fast auto-hide"
# Xfce 4.20 hard-codes the auto-hide delays (1.4 s to hide). Shorten them for the xfce4-panel process only.
command -v gcc >/dev/null || sudo apt-get install -y gcc libc6-dev
install -m644 "$HERE/panel-autohide-fast.c" ~/.local/src/panel-autohide-fast.c
gcc -shared -fPIC -O2 -o ~/.local/lib/panel-autohide-fast.so ~/.local/src/panel-autohide-fast.c -ldl
cat > ~/.local/bin/xfce4-panel <<'W'
#!/bin/sh
# Wrapper: run xfce4-panel with shortened auto-hide delays. Delete this file to get the stock behaviour back.
LD_PRELOAD="$HOME/.local/lib/panel-autohide-fast.so${LD_PRELOAD:+:$LD_PRELOAD}" exec /usr/bin/xfce4-panel "$@"
W
chmod +x ~/.local/bin/xfce4-panel
xfconf-query -c xfce4-panel -p /panels/panel-1/autohide-behavior -n -t uint -s 2 2>/dev/null || true   # 2 = always auto-hide
echo "Done. Log out and back in (or reboot). Biggest win remains on the Mac side: give the VM enough RAM."

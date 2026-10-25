#!/usr/bin/env bash
set -uo pipefail
sudo systemctl disable --now zramswap.service 2>/dev/null
sudo rm -f /etc/sysctl.d/99-vm-tuning.conf
[[ -e /etc/default/zramswap.bak-orig ]] && sudo cp -a /etc/default/zramswap.bak-orig /etc/default/zramswap
for n in blueman geoclue-demo-agent kali-vboxclient onboard-autostart orca-autostart print-applet xiccd xcape-super-key-bind org.gnome.SettingsDaemon.DiskUtilityNotify; do
  grep -q 'Hidden=true' ~/.config/autostart/$n.desktop 2>/dev/null && rm -f ~/.config/autostart/$n.desktop
done
sudo systemctl enable ModemManager.service 2>/dev/null
xfconf-query -c xfwm4 -p /general/cycle_preview -s true 2>/dev/null
xfconf-query -c xfwm4 -p /general/cycle_draw_frame -s true 2>/dev/null
rm -f ~/.local/bin/xfce4-panel ~/.local/lib/panel-autohide-fast.so ~/.local/src/panel-autohide-fast.c
echo "Performance tweaks removed."

#!/bin/bash
# Switch Xfce to 2x (Retina) when the VM runs at a high resolution, back to 1x otherwise.
# GTK/Firefox: scale factor 2 with DPI 96 (do not double it with a 192 DPI). Qt: QT_SCALE_FACTOR (see ~/.xsessionrc).
apply() {
  local w=$1 s=1 cur=24 theme=Kali-Dark
  (( w >= 2560 )) && s=2 cur=48 theme=Kali-Dark-xHiDPI-square
  xfconf-query -c xsettings -p /Gdk/WindowScalingFactor -n -t int -s $s
  xfconf-query -c xsettings -p /Xft/DPI -n -t int -s 96
  xfconf-query -c xsettings -p /Gtk/CursorThemeSize -n -t int -s $cur
  xfconf-query -c xfwm4 -p /general/theme -n -t string -s $theme
  echo "Xft.dpi: 96" | xrdb -merge
}
last=""
while sleep 2; do
  w=$(xrandr 2>/dev/null | sed -n 's/^Screen 0:.*current \([0-9]*\) x.*/\1/p')
  [[ -n $w && $w != "$last" ]] && { apply "$w"; last=$w; }
done

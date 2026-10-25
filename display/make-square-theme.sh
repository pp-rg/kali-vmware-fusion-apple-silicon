#!/usr/bin/env bash
# Make a square-corner copy of an xfwm4 window theme (default: Kali-Dark-xHiDPI). Needs ImageMagick.
# Usage: make-square-theme.sh [source_theme_dir] [destination_dir]
set -euo pipefail
SRC=${1:-/usr/share/themes/Kali-Dark-xHiDPI}
DST=${2:-$HOME/.themes/$(basename "$SRC")-square}
[[ -d $SRC/xfwm4 ]] || { echo "theme not found: $SRC"; exit 1; }
command -v convert >/dev/null || sudo apt-get install -y imagemagick
rm -rf "$DST"; mkdir -p "$(dirname "$DST")"; cp -r "$SRC" "$DST"; cd "$DST/xfwm4"
for st in active inactive; do
  # top corners: stretch the title bar end pieces; bottom corners: side border extended + bottom strip on top
  convert title-1-$st.png -filter point -resize 12x62! top-left-$st.png
  convert title-5-$st.png -filter point -resize 12x62! top-right-$st.png
  convert left-$st.png  \( left-$st.png  -gravity east -crop 1x32+0+0 +repage -filter point -resize 22x32! \) +append bl-base.png
  convert right-$st.png \( right-$st.png -gravity west -crop 1x32+0+0 +repage -filter point -resize 22x32! \) -swap 0,1 +append br-base.png
  convert bl-base.png bottom-$st.png -geometry +0+22 -composite bottom-left-$st.png
  convert br-base.png bottom-$st.png -geometry +0+22 -composite bottom-right-$st.png
  for f in top-left top-right bottom-left bottom-right; do mogrify +repage $f-$st.png; done
done
rm -f bl-base.png br-base.png
echo "theme created: $DST"

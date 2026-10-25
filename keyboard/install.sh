#!/usr/bin/env bash
# Mac keyboard behaviour on Linux: keyd (Option/Cmd) + XKB Mac layout + per-app rules + shell/tmux bindings. Idempotent.
#
# Usage: ./install.sh [--layout CODE] [--variant NAME] [--keep-layout] [--swap-iso] [--root]
#   --layout CODE    keyboard layout: fr, us, de, gb, es, it, se, ... (default: the layout currently in use)
#   --variant NAME   XKB variant (default: "mac" when the layout has one)
#   --keep-layout    do not change the system layout, only add the Mac bindings
#   --swap-iso       swap the `grave` and `102nd` keys (some Apple ISO keyboards send @# and <> crossed; see README)
#   --root           also install the shell bindings for root
#   --list-layouts   list layouts that have a Mac variant
#   --dry-run        resolve the layout and print the generated per-app rules, change nothing
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd); CFG=$HERE/config
LAYOUT=""; VARIANT=""; KEEP=0; SWAP=0; ROOT=0; DRY=0; VSET=0
while [[ $# -gt 0 ]]; do case $1 in
  --layout) LAYOUT=${2:?}; shift;; --variant) VARIANT=${2-}; VSET=1; shift;; --keep-layout) KEEP=1;;
  --swap-iso) SWAP=1;; --root) ROOT=1;;
  --list-layouts) find /usr/share/X11/xkb/symbols -maxdepth 1 -type f -exec grep -l 'xkb_symbols "mac"' {} + | xargs -n1 basename | sort -u | tr '\n' ' '; echo; exit 0;;
  --dry-run) DRY=1;;
  -h|--help) sed -n 2,12p "$0"; exit 0;; *) echo "unknown option: $1"; exit 1;; esac; shift; done
DATE=$(date +%F)
BEGIN='# >>> mac-keyboard >>>'; END='# <<< mac-keyboard <<<'
SRC=$HOME/.cache/mac-keyboard/keyd-src
[[ $EUID -ne 0 ]] || { echo "Do not run as root."; exit 1; }
[[ "${XDG_SESSION_TYPE:-x11}" != wayland ]] || echo "WARNING: Wayland session, the per-app mapper may not work. Use an X11 session."
command -v setxkbmap >/dev/null && command -v xkbcomp >/dev/null || sudo apt-get install -y x11-xkb-utils xkb-data

# --- layout selection -------------------------------------------------------------------------------------------
if [[ -z $LAYOUT ]]; then LAYOUT=$(setxkbmap -query 2>/dev/null | awk '/^layout:/{print $2}' | cut -d, -f1); fi
[[ -n $LAYOUT ]] || { echo "Cannot detect the current layout: pass --layout CODE."; exit 1; }
SYM=/usr/share/X11/xkb/symbols/$LAYOUT
[[ -f $SYM ]] || { echo "Unknown layout '$LAYOUT' (see --list-layouts)."; exit 1; }
if [[ -z $VARIANT && $VSET -eq 0 ]]; then
  if grep -q 'xkb_symbols "mac"' "$SYM"; then VARIANT=mac
  else
    echo "Layout '$LAYOUT' has no 'mac' variant. Variants mentioning mac: $(grep -oE 'xkb_symbols "[A-Za-z_]*[Mm]ac[A-Za-z_]*"' "$SYM" | cut -d'"' -f2 | tr '\n' ' ')"
    echo "Pass --variant NAME, or --variant '' to use the plain layout."; exit 1
  fi
fi
echo "Layout: $LAYOUT${VARIANT:+ ($VARIANT)}"
[[ $DRY -eq 0 ]] || { python3 "$HERE/gen-app-conf.py" "$LAYOUT" "$VARIANT"; exit 0; }

backup() { # one backup, before the first modification only
  local f=$1 s=${2:-}
  if $s test -e "$f" && ! ls "$f".bak-* >/dev/null 2>&1; then $s cp -a "$f" "$f.bak-$DATE"; echo "backup $f.bak-$DATE"; fi
}
add_block() { # file block [sudo]: (re)write the delimited block, never duplicated
  local f=$1 b=$2 s=${3:-}
  backup "$f" "$s"; $s touch "$f"
  $s sed -i "/$BEGIN/,/$END/d" "$f"
  $s sh -c "[ -s '$f' ] && [ -n \"\$(tail -c1 '$f')\" ] && echo >> '$f'; cat '$b' >> '$f'"
}

echo "== 1. keyd"
if ! command -v keyd-application-mapper >/dev/null; then
  sudo apt-get install -y python3-xlib build-essential git
  # the distro package may not ship the mapper: build from source
  sudo apt-get remove -y keyd || true
  if [[ ! -d $SRC ]]; then mkdir -p "$(dirname "$SRC")"; git clone https://github.com/rvaiya/keyd "$SRC"; fi
  make -C "$SRC"; sudo make -C "$SRC" install
fi
sudo apt-get install -y python3-xlib >/dev/null
getent group keyd >/dev/null || sudo groupadd keyd
id -nG | grep -qw keyd || sudo usermod -aG keyd "$USER"

echo "== 2. keyd configuration"
sudo mkdir -p /etc/keyd
backup /etc/keyd/default.conf sudo
T=$(mktemp); cp "$CFG/default.conf" "$T"
if [[ $SWAP -eq 1 ]]; then sed -i 's/^rightmeta = layer(cmd)$/&\n# swap: some Apple ISO keyboards send @# and <> crossed\ngrave = 102nd\n102nd = grave/' "$T"; fi
sudo install -m644 "$T" /etc/keyd/default.conf; rm -f "$T"
sudo /usr/local/bin/keyd check /etc/keyd/default.conf
mkdir -p ~/.config/keyd ~/.config/autostart ~/.local/bin
# patched mapper: no rule reset on every window-title change (a terminal title changes constantly)
install -m755 "$HERE/bin/keyd-application-mapper" ~/.local/bin/keyd-application-mapper
# per-app rules, resolved from the real XKB layout
python3 "$HERE/gen-app-conf.py" "$LAYOUT" "$VARIANT" > ~/.config/keyd/app.conf
cat > ~/.config/autostart/keyd-application-mapper.desktop <<D
[Desktop Entry]
Type=Application
Name=keyd application mapper
Exec=$HOME/.local/bin/keyd-application-mapper -d
X-GNOME-Autostart-enabled=true
D

echo "== 3. XKB layout"
if [[ $KEEP -eq 0 ]]; then
  backup /etc/default/keyboard sudo
  if ! sudo localectl set-x11-keymap "$LAYOUT" pc105 "$VARIANT" lv3:ralt_switch 2>/dev/null; then
    # fallback (polkit refuses without an interactive session): same result, direct write
    sudo sed -i -e 's/^XKBMODEL=.*/XKBMODEL="pc105"/' -e "s/^XKBLAYOUT=.*/XKBLAYOUT=\"$LAYOUT\"/" \
      -e "s/^XKBVARIANT=.*/XKBVARIANT=\"$VARIANT\"/" -e 's/^XKBOPTIONS=.*/XKBOPTIONS="lv3:ralt_switch"/' /etc/default/keyboard
  fi
  if [[ -n "${DISPLAY:-}" ]]; then setxkbmap -model pc105 -layout "$LAYOUT" ${VARIANT:+-variant "$VARIANT"} -option -option lv3:ralt_switch || true; fi
else echo "kept the current layout"; fi

echo "== 4. shells and tmux"
add_block ~/.zshrc "$CFG/zshrc.block"
add_block ~/.inputrc "$CFG/inputrc.block"
add_block ~/.tmux.conf "$CFG/tmux.block"
if grep -vE "^\s*#" ~/.tmux.conf | sed "/$BEGIN/,/$END/d" | grep -nE '(^|[ "])(M-|Meta|A-)' ; then
  echo "WARNING: tmux Meta/Alt bindings above may conflict with the Option shortcuts. Nothing was changed."
fi
if [[ $ROOT -eq 1 ]]; then
  add_block /root/.zshrc "$CFG/zshrc.block" sudo; add_block /root/.inputrc "$CFG/inputrc.block" sudo; add_block /root/.tmux.conf "$CFG/tmux.block" sudo
  echo "root shell bindings installed"
fi

echo "== 5. activation"
sudo systemctl enable keyd
sudo systemctl restart keyd
if id -nG | grep -qw keyd; then pkill -f '^/usr/bin/python3 .*keyd-application-mapper' || true; ~/.local/bin/keyd-application-mapper -d || true
else echo "The keyd group applies at next login (needed by the mapper): log out and back in."; fi
echo "Done. Emergency exit if the keyboard misbehaves: sudo systemctl stop keyd"

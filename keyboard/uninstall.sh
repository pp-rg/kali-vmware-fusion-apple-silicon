#!/usr/bin/env bash
# Back to the initial state. Backups (*.bak-*) are kept.
set -uo pipefail
BEGIN='# >>> mac-keyboard >>>'; END='# <<< mac-keyboard <<<'
SRC=$HOME/.cache/mac-keyboard/keyd-src
sudo systemctl disable --now keyd 2>/dev/null
pkill -f '^/usr/bin/python3 .*keyd-application-mapper' 2>/dev/null
rm -f ~/.local/bin/keyd-application-mapper ~/.config/autostart/keyd-application-mapper.desktop ~/.config/keyd/app.conf
rmdir ~/.config/keyd 2>/dev/null
sudo rm -f /etc/keyd/default.conf; sudo rmdir /etc/keyd 2>/dev/null
for f in ~/.zshrc ~/.inputrc ~/.tmux.conf; do
  [[ -e $f ]] || continue
  sed -i "/$BEGIN/,/$END/d" "$f"
  [[ -s $f ]] || { b=$(ls "$f".bak-* 2>/dev/null | head -1); [[ -n $b ]] || rm -f "$f"; }
done
for f in /root/.zshrc /root/.inputrc /root/.tmux.conf; do sudo test -e $f && sudo sed -i "/$BEGIN/,/$END/d" $f; done
kb=$(ls /etc/default/keyboard.bak-* 2>/dev/null | head -1)
if [[ -n $kb ]]; then
  sudo cp -a "$kb" /etc/default/keyboard
  . "$kb"
  [[ -z "${DISPLAY:-}" ]] || setxkbmap -model "$XKBMODEL" -layout "$XKBLAYOUT" -variant "$XKBVARIANT" -option "$XKBOPTIONS" || true
fi
if [[ -d $SRC ]]; then sudo make -C "$SRC" uninstall; rm -rf ~/.cache/mac-keyboard; fi
sudo gpasswd -d "$USER" keyd 2>/dev/null
echo "Uninstalled. Backups *.bak-* were kept."

# Details

## Keyboard: from key to application

1. **Fusion** sends raw PC scancodes (Key Mappings and Mac host shortcuts must be off).
2. **keyd** (`/etc/keyd/default.conf`): Option -> AltGr layer + edit keys; Cmd -> Ctrl layer; Cmd+Tab holds Alt while Cmd is held.
3. **XKB**: layout variant `mac`, option `lv3:ralt_switch` only (left Alt stays a real Alt).
4. **keyd-application-mapper** (`~/.config/keyd/app.conf`, generated): `[*]` rules for every window, plus one section per terminal class.
5. **zsh / readline / tmux**: bindings for the sequences emitted (`keyboard/config/*.block`, between `# >>> mac-keyboard >>>` markers).

keyd names keys by **QWERTY position** (on AZERTY, the key labelled W is `z`). `keyboard/gen-app-conf.py LAYOUT VARIANT` compiles the real XKB keymap (`setxkbmap -print | xkbcomp`) and resolves each letter, digit, `+`, `=` to its key and Shift state, so one generator serves AZERTY, QWERTY, QWERTZ... Example: Cmd+digit is `A-1` on QWERTY, `A-S-1` on AZERTY (digits need Shift). `fr:mac` output was checked against the hand-written rules (identical); `us gb de it se no dk pt nl` generate without error. Preview with `./keyboard/install.sh --layout X --dry-run`.

Safety: the config is checked with `keyd check` before activation; emergency exit: `sudo systemctl stop keyd`. Test rule changes on a snapshot: one `swapm` variant crashed keyd during development.

## Display

Fusion in Retina mode gives the guest 2880x1800. `display/hidpi-auto.sh` (autostart, polls `xrandr` every 2 s) applies, at width >= 2560: GTK scale 2 with **DPI 96** (192 would make text 4x), cursor 48, window theme `<theme>-xHiDPI-square`. Qt ignores the GTK scale: `QT_SCALE_FACTOR=2` comes from `~/.xsessionrc` (read at login). The stock `Kali-Dark` window theme is not HiDPI; `make-square-theme.sh` rebuilds the corner images of the `-xHiDPI` variant without transparency.

## Performance (measured on the original VM: 2.9 GB RAM, 4 cores, M1)

| Finding | Change | Result |
| --- | --- | --- |
| Disk swap 99 % full, constant swapping | zram (zstd, 60 % of RAM) + `vm.swappiness=100` | ~520 MB available instead of 350, no swap traffic at idle. The real fix is enough RAM. |
| Mapper walked every X window per event and reset rules on each title change | patched copy (`keyboard/bin`) | 6-8 % CPU -> ~0 %; Cmd+Shift+Tab 240-370 ms -> 35-185 ms |
| Xfce 4.20 hard-codes the panel auto-hide delays (1.4 s) | `LD_PRELOAD` shim for `xfce4-panel` only | hide 1.8 s -> ~0.15 s |
| Window switcher thumbnails, unused autostarts | switched off | less repaint, ~100 MB |
| Cmd+digit tab switch | measured only | 0.12-0.16 s in a normal terminal, ~0.6 s when the target tab redraws the whole screen (software Qt at 2880x1800), not a RAM issue |
| Boot: ~32 s in `udev` on Fusion's virtual devices | none | no guest-side fix found |

## Troubleshooting

- `sudo keyd monitor`: keys seen by keyd and what it emits. `xev -event keyboard`: keysyms seen by X11. `cat -v`: bytes seen by the shell.
- Terminal shortcuts do nothing: is the mapper running (`pgrep -af keyd-application-mapper`)? It needs the `keyd` group: log out and back in once.
- A terminal is not covered: `keyd-application-mapper -v` prints its window class; add it to `TERMINALS` in `keyboard/gen-app-conf.py`, re-run the installer.
- Blurry screen: Retina option off or not full screen. Tiny text in Qt apps: log in again.
- Panel misbehaves: delete `~/.local/bin/xfce4-panel` for the stock panel.
- `pkill -f pattern` kills its own shell if the pattern is in its command line: anchor it or use `pgrep -x` + `kill`.

Credits: `keyboard/bin/keyd-application-mapper` derives from [keyd](https://github.com/rvaiya/keyd) (MIT, Raheman Vaiya).

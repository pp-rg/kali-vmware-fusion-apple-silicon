#!/usr/bin/env bash
# Kali Linux (ARM64, Xfce/X11) in VMware Fusion on an Apple Silicon Mac: Mac keyboard + Retina display + performance.
# Usage: ./install.sh [--layout CODE] [--variant NAME] [--keep-layout] [--swap-iso] [--root]
#                     [--no-keyboard] [--no-display] [--no-perf]
# Keyboard options are explained in keyboard/install.sh --help.
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
KB=1 DISP=1 PERF=1 KBARGS=()
while [[ $# -gt 0 ]]; do case $1 in
  --no-keyboard) KB=0;; --no-display) DISP=0;; --no-perf) PERF=0;;
  --layout|--variant) KBARGS+=("$1" "${2-}"); shift;;
  --keep-layout|--swap-iso|--root|--dry-run) KBARGS+=("$1");;
  -h|--help) sed -n 2,5p "$0"; exit 0;; *) echo "unknown option: $1"; exit 1;; esac; shift; done
[[ $EUID -ne 0 ]] || { echo "Do not run as root (sudo is called when needed)."; exit 1; }
[[ $KB   -eq 0 ]] || bash "$HERE/keyboard/install.sh" "${KBARGS[@]}"
[[ $DISP -eq 0 ]] || bash "$HERE/display/install.sh"
[[ $PERF -eq 0 ]] || bash "$HERE/perf/install.sh"
echo; echo "Done. Log out and back in (keyd group, Qt scale factor) or reboot."

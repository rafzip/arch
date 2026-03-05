#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

link() {
  local src="$1"
  local dst="$2"
  local src_real
  local dst_real

  src_real="$(realpath -m "$src")"
  dst_real="$(realpath -m "$dst")"

  if [ "$src_real" = "$dst_real" ]; then
    echo "Skipping self-link: $dst"
    return 0
  fi

  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    echo "Backing up existing: $dst -> $dst.bak"
    mv "$dst" "$dst.bak"
  fi
  ln -s "$src" "$dst"
  echo "Linked: $dst -> $src"
}

chmod +x "$ROOT/.config/hypr/scripts/"*.sh 2>/dev/null || true
chmod +x "$ROOT/.config/waybar/scripts/"*.sh 2>/dev/null || true

link "$ROOT/.zshrc" "$HOME/.zshrc"

link "$ROOT/.config/hypr"   "$HOME/.config/hypr"
link "$ROOT/.config/waybar" "$HOME/.config/waybar"
link "$ROOT/.config/swaync" "$HOME/.config/swaync"
link "$ROOT/.config/wofi"   "$HOME/.config/wofi"
link "$ROOT/.config/kitty"  "$HOME/.config/kitty"
link "$ROOT/.config/fastfetch"  "$HOME/.config/fastfetch"
link "$ROOT/.config/cava"  "$HOME/.config/cava"
link "$ROOT/.config/wlogout"  "$HOME/.config/wlogout"
link "$ROOT/.wallpapers" "$HOME/.wallpapers"

replace_zshrc="${DOTS_REPLACE_ZSHRC:-ask}"
should_replace=0

case "$replace_zshrc" in
  yes|YES|y|Y|1|true|TRUE)
    should_replace=1
    ;;
  no|NO|n|N|0|false|FALSE)
    should_replace=0
    ;;
  ask|ASK|"")
    if [[ -t 0 ]]; then
      read -p "Replace old .zshrc? (y/n) " -n 1 -r
      echo
      [[ $REPLY =~ ^[Yy]$ ]] && should_replace=1
    fi
    ;;
  *)
    echo "Unknown DOTS_REPLACE_ZSHRC value '$replace_zshrc', defaulting to 'no'."
    ;;
esac

if [[ "$should_replace" -eq 1 ]]; then
  rm -f "$HOME/.zshrc"
  ln -s "$ROOT/.zshrc" "$HOME/.zshrc"
fi

echo "Done. Log out and start Hyprland."

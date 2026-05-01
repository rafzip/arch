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

link "$ROOT/.config/hypr"   "$HOME/.config/hypr"
link "$ROOT/.config/waybar" "$HOME/.config/waybar"
link "$ROOT/.config/swaync" "$HOME/.config/swaync"
link "$ROOT/.config/wofi"   "$HOME/.config/wofi"
link "$ROOT/.config/kitty"  "$HOME/.config/kitty"
link "$ROOT/.config/fastfetch"  "$HOME/.config/fastfetch"
link "$ROOT/.config/cava"  "$HOME/.config/cava"
link "$ROOT/.config/wlogout"  "$HOME/.config/wlogout"

if [ -d /etc/ly ]; then
  echo "Copying ly/config.ini -> /etc/ly/config.ini (requires sudo)"
  sudo cp "$ROOT/ly/config.ini" /etc/ly/config.ini
fi

echo "Done. Log out and start Hyprland."

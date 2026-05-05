#!/usr/bin/env bash
# install-pkgs.sh — install packages required by these dotfiles on Artix Linux
# Excludes: audio stack (pipewire, wireplumber, etc.)
# Requires: an AUR helper (paru or yay)

set -euo pipefail

msg()  { printf '\n\e[1;34m==> \e[0m%s\n' "$*"; }
warn() { printf '\e[1;33m:: \e[0m%s\n' "$*"; }
die()  { printf '\e[1;31mERROR:\e[0m %s\n' "$*" >&2; exit 1; }

# Detect AUR helper
if   command -v paru &>/dev/null; then AUR=paru
elif command -v yay  &>/dev/null; then AUR=yay
else die "No AUR helper found. Install paru or yay first."
fi
msg "AUR helper: $AUR"

# Detect init system
if   [ -d /run/runit ];                then INIT=runit
elif [ -d /run/openrc ];               then INIT=openrc
elif command -v s6-rc    &>/dev/null;  then INIT=s6
elif command -v dinitctl &>/dev/null;  then INIT=dinit
else
  warn "Could not detect init system — skipping init-specific service packages."
  INIT=unknown
fi
msg "Init system: $INIT"

# ---------------------------------------------------------------------------
# Official repo packages
# ---------------------------------------------------------------------------
PACMAN_PKGS=(
  # Hyprland compositor + ecosystem
  hyprland
  hyprlock
  hypridle
  hyprsunset
  hyprpicker
  hyprpolkitagent

  # Wayland utilities
  waybar
  wofi
  wlogout
  wl-clipboard
  grim
  slurp
  cliphist
  brightnessctl

  # Terminal
  kitty

  # Notifications
  swaync
  libnotify

  # Network
  networkmanager
  network-manager-applet

  # Power management
  power-profiles-daemon
  upower

  # XDG portals
  xdg-desktop-portal
  xdg-desktop-portal-hyprland
  xdg-desktop-portal-gtk

  # Fonts
  ttf-jetbrains-mono-nerd
  ttf-meslo-nerd

  # Visualizer
  cava

  # Utilities
  fastfetch
  pacman-contrib
)

# ---------------------------------------------------------------------------
# AUR packages
# ---------------------------------------------------------------------------
AUR_PKGS=(
  awww              # animated wallpaper daemon (awww-daemon / awww img)
  pyprland          # pypr scratchpad and plugin system
  bibata-cursor-theme
  zen-browser-bin
  obsidian
  ly                # TUI login manager
)

# ---------------------------------------------------------------------------
# Init-specific service packages (from Artix repos)
# ---------------------------------------------------------------------------
case "$INIT" in
  openrc) SVC_PKGS=(networkmanager-openrc upower-openrc ly-openrc power-profiles-daemon-openrc) ;;
  runit)  SVC_PKGS=(networkmanager-runit  upower-runit  ly-runit  power-profiles-daemon-runit)  ;;
  s6)     SVC_PKGS=(networkmanager-s6     upower-s6     ly-s6     power-profiles-daemon-s6)     ;;
  dinit)  SVC_PKGS=(networkmanager-dinit                ly-dinit  power-profiles-daemon-dinit)  ;;
  *)      SVC_PKGS=() ;;
esac

# ---------------------------------------------------------------------------
# Optional: NVIDIA drivers
# ---------------------------------------------------------------------------
read -rp $'\n\e[1;33m::\e[0m Install NVIDIA drivers (nvidia-dkms + nvidia-utils)? [y/N] ' _yn
case "${_yn,,}" in
  y|yes) PACMAN_PKGS+=(nvidia-dkms nvidia-utils) ;;
  *)     msg "Skipping NVIDIA packages." ;;
esac

# ---------------------------------------------------------------------------
# Install
# ---------------------------------------------------------------------------
msg "Installing official packages..."
sudo pacman -S --needed "${PACMAN_PKGS[@]}"

if [ "${#SVC_PKGS[@]}" -gt 0 ]; then
  msg "Installing $INIT service packages..."
  sudo pacman -S --needed "${SVC_PKGS[@]}"
fi

msg "Installing AUR packages via $AUR..."
"$AUR" -S --needed "${AUR_PKGS[@]}"

msg "Done. Run ./install-dots.sh to symlink configs, then log out and start Hyprland."

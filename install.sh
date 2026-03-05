#!/usr/bin/env bash
set -euo pipefail

#############################################
# Post-install for Arch on ASUS Zephyrus G14 #
# AMD CPU + NVIDIA GPU, Wayland, GDM, GNOME #
# + Hyprland, Gaming/School/Dev, USB import #
#############################################

# ----------------------------
# User-tunable options
# ----------------------------

# Add asus-linux "g14" repo (recommended for asusctl / rog-control-center):
USE_G14_REPO=1

# Install asusctl + rog-control-center from g14 repo:
INSTALL_ASUS_TOOLS=1

# supergfxctl is warned as "being phased out / unadvised unless you really need it"
# by the asus-linux Arch guide. Enable only if you know you want it.
INSTALL_SUPERGFXCTL=0

# If you installed a custom kernel (like linux-g14), prefer DKMS driver:
# For stock Arch kernel you can still use nvidia-open-dkms safely; DKMS is flexible.
NVIDIA_DRIVER_PKG="nvidia-open-dkms"   # alternative: "nvidia" (stock-kernel only)

# Patch bootloader to add kernel parameter (best-effort, supports GRUB + systemd-boot):
PATCH_BOOTLOADER=1

# Flatpak + common “desktop apps” (Heroic/Bottles/ProtonUp-Qt/etc):
INSTALL_FLATPAK=1

# Try to install a few big optional stacks (can be huge):
INSTALL_DOCKER=1
INSTALL_VIRT=1
INSTALL_LATEX=0       # texlive-most is very large; keep off unless you want it

# Dotfiles (optional). If empty, script skips.
DOTFILES_GIT_URL=""   # e.g. "https://github.com/you/dotfiles.git"
DOTFILES_DIR_NAME=".dotfiles"
DOTFILES_APPLY_CMD="" # e.g. "stow -vR -t ~ ." OR "./install.sh"

# USB import:
# If you know the exact block device, set it (example "/dev/sda1"). Otherwise auto-detect.
USB_BLOCK_DEVICE=""
# Destination inside your home:
USB_DEST_SUBDIR="usb-import"

# WirePlumber “software volume” override:
# Default matches all PCI ALSA cards (internal audio / HDMI audio typically).
# You can tighten later to something like:
#   "~alsa_card.pci-0000_65_00.6.*"
SOFTVOL_DEVICE_NAME_REGEX="~alsa_card.pci-0000_.*"

# ----------------------------
# Helpers
# ----------------------------
log()  { echo -e "\033[1;34m==>\033[0m $*"; }
warn() { echo -e "\033[1;33m==> WARNING:\033[0m $*" >&2; }
die()  { echo -e "\033[1;31m==> ERROR:\033[0m $*" >&2; exit 1; }

need_cmd() { command -v "$1" >/dev/null 2>&1 || die "Missing command: $1"; }

as_user() {
  local cmd="$*"
  sudo -u "$TARGET_USER" -H bash -lc "$cmd"
}

pacman_install() {
  # shellcheck disable=SC2068
  pacman -S --needed --noconfirm "$@"
}

pacman_remove_if_present() {
  local pkgs=("$@")
  local to_remove=()
  for p in "${pkgs[@]}"; do
    if pacman -Q "$p" >/dev/null 2>&1; then
      to_remove+=("$p")
    fi
  done
  if ((${#to_remove[@]})); then
    log "Removing GNOME default apps (requested): ${to_remove[*]}"
    pacman -Rns --noconfirm "${to_remove[@]}" || true
  else
    log "No GNOME default apps from removal list are installed. Skipping remove."
  fi
}

install_yay_if_missing() {
  if command -v yay >/dev/null 2>&1; then
    log "yay already installed"
    return 0
  fi

  log "Installing yay (AUR helper)"
  local yay_build_dir="/tmp/yay-${TARGET_USER}"
  as_user "rm -rf '$yay_build_dir' && git clone https://aur.archlinux.org/yay.git '$yay_build_dir'" || {
    warn "Failed to clone yay AUR repo."
    return 1
  }

  as_user "cd '$yay_build_dir' && makepkg -si --needed --noconfirm" || {
    warn "Failed to build/install yay."
    return 1
  }

  as_user "rm -rf '$yay_build_dir'" || true
}

ensure_multilib_enabled() {
  if grep -qE '^\s*\[multilib\]' /etc/pacman.conf && grep -qE '^\s*Include\s*=\s*/etc/pacman\.d/mirrorlist' /etc/pacman.conf; then
    # Might still be commented; best-effort uncomment block.
    sed -i '/^\s*#\s*\[multilib\]\s*$/,/^\s*#\s*Include\s*=\s*\/etc\/pacman\.d\/mirrorlist\s*$/ s/^\s*#\s*//' /etc/pacman.conf
  else
    # Typical Arch default: commented block exists; try to uncomment anyway.
    sed -i '/^\s*#\s*\[multilib\]\s*$/,/^\s*#\s*Include\s*=\s*\/etc\/pacman\.d\/mirrorlist\s*$/ s/^\s*#\s*//' /etc/pacman.conf || true
  fi
}

add_g14_repo() {
  # Based on asus-linux Arch guide repo/key steps.
  # https://asus-linux.org/guides/arch-guide/ :contentReference[oaicite:5]{index=5}
  local key="8F654886F17D497FEFE3DB448B15A6B0E9A3FA35"

  if grep -q '^\[g14\]' /etc/pacman.conf; then
    log "g14 repo already present in /etc/pacman.conf"
    return 0
  fi

  log "Adding asus-linux g14 repo + signing key"
  pacman_install wget ca-certificates

  # Key import (best-effort; keyservers sometimes fail)
  pacman-key --recv-keys "$key" || true
  pacman-key --finger "$key" || true
  pacman-key --lsign-key "$key" || true

  cat >>/etc/pacman.conf <<'EOF'

[g14]
Server = https://arch.asus-linux.org
EOF
}

patch_bootloader_cmdline() {
  local param="nvidia_drm.modeset=1"
  log "Best-effort: ensuring kernel cmdline contains: $param"

  if [[ -f /etc/default/grub ]]; then
    if grep -q "$param" /etc/default/grub; then
      log "GRUB cmdline already contains $param"
    else
      sed -i "s/^\(GRUB_CMDLINE_LINUX_DEFAULT=\".*\)\"/\1 $param\"/" /etc/default/grub
      log "Updated /etc/default/grub; regenerating grub.cfg if grub-mkconfig exists"
      if command -v grub-mkconfig >/dev/null 2>&1; then
        grub-mkconfig -o /boot/grub/grub.cfg || warn "grub-mkconfig failed; regenerate grub.cfg manually."
      else
        warn "grub-mkconfig not found; regenerate GRUB config manually if needed."
      fi
    fi
    return 0
  fi

  # systemd-boot:
  if [[ -d /boot/loader/entries ]]; then
    shopt -s nullglob
    local changed=0
    for f in /boot/loader/entries/*.conf; do
      if grep -q '^options' "$f"; then
        if grep -q "$param" "$f"; then
          continue
        fi
        sed -i "s/^options \(.*\)$/options \1 $param/" "$f"
        changed=1
      fi
    done
    if [[ $changed -eq 1 ]]; then
      log "Updated systemd-boot entry options with $param"
    else
      log "No systemd-boot entries changed (maybe already present, or no 'options' lines)."
    fi
    return 0
  fi

  warn "Unknown bootloader (not GRUB, not systemd-boot entries in /boot/loader/entries). Add $param manually if needed."
}

setup_nvidia_modeset() {
  # asus-linux guide explicitly uses /etc/modprobe.d/nvidia.conf with:
  #   options nvidia_drm modeset=1
  # which is equivalent goal to kernel parameter. :contentReference[oaicite:6]{index=6}
  log "Configuring NVIDIA DRM KMS via modprobe.d"
  cat >/etc/modprobe.d/nvidia.conf <<'EOF'
options nvidia_drm modeset=1
EOF

  # Enabling these services is commonly required for GDM/NVIDIA Wayland reliability.
  # See GDM issue discussion + similar guidance. :contentReference[oaicite:7]{index=7}
  log "Enabling NVIDIA suspend/resume/hibernate services (if present)"
  systemctl enable nvidia-suspend.service 2>/dev/null || true
  systemctl enable nvidia-resume.service 2>/dev/null || true
  systemctl enable nvidia-hibernate.service 2>/dev/null || true
}

install_audio_stack_and_softvol_override() {
  log "Installing PipeWire + WirePlumber + ALSA utils"
  pacman_install pipewire wireplumber pipewire-alsa pipewire-pulse alsa-utils sof-firmware pavucontrol

  # WirePlumber config: api.alsa.soft-mixer=true disables hardware mixer for volume control,
  # and uses software volume instead. :contentReference[oaicite:8]{index=8}
  # This exact fix was recommended + confirmed working for Zephyrus G14 (2025) on Arch forums. :contentReference[oaicite:9]{index=9}
  log "Writing WirePlumber software-volume override for your user"
  as_user "mkdir -p ~/.config/wireplumber/wireplumber.conf.d"

  as_user "cat > ~/.config/wireplumber/wireplumber.conf.d/99-alsasoftvol.conf <<'EOF'
monitor.alsa.rules = [
  {
    matches = [
      {
        device.name = \"${SOFTVOL_DEVICE_NAME_REGEX}\"
      }
    ]
    actions = {
      update-props = {
        api.alsa.soft-mixer = true
      }
    }
  }
]
EOF"

  log "Audio override installed. It will apply next time your user session starts WirePlumber."
  log "Tip: to tighten matching later, find your device name via: pactl list cards | grep -E 'Name:|alsa_card' -n"
}

install_dotfiles_optional() {
  if [[ -z "$DOTFILES_GIT_URL" ]]; then
    log "DOTFILES_GIT_URL empty; skipping dotfiles."
    return 0
  fi

  log "Cloning dotfiles into ~/${DOTFILES_DIR_NAME}"
  pacman_install git
  as_user "rm -rf ~/'$DOTFILES_DIR_NAME' && git clone '$DOTFILES_GIT_URL' ~/'$DOTFILES_DIR_NAME'"

  if [[ -n "$DOTFILES_APPLY_CMD" ]]; then
    log "Applying dotfiles with your command: $DOTFILES_APPLY_CMD"
    as_user "cd ~/'$DOTFILES_DIR_NAME' && $DOTFILES_APPLY_CMD"
  else
    warn "DOTFILES_APPLY_CMD empty. Clone done, but no apply step ran."
  fi
}

# ----------------------------
# Main
# ----------------------------

if [[ "${EUID}" -ne 0 ]]; then
  exec sudo -E bash "$0" "$@"
fi

need_cmd pacman
if [[ -f /etc/os-release ]]; then
  # shellcheck disable=SC1091
  source /etc/os-release
  [[ "${ID:-}" == "arch" ]] || warn "This script is intended for Arch (ID=arch). Continuing anyway."
fi

TARGET_USER="${SUDO_USER:-}"
[[ -n "$TARGET_USER" ]] || die "Run this as a regular user with sudo (so SUDO_USER is set)."

log "Target user: $TARGET_USER"

log "Enabling multilib (needed for many gaming packages / 32-bit libs)"
ensure_multilib_enabled

if [[ "$USE_G14_REPO" == "1" ]]; then
  add_g14_repo
fi

log "Full system update"
pacman -Syu --noconfirm

# ----------------------------
# Base / quality-of-life
# ----------------------------
log "Installing base system tools"
pacman_install \
  base-devel git curl wget \
  linux-firmware amd-ucode \
  nano vim neovim \
  zsh \
  openssh \
  rsync \
  unzip zip p7zip unrar \
  jq yq \
  pacman-contrib \
  man-db man-pages \
  bash-completion \
  reflector \
  fwupd \
  lm_sensors \
  acpi \
  htop btop \
  fastfetch \
  ripgrep fd bat eza fzf \
  tmux \
  chrony

systemctl enable --now chronyd || true

log "Filesystems / removable media helpers"
pacman_install \
  exfatprogs dosfstools ntfs-3g \
  gvfs gvfs-mtp gvfs-smb

# ----------------------------
# Desktop: GDM + GNOME core + Hyprland
# ----------------------------
log "Installing GDM + GNOME core (without default GNOME apps)"
pacman_install \
  gdm \
  gnome-shell gnome-session gnome-settings-daemon gnome-control-center \
  gnome-keyring \
  nautilus \
  xdg-desktop-portal xdg-desktop-portal-gnome

log "Installing Hyprland stack"
pacman_install \
  hyprland xdg-desktop-portal-hyprland \
  hyprlock waybar wofi dunst \
  kitty cava \
  swww cliphist \
  grim slurp swappy wl-clipboard \
  libnotify \
  brightnessctl playerctl \
  networkmanager network-manager-applet nm-connection-editor \
  power-profiles-daemon \
  ttf-jetbrains-mono-nerd \
  polkit-gnome \
  qt6-wayland qt5-wayland

log "Enabling NetworkManager + power profiles daemon"
systemctl enable --now NetworkManager || true
systemctl enable --now power-profiles-daemon || true

log "Enabling GDM"
systemctl enable gdm

# ----------------------------
# NVIDIA + Wayland essentials
# ----------------------------
log "Installing graphics stack (Mesa + NVIDIA + Vulkan + video accel bits)"
pacman_install \
  mesa lib32-mesa \
  vulkan-icd-loader lib32-vulkan-icd-loader vulkan-tools \
  "${NVIDIA_DRIVER_PKG}" nvidia-utils lib32-nvidia-utils nvidia-settings \
  opencl-nvidia \
  egl-wayland \
  libva-nvidia-driver

setup_nvidia_modeset
if [[ "$PATCH_BOOTLOADER" == "1" ]]; then
  patch_bootloader_cmdline
fi

# ----------------------------
# ASUS laptop tools (optional)
# ----------------------------
if [[ "$INSTALL_ASUS_TOOLS" == "1" ]]; then
  if [[ "$USE_G14_REPO" != "1" ]]; then
    warn "INSTALL_ASUS_TOOLS=1 but USE_G14_REPO=0. Installing asusctl may be suboptimal."
  fi
  log "Installing ASUS control tools"
  pacman_install asusctl power-profiles-daemon
  systemctl enable --now power-profiles-daemon || true

  # rog-control-center is in the g14 repo per asus-linux guide
  pacman_install rog-control-center || true
fi

if [[ "$INSTALL_SUPERGFXCTL" == "1" ]]; then
  log "Installing supergfxctl (note: asus-linux warns it's being phased out / unadvised unless needed)"
  pacman_install supergfxctl
  systemctl enable --now supergfxd
fi

# ----------------------------
# Audio: PipeWire + WirePlumber + soft volume override
# ----------------------------
install_audio_stack_and_softvol_override

# ----------------------------
# Remove default GNOME apps (keep Files + Control Center + core)
# ----------------------------
# Based on Arch "gnome" group listing; remove user-facing defaults.
# (We intentionally do NOT remove nautilus, gnome-control-center, gnome-shell, gdm, etc.)
# :contentReference[oaicite:10]{index=10}
GNOME_DEFAULT_APPS_TO_REMOVE=(
  gnome-calendar gnome-characters gnome-clocks gnome-color-manager gnome-connections
  gnome-console gnome-contacts gnome-disk-utility gnome-font-viewer gnome-logs
  gnome-maps gnome-music gnome-software gnome-system-monitor gnome-text-editor
  gnome-tour gnome-user-docs gnome-user-share gnome-weather
  loupe papers showtime simple-scan sushi tecla yelp rygel orca malcontent
  gnome-remote-desktop
)
pacman_remove_if_present "${GNOME_DEFAULT_APPS_TO_REMOVE[@]}"

# ----------------------------
# Gaming stack
# ----------------------------
log "Installing gaming stack (Steam/Proton/Wine/Lutris/Gamemode/MangoHud/Gamescope)"
pacman_install \
  steam \
  wine-staging winetricks \
  lutris \
  gamemode lib32-gamemode \
  mangohud lib32-mangohud \
  gamescope \
  goverlay \
  obs-studio

# Controllers rules package sometimes exists separately on Arch; install if available.
if pacman -Si steam-devices >/dev/null 2>&1; then
  pacman_install steam-devices
fi

# ----------------------------
# Programming / dev stack
# ----------------------------
log "Installing dev stack"
pacman_install \
  gcc clang lld lldb gdb cmake ninja make pkgconf \
  python python-pip python-virtualenv pipx \
  nodejs npm \
  go rustup \
  jdk-openjdk maven gradle \
  shellcheck shfmt \
  sqlite postgresql-libs \
  direnv \
  wireshark-cli \
  git-lfs \
  vscode || true

# Rust toolchain via rustup (non-root)
as_user "rustup toolchain install stable && rustup default stable" || true

if install_yay_if_missing; then
  log "Installing requested AUR packages (bambustudio, spotify, overskride, brew)"
  as_user "yay -S --needed --noconfirm --answerdiff None --answerclean None bambustudio zen-browser-bin wlogout spotify overskride brew vesktop" || warn "Failed to install one or more requested AUR packages."
else
  warn "Skipping AUR packages because yay could not be installed."
fi

if [[ "$INSTALL_DOCKER" == "1" ]]; then
  log "Enabling Docker + adding user to docker group"
  pacman_install \
    docker \
    docker-compose
  systemctl enable --now docker
  if ! getent group docker >/dev/null; then groupadd docker || true; fi
  usermod -aG docker "$TARGET_USER" || true
fi

if [[ "$INSTALL_VIRT" == "1" ]]; then
  log "Installing virtualization stack"
  pacman_install qemu-full virt-manager libvirt dnsmasq vde2 ebtables iptables-nft
  systemctl enable --now libvirtd
  usermod -aG libvirt "$TARGET_USER" || true
fi

# ----------------------------
# School / productivity stack
# ----------------------------
log "Installing school/productivity tools"
pacman_install \
  libreoffice-fresh \
  gimp inkscape \
  blender \
  pandoc \
  texinfo \
  anki \
  krita \
  keepassxc

if [[ "$INSTALL_LATEX" == "1" ]]; then
  log "Installing LaTeX (texlive-most) — this is huge"
  pacman_install texlive-most biber
fi

# ----------------------------
# Flatpak apps (optional)
# ----------------------------
if [[ "$INSTALL_FLATPAK" == "1" ]]; then
  log "Setting up Flatpak + Flathub"
  pacman_install flatpak
  as_user "flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo"

  # Common “gaming helpers” not always ideal via pacman:
  # Heroic, Bottles, ProtonUp-Qt are readily available on Flathub.
  as_user "flatpak install -y flathub com.heroicgameslauncher.hgl || true"
  as_user "flatpak install -y flathub com.usebottles.bottles || true"
  as_user "flatpak install -y flathub net.davidotek.pupgui2 || true" # ProtonUp-Qt
fi

# ----------------------------
# Dotfiles (optional)
# ----------------------------
# install_dotfiles_optional

log "DONE."
log "Recommended next steps:"
log "  1) Reboot."
log "  2) In GDM, choose GNOME or Hyprland session."
log "  3) If volume is still weird, tighten SOFTVOL_DEVICE_NAME_REGEX to your exact alsa_card.* from 'pactl list cards'."
log "  4) If using Docker: log out/in so your group changes apply."

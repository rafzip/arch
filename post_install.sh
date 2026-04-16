#!/usr/bin/env bash
set -euo pipefail

DOTS_REPO="https://github.com/rafzip/arch.git"
DOTS_INSTALL_SCRIPT="install-dots.sh"
AUR_HELPER_REPO="https://aur.archlinux.org/yay.git"
OH_MY_ZSH_REPO="https://github.com/ohmyzsh/ohmyzsh.git"
POWERLEVEL10K_REPO="https://github.com/romkatv/powerlevel10k.git"
ZSH_AUTOSUGGESTIONS_REPO="https://github.com/zsh-users/zsh-autosuggestions.git"
ZSH_SYNTAX_HIGHLIGHTING_REPO="https://github.com/zsh-users/zsh-syntax-highlighting.git"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CURRENT_USER="${SUDO_USER:-$USER}"
HOME_DIR="$(getent passwd "$CURRENT_USER" | cut -d: -f6)"
PACKAGE_DIR="$SCRIPT_DIR/packages"

PACMAN_PKGS=()
AUR_PKGS=()
BREW_PKGS=()
FLATPAK_PKGS=()

log() {
  printf '\n==> %s\n' "$*"
}

warn() {
  printf '\n[WARN] %s\n' "$*" >&2
}

run_as_user() {
  sudo -u "$CURRENT_USER" HOME="$HOME_DIR" bash -lc "$*"
}

load_package_file() {
  local file="$1"
  local array_name="$2"
  local -n target_array="$array_name"

  target_array=()

  if [[ ! -f "$file" ]]; then
    warn "Package list not found: $file"
    return 1
  fi

  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [[ -z "$line" ]] && continue
    target_array+=("$line")
  done <"$file"
}

shell_join() {
  local out=""
  local item
  for item in "$@"; do
    printf -v item '%q' "$item"
    out+=" $item"
  done
  printf '%s' "${out# }"
}

load_package_lists() {
  log "Loading package lists"
  load_package_file "$PACKAGE_DIR/pacman.txt" PACMAN_PKGS || exit 1
  load_package_file "$PACKAGE_DIR/yay.txt" AUR_PKGS || exit 1
  load_package_file "$PACKAGE_DIR/brew.txt" BREW_PKGS || exit 1
  load_package_file "$PACKAGE_DIR/flatpak.txt" FLATPAK_PKGS || exit 1
}

require_not_root() {
  if [[ "$EUID" -eq 0 ]]; then
    echo "Run this script as your normal user, not root." >&2
    exit 1
  fi
}

check_sudo() {
  log "Checking sudo access"
  sudo -v
}

ensure_network() {
  log "Checking network connectivity"
  if curl -Is --max-time 5 https://archlinux.org >/dev/null 2>&1; then
    echo "Network already works."
    return 0
  fi

  warn "No connectivity detected. Trying to bring NetworkManager up if already installed."
  if command -v systemctl >/dev/null 2>&1; then
    sudo systemctl enable --now NetworkManager.service || true
    sleep 3
  fi

  if curl -Is --max-time 5 https://archlinux.org >/dev/null 2>&1; then
    echo "NetworkManager brought networking up."
    return 0
  fi

  cat <<'EOM'
No working network detected.

Options:
  1. Ethernet: plug it in and re-run.
  2. Wi-Fi with NetworkManager already installed:
       nmcli dev wifi list
       nmcli dev wifi connect "SSID" password "PASSWORD"
  3. Live/manual Wi-Fi with iwd:
       iwctl
       device list
       station <wlan-iface> scan
       station <wlan-iface> get-networks
       station <wlan-iface> connect "SSID"

EOM
  exit 1
}

install_base_packages() {
  log "Installing pacman packages"
  if [[ "${#PACMAN_PKGS[@]}" -eq 0 ]]; then
    echo "No pacman packages listed."
    return 0
  fi
  sudo pacman -Syu --noconfirm --needed "${PACMAN_PKGS[@]}"
  fc-cache -fv
}

setup_services() {
  log "Enabling base services"
  sudo systemctl enable --now NetworkManager.service
  sudo systemctl enable ly.service
}

setup_sudo_pwfeedback() {
  log "Enabling sudo password feedback (stars)"
  local sudoers_drop="/etc/sudoers.d/10-pwfeedback"
  echo 'Defaults pwfeedback' | sudo tee "$sudoers_drop" >/dev/null
  sudo chmod 440 "$sudoers_drop"
  sudo visudo -cf "$sudoers_drop"
}

clone_and_install_dots() {
  log "Cloning dotfiles"
  run_as_user "mkdir -p '$HOME_DIR/Code'"
  if [[ -d "$HOME_DIR/Code/arch/.git" ]]; then
    run_as_user "cd '$HOME_DIR/Code/arch' && git pull --ff-only"
  else
    run_as_user "git clone '$DOTS_REPO' '$HOME_DIR/Code/arch'"
  fi

  log "Running dotfiles installer"
  run_as_user "cd '$HOME_DIR/Code/arch' && chmod +x '$DOTS_INSTALL_SCRIPT' && ./'$DOTS_INSTALL_SCRIPT'"
}

install_yay() {
  log "Building and installing yay from AUR"
  if command -v yay >/dev/null 2>&1; then
    echo "yay already installed."
    return 0
  fi

  run_as_user "rm -rf '$HOME_DIR/.cache/yay-build/yay' && mkdir -p '$HOME_DIR/.cache/yay-build'"
  run_as_user "git clone '$AUR_HELPER_REPO' '$HOME_DIR/.cache/yay-build/yay'"
  run_as_user "cd '$HOME_DIR/.cache/yay-build/yay' && makepkg -si --noconfirm"
}

install_aur_packages() {
  log "Installing requested AUR packages"
  if [[ "${#AUR_PKGS[@]}" -eq 0 ]]; then
    echo "No yay packages listed."
    return 0
  fi
  run_as_user "yay -S --noconfirm --needed $(shell_join "${AUR_PKGS[@]}")"
}

install_or_update_git_repo() {
  local repo_url="$1"
  local target_dir="$2"

  run_as_user "mkdir -p '$(dirname "$target_dir")'"
  if run_as_user "[[ -d '$target_dir/.git' ]]"; then
    run_as_user "git -C '$target_dir' pull --ff-only"
  else
    run_as_user "rm -rf '$target_dir' && git clone --depth 1 '$repo_url' '$target_dir'"
  fi
}

setup_zsh_environment() {
  log "Installing Oh My Zsh, Powerlevel10k, and Zsh plugins"

  local custom_dir="$oh_my_zsh_dir/custom"
  local theme_dir="$custom_dir/themes/powerlevel10k"
  local autosuggestions_dir="$custom_dir/plugins/zsh-autosuggestions"
  local syntax_highlighting_dir="$custom_dir/plugins/zsh-syntax-highlighting"

  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  install_or_update_git_repo "$POWERLEVEL10K_REPO" "$theme_dir"
  install_or_update_git_repo "$ZSH_AUTOSUGGESTIONS_REPO" "$autosuggestions_dir"
  install_or_update_git_repo "$ZSH_SYNTAX_HIGHLIGHTING_REPO" "$syntax_highlighting_dir"

  local zsh_path
  zsh_path="$(command -v zsh)"
  if [[ -n "$zsh_path" ]] && [[ "$(getent passwd "$CURRENT_USER" | cut -d: -f7)" != "$zsh_path" ]]; then
    log "Setting default shell to zsh for $CURRENT_USER"
    sudo chsh -s "$zsh_path" "$CURRENT_USER"
  fi
}

setup_audio_override() {
  log "Applying PulseAudio mixer override"
  local conf="/usr/share/pulseaudio/alsa-mixer/paths/analog-output.conf.common"
  local marker="# arch-postinstall-rafzip pcm override"

  if ! sudo grep -qF "$marker" "$conf"; then
    sudo cp "$conf" "${conf}.bak.$(date +%s)"
    sudo tee -a "$conf" >/dev/null <<EOF2

$marker
[Element PCM]
volume = ignore
volume-limit = 1.0
switch = mute
EOF2
  else
    echo "Audio override already present."
  fi

  pulseaudio -k || true

  cat <<'EOM'
Audio note:
  1. Open alsamixer
  2. Set PCM as desired
  3. Run: sudo alsactl store
EOM
}

configure_nvidia_modules_and_plymouth() {
  log "Configuring mkinitcpio for NVIDIA + Plymouth"
  local mkinit="/etc/mkinitcpio.conf"

  sudo cp "$mkinit" "${mkinit}.bak.$(date +%s)"

  sudo sed -i -E 's/^MODULES=\(.*/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' "$mkinit"

  if ! sudo grep -q 'plymouth' "$mkinit"; then
    sudo sed -i -E 's/^HOOKS=\((.*) kms (.*) filesystems(.*)\)$/HOOKS=(\1 kms \2 plymouth filesystems\3)/' "$mkinit" || true
    sudo sed -i -E 's/^HOOKS=\((.*) udev (.*) filesystems(.*)\)$/HOOKS=(\1 udev \2 plymouth filesystems\3)/' "$mkinit" || true
  fi

  if ! sudo grep -q '^options nvidia_drm modeset=1' /etc/modprobe.d/nvidia.conf 2>/dev/null; then
    echo 'options nvidia_drm modeset=1' | sudo tee /etc/modprobe.d/nvidia.conf >/dev/null
  fi

  sudo mkinitcpio -P
}

configure_plymouth_theme() {
  log "Trying to set Plymouth theme to 'splash'"
  if command -v plymouth-set-default-theme >/dev/null 2>&1; then
    if plymouth-set-default-theme -l 2>/dev/null | grep -qx 'splash'; then
      sudo plymouth-set-default-theme -R splash
    else
      warn "No installed Plymouth theme named 'splash'. Leaving current/default theme in place."
      warn "Install a theme first, then run: sudo plymouth-set-default-theme -R <theme-name>"
    fi
  else
    warn "plymouth-set-default-theme not found; skipping theme switch."
  fi
}

install_homebrew() {
  log "Installing Homebrew"
  if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    echo "Homebrew already installed."
  else
    run_as_user '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  fi

  local zprofile="$HOME_DIR/.zprofile"
  local zshrc="$HOME_DIR/.zshrc"
  local brew_eval='eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'

  run_as_user "grep -qxF '$brew_eval' '$zprofile' 2>/dev/null || echo '$brew_eval' >> '$zprofile'"
  run_as_user "grep -qxF '$brew_eval' '$zshrc' 2>/dev/null || echo '$brew_eval' >> '$zshrc'"
}

install_brew_packages() {
  log "Installing Homebrew packages"
  if [[ "${#BREW_PKGS[@]}" -eq 0 ]]; then
    echo "No Homebrew packages listed."
    return 0
  fi

  run_as_user "eval \"\$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)\" && brew install $(shell_join "${BREW_PKGS[@]}")"
}

install_flatpak_packages() {
  log "Installing Flatpak packages"
  if [[ "${#FLATPAK_PKGS[@]}" -eq 0 ]]; then
    echo "No Flatpak packages listed."
    return 0
  fi

  if ! command -v flatpak >/dev/null 2>&1; then
    warn "flatpak is not installed; skipping Flatpak packages."
    return 0
  fi

  if ! flatpak remote-list | grep -qx 'flathub'; then
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  fi

  run_as_user "flatpak install -y flathub $(shell_join "${FLATPAK_PKGS[@]}")"
}

finish_message() {
  cat <<'EOM'

Done.

Recommended final checks:
  1. Reboot
  2. Confirm Ly starts
  3. Confirm Hyprland session launches
  4. Check NVIDIA modeset: cat /sys/module/nvidia_drm/parameters/modeset
  5. If needed, finish bootloader splash args and Secure Boot signing
  6. Run fc-cache -fv if apps do not immediately see new fonts

EOM
}

main() {
  require_not_root
  check_sudo
  load_package_lists
  ensure_network
  install_base_packages
  setup_services
  setup_sudo_pwfeedback
  clone_and_install_dots
  install_yay
  install_aur_packages
  setup_zsh_environment
  setup_audio_override
  configure_nvidia_modules_and_plymouth
  configure_plymouth_theme
  install_homebrew
  install_brew_packages
  install_flatpak_packages
  finish_message
  cat /sys/module/nvidia_drm/parameters/modeset
}

main "$@"

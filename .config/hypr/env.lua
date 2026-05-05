-- Adjust AQ_DRM_DEVICES if you need to force which GPU is primary.
-- Example: /dev/dri/card0:/dev/dri/card1
-- hl.env("AQ_DRM_DEVICES", "/dev/dri/card0:/dev/dri/card1")
hl.env("AQ_FORCE_LINEAR_BLIT", "0")

hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("NIXOS_OZONE_WL", "1")

hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE", "20")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("HYPRCURSOR_SIZE", "20")

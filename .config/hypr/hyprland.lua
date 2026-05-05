-- Entry point. Sources sub-modules in the same order as the old hyprland.conf.
-- hypridle.conf and hyprlock.conf are standalone programs and stay as .conf files.
require("env")
require("execs")
require("monitors")
require("keybinds")
require("looks")

hl.config({
    input = {
        kb_layout      = "us",
        follow_mouse   = 1,
        repeat_rate    = 35,
        repeat_delay   = 250,
        natural_scroll = false,
        accel_profile  = "adaptive",
        sensitivity    = 0.0,

        touchpad = {
            natural_scroll          = true,
            tap_to_click            = false,
            drag_lock               = true,
            clickfinger_behavior    = true,
            middle_button_emulation = true,
            disable_while_typing    = false,
        },
    },
})

hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})

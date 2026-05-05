local super = "SUPER"
local alt   = "ALT"

local terminal = "kitty"
local launcher = "wofi --show drun"

-- Apps
hl.bind(super .. " + Return",        hl.dsp.exec_cmd(terminal))
hl.bind(super .. " + Space",         hl.dsp.exec_cmd(launcher))
hl.bind(super .. " + B",             hl.dsp.exec_cmd("swaync-client -t"))
hl.bind(super .. " + E",             hl.dsp.exec_cmd("hyprlock"))
hl.bind("XF86Launch1",               hl.dsp.exec_cmd("zen-browser"))
hl.bind(super .. " + XF86MicMute",   hl.dsp.exec_cmd("pactl set-source-mute @DEFAULT_SOURCE@ toggle"))
hl.bind(super .. " + P",             hl.dsp.exec_cmd("hyprpicker -a"))
hl.bind(super .. " + O",             hl.dsp.exec_cmd("obsidian"))
hl.bind(super .. " + F11",           hl.dsp.exec_cmd("swaync-client -d"))
hl.bind(super .. " + A",             hl.dsp.exec_cmd("/home/raf/media/downloads/Handy_0.7.11_amd64.AppImage --toggle-transcription"))
hl.bind(super .. " + Q",             hl.dsp.window.close())
hl.bind(alt   .. " + ESCAPE",        hl.dsp.exit())

-- Window management
hl.bind(super .. " + F",             hl.dsp.window.fullscreen())
hl.bind(super .. " + CTRL + F",      hl.dsp.window.fullscreen({ mode = 1 }))
hl.bind(super .. " + CTRL + H",      hl.dsp.window.pseudo())
hl.bind(super .. " + W",             hl.dsp.window.float({ action = "toggle" }))
hl.bind(super .. " + mouse:273",     hl.dsp.window.resize(), { mouse = true })
hl.bind(super .. " + mouse:272",     hl.dsp.window.drag(),   { mouse = true })

-- Focus
hl.bind(super .. " + CTRL + left",   hl.dsp.focus({ direction = "left" }))
hl.bind(super .. " + CTRL + right",  hl.dsp.focus({ direction = "right" }))
hl.bind(super .. " + CTRL + up",     hl.dsp.focus({ direction = "up" }))
hl.bind(super .. " + CTRL + down",   hl.dsp.focus({ direction = "down" }))

-- Move windows
hl.bind(super .. " + CTRL + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(super .. " + CTRL + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(super .. " + CTRL + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))
hl.bind(super .. " + CTRL + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))

-- Workspaces 1-9
for i = 1, 9 do
    hl.bind(super .. " + " .. i, hl.dsp.focus({ workspace = i }))
    hl.bind(alt   .. " + " .. i, hl.dsp.window.move({ workspace = i }))
end

-- Scripts
hl.bind(super .. " + F5", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot-screen.sh"))
hl.bind(super .. " + F6", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot-area.sh"))
hl.bind(super .. " + M",  hl.dsp.exec_cmd("~/.config/hypr/scripts/focus-mode.sh toggle"))
hl.bind(super .. " + R",  hl.dsp.exec_cmd("~/.config/hypr/scripts/reload.sh"))

-- Volume / brightness (locked + repeating, mirrors bindel)
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("~/.config/hypr/scripts/volume-osd.sh up"),        { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("~/.config/hypr/scripts/volume-osd.sh down"),      { locked = true, repeating = true })
hl.bind(super .. " + F1",       hl.dsp.exec_cmd("~/.config/hypr/scripts/volume-osd.sh mute"),      { locked = true, repeating = true })
hl.bind(super .. " + F8",       hl.dsp.exec_cmd("~/.config/hypr/scripts/brightness-osd.sh up"),    { locked = true, repeating = true })
hl.bind(super .. " + F7",       hl.dsp.exec_cmd("~/.config/hypr/scripts/brightness-osd.sh down"),  { locked = true, repeating = true })
hl.bind("XF86PowerOff",         hl.dsp.exec_cmd("wlogout"))

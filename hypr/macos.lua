-- macOS look for Hyprland (Lua config, Hyprland 0.57+)
-- Loaded from hyprland.lua with:  require("macos")
-- Put the require at the end of hyprland.lua so these settings win.

---------------------
---- ENVIRONMENT ----
---------------------

hl.env("XCURSOR_THEME", "macOS")
hl.env("HYPRCURSOR_THEME", "macOS")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
-- Qt apps use the macOS (Kvantum WhiteSur) theme
if io.open("/usr/bin/qt6ct") then hl.env("QT_QPA_PLATFORMTHEME", "qt6ct") end
if io.open("/usr/bin/kvantummanager") then hl.env("QT_STYLE_OVERRIDE", "kvantum") end

---------------------
---- LOOK & FEEL ----
---------------------

-- No coloured border, just a hairline + soft drop shadow, rounded corners, frosted blur
hl.config({
    general = {
        gaps_in = 6,
        gaps_out = 12,
        border_size = 1,
        col = {
            active_border = "rgba(ffffff2e)",
            inactive_border = "rgba(ffffff14)",
        },
        resize_on_border = true,
    },
    decoration = {
        rounding = 12,
        active_opacity = 1.0,
        inactive_opacity = 1.0,
        shadow = {
            enabled = true,
            range = 40,
            render_power = 3,
            offset = "0 12",
            color = "rgba(00000073)",
            color_inactive = "rgba(00000040)",
        },
        blur = {
            enabled = true,
            size = 10,
            passes = 3,
            noise = 0.02,
            vibrancy = 0.25,
        },
    },
    animations = {
        enabled = true,
    },
})

-- macOS-like motion: quick ease-out, windows scale in, Spaces slide sideways
hl.curve("macEase",  { type = "bezier", points = { { 0.25, 1 }, { 0.5, 1 } } })
hl.curve("macSpace", { type = "bezier", points = { { 0.2, 0.9 }, { 0.2, 1 } } })
hl.animation({ leaf = "windows",    enabled = true, speed = 4,  bezier = "macEase", style = "popin 92%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3,  bezier = "macEase", style = "popin 92%" })
hl.animation({ leaf = "border",     enabled = true, speed = 6,  bezier = "default" })
hl.animation({ leaf = "fade",       enabled = true, speed = 4,  bezier = "macEase" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5,  bezier = "macSpace", style = "slide" })

-- Dux Shell surfaces animate themselves
hl.layer_rule({ match = { namespace = "dms" }, no_anim = true })

-------------------
---- AUTOSTART ----
-------------------

-- Follow light/dark mode: GTK 3/4, Qt (Kvantum) and kitty switch with the shell
hl.on("hyprland.start", function()
    hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/mac-appearance.sh")
end)

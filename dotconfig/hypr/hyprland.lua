-- hyprland.lua — converted from hyprland.conf
-- Target: Hyprland 0.55.4 (hyprlang deprecated since 0.55)
--
-- API verified against /usr/share/hypr/stubs/hl.meta.lua and
-- `Hyprland --verify-config` on this machine.
--
-- Key syntax note: every modifier needs its own `+` separator.
--   correct:   "SUPER + ALT + m"
--   incorrect: "SUPER ALT + m"

-- =============================================================================
-- 00 — Variables
-- =============================================================================

local MONITOR_SCALE    = 1
local TOUCHPAD_ENABLED = true
local HYPRCURSOR_THEME = "Bibata-Modern-Ice"
local HYPRCURSOR_SIZE  = 24

local HOME             = os.getenv("HOME")
local CONFIG_DIR       = (os.getenv("XDG_CONFIG_HOME") or (HOME .. "/.config")) .. "/hypr"

-- =============================================================================
-- 01 — Environment variables
-- =============================================================================

-- Toolkit backends
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("CLUTTER_BACKEND", "wayland")

-- XDG
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
-- Ensure Dolphin finds the KDE menu
hl.env("XDG_MENU_PREFIX", "arch-")

-- GTK fallback theme
hl.env("GTK_THEME", "Adwaita:dark")

-- QT
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_QPA_PLATFORMTHEME", "hyprqt6engine")
hl.env("QT_STYLE_OVERRIDE", "kvantum-dark")
-- hyprland-qt-support
hl.env("QT_QUICK_CONTROLS_STYLE", "org.hyprland.style")

-- Scaling
hl.env("GDK_SCALE", tostring(MONITOR_SCALE))
hl.env("QT_SCALE_FACTOR", tostring(MONITOR_SCALE))

-- Cursor
hl.env("HYPRCURSOR_THEME", HYPRCURSOR_THEME)
hl.env("HYPRCURSOR_SIZE", tostring(HYPRCURSOR_SIZE))

-- Apps
hl.env("TERMINAL", "ghostty")
hl.env("EDITOR", "nvim")
hl.env("MOZ_ENABLE_WAYLAND", "1")
-- auto selects Wayland if possible, X11 otherwise
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- =============================================================================
-- 02 — Exec
-- =============================================================================

-- Runs on every config load (was `exec =`)
hl.exec_cmd([[gsettings set org.gnome.desktop.interface gtk-theme "Breeze-Dark"]])
hl.exec_cmd([[gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"]])

-- Runs once at startup (was `exec-once =`)
hl.on("hyprland.start", function()
    hl.exec_cmd("hyprctl setcursor " .. HYPRCURSOR_THEME .. " " .. tostring(HYPRCURSOR_SIZE))

    -- export env
    hl.exec_cmd(
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE")
    hl.exec_cmd(
        "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE QT_QPA_PLATFORMTHEME QT_STYLE_OVERRIDE")

    -- agents
    hl.exec_cmd("/usr/lib/pam_kwallet_init &")

    -- bluelight filter
    hl.exec_cmd("wlsunset -t2550 -T5500 -d1800 -S9:00 -s19:30 &")
end)

-- =============================================================================
-- 03 — Monitors
-- =============================================================================

-- Fallbacks; DMS-generated dms/outputs.conf is replayed at the bottom of this
-- file and takes precedence.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = MONITOR_SCALE })
hl.monitor({ output = "", mode = "highrr", position = "auto", scale = MONITOR_SCALE })
hl.monitor({ output = "", mode = "highres", position = "auto", scale = MONITOR_SCALE })

-- =============================================================================
-- 04 — Laptop (touchpad)
-- =============================================================================

-- Same approach as the old `$Touchpad` backtick: ask hyprctl for the device
-- name. Skipped silently when it can't be resolved (e.g. during
-- --verify-config, where no compositor is running).
local function touchpad_name()
    local ok, handle = pcall(io.popen,
        [[hyprctl devices -j 2>/dev/null | jq -r '.mice[]? | select(.name | contains("touchpad")).name' 2>/dev/null | head -1]])
    if not ok or not handle then return nil end
    local name = handle:read("*l")
    handle:close()
    if name and name ~= "" then return name end
    return nil
end

local tp = touchpad_name()
if tp then
    hl.device({ name = tp, enabled = TOUCHPAD_ENABLED })
end

-- =============================================================================
-- 05 — Window / layer / workspace rules
-- =============================================================================

-- ---- Tags -------------------------------------------------------------------

-- browsers
hl.window_rule({
    match = { class = "^([Ff]irefox|org.mozilla.firefox|[Ff]irefox-esr|[Ff]irefox-bin|zen)$" },
    tag =
    "+browser"
})
hl.window_rule({ match = { class = "^([Cc]hromium)$" }, tag = "+browser" })
hl.window_rule({ match = { class = "^(Brave-browser(-beta|-dev|-unstable)?)$" }, tag = "+browser" })

-- notifications
hl.window_rule({
    match = { class = "^(swaync-control-center|swaync-notification-window|swaync-client|class)$" },
    tag =
    "+notif"
})

-- terminals
hl.window_rule({ match = { class = "^(wezterm|ghostty|konsole)$" }, tag = "+terminal" })

-- email
hl.window_rule({ match = { class = "^([Tt]hunderbird)$" }, tag = "+email" })
hl.window_rule({ match = { class = "^(eu.betterbird.Betterbird)$" }, tag = "+email" })

-- screenshare
hl.window_rule({ match = { class = "^(com.obsproject.Studio)$" }, tag = "+screenshare" })

-- IM
hl.window_rule({ match = { class = "^([Dd]iscord|[Ww]ebCord|[Vv]esktop)$" }, tag = "+im" })
hl.window_rule({ match = { class = "^([Ff]erdium)$" }, tag = "+im" })
hl.window_rule({ match = { class = "^([Ww]hatsapp-for-linux)$" }, tag = "+im" })
hl.window_rule({ match = { class = "^(ZapZap|com.rtosta.zapzap)$" }, tag = "+im" })
hl.window_rule({ match = { class = "^(org.telegram.desktop|io.github.tdesktop_x64.TDesktop)$" }, tag = "+im" })
hl.window_rule({ match = { class = "^([Ss]lack)$" }, tag = "+im" })

-- games
hl.window_rule({ match = { class = "^(gamescope)$" }, tag = "+games" })
hl.window_rule({ match = { class = "^(steam_app_\\d+)$" }, tag = "+games" })
hl.window_rule({ match = { class = "^(.*path of building.*)$" }, tag = "+game_adj" })

-- gamestore
hl.window_rule({ match = { class = "^([Ss]team)$" }, tag = "+gamestore" })
hl.window_rule({ match = { title = "^([Ll]utris)$" }, tag = "+gamestore" })
hl.window_rule({ match = { title = "^([Bb]attle.net.*)$" }, tag = "+gamestore" })

-- file managers
hl.window_rule({ match = { class = "^([Tt]hunar|org.gnome.Nautilus|[Pp]cmanfm-qt|[Dd]olphin)$" }, tag = "+file-manager" })
hl.window_rule({ match = { class = "^(app.drey.Warp)$" }, tag = "+file-manager" })

-- wallpaper
hl.window_rule({ match = { class = "^([Ww]aytrogen)$" }, tag = "+wallpaper" })

-- multimedia
hl.window_rule({ match = { class = "^([Aa]udacious)$" }, tag = "+multimedia" })
hl.window_rule({ match = { class = "^([Mm]pv|vlc)$" }, tag = "+multimedia" })

-- settings
hl.window_rule({ match = { class = "^(wihotspot(-gui)?)$" }, tag = "+settings" })              -- wifi hotspot
hl.window_rule({ match = { class = "^([Bb]aobab|org.gnome.[Bb]aobab)$" }, tag = "+settings" }) -- disk usage analyzer
hl.window_rule({ match = { class = "^(gnome-disks|wihotspot(-gui)?)$" }, tag = "+settings" })
hl.window_rule({ match = { title = "(Kvantum Manager)" }, tag = "+settings" })
hl.window_rule({ match = { class = "^(file-roller|org.gnome.FileRoller)$" }, tag = "+settings" }) -- archive manager
hl.window_rule({ match = { class = "^(nm-applet|nm-connection-editor|blueman-manager)$" }, tag = "+settings" })
hl.window_rule({
    match = { class = "^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$" },
    tag =
    "+settings"
})
hl.window_rule({ match = { class = "^(qt5ct|qt6ct|[Yy]ad)$" }, tag = "+settings" })
hl.window_rule({ match = { class = "(xdg-desktop-portal.*)" }, tag = "+settings" })
hl.window_rule({ match = { class = "^(.*.polkit-.*-authentication-agent.*)$" }, tag = "+settings" })
hl.window_rule({ match = { class = "^([WwRr]ofi)$" }, tag = "+settings" })

-- viewers
hl.window_rule({
    match = { class = "^(gnome-system-monitor|org.gnome.SystemMonitor|io.missioncenter.MissionCenter)$" },
    tag =
    "+viewer"
})                                                                                             -- system monitor
hl.window_rule({ match = { class = "^(evince)$" }, tag = "+viewer" })                          -- document viewer
hl.window_rule({ match = { class = "^(eog|org.gnome.Loupe|[Gg]wenview)$" }, tag = "+viewer" }) -- image viewer

-- ---- Overrides --------------------------------------------------------------

hl.window_rule({ match = { tag = "multimedia*" }, opacity = "1.0", no_blur = true })

-- ---- Privacy ----------------------------------------------------------------

hl.window_rule({ match = { class = "^(.*KeePassXC.*)$" }, tag = "+private*" })
hl.window_rule({ match = { class = "^([Ss]lack)$" }, tag = "+private*" })

hl.window_rule({
    name            = "private-windows",
    match           = { tag = "private*" },
    no_screen_share = true,
    border_color    = { colors = { "rgb(FF0000)", "rgb(CC7654)" }, angle = 35 },
})

hl.layer_rule({
    name            = "private-notifications-1",
    match           = { namespace = "dms:notification-popup" },
    no_screen_share = true,
})
hl.layer_rule({
    name            = "private-notifications-2",
    match           = { namespace = "dms:notification-center-popout" },
    no_screen_share = true,
})

-- ---- Position ---------------------------------------------------------------

hl.window_rule({ match = { class = "([Tt]hunar)", title = "negative:(.*[Tt]hunar.*)" }, center = true })
hl.window_rule({ match = { class = "([Dd]olphin)", title = "negative:(.*[Dd]olphin.*)" }, center = true })

hl.window_rule({ match = { class = "^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$" }, center = true })
hl.window_rule({ match = { class = "^([Ww]hatsapp-for-linux|ZapZap|com.rtosta.zapzap)$" }, center = true })
hl.window_rule({ match = { class = "^([Ff]erdium)$" }, center = true })
hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, center = true })
hl.window_rule({ match = { class = "^(org.kde.kgpg)$" }, center = true })

-- ---- Idle inhibit -----------------------------------------------------------

hl.window_rule({ match = { fullscreen = true }, idle_inhibit = "fullscreen" })
hl.window_rule({ match = { class = "(mpv)" }, idle_inhibit = "focus" })

-- ---- Workspace assignment ---------------------------------------------------

hl.window_rule({ match = { tag = "email*" }, workspace = "1" })
hl.window_rule({ match = { tag = "browser*" }, workspace = "2" })
hl.window_rule({ match = { tag = "multimedia*" }, workspace = "4" })
hl.window_rule({ match = { tag = "games*" }, workspace = "5" })
hl.window_rule({ match = { tag = "game_adj*" }, workspace = "6" })
hl.window_rule({ match = { tag = "im*" }, workspace = "7" })

hl.window_rule({ match = { tag = "gamestore*" }, workspace = "5 silent" })
hl.window_rule({ match = { tag = "screenshare*" }, workspace = "9 silent" })
hl.window_rule({ match = { class = "^(virt-manager)$" }, workspace = "10 silent" })
hl.window_rule({ match = { class = "^(.virt-manager-wrapped)$" }, workspace = "10 silent" })

hl.window_rule({ match = { class = "^(.*KeePassXC.*)$" }, workspace = "special:keepass silent" })
hl.window_rule({ match = { class = "^(.*zaproxy.*)$" }, workspace = "special silent" })

-- ---- Floating ---------------------------------------------------------------

hl.window_rule({ match = { tag = "wallpaper*" }, float = true })
hl.window_rule({ match = { tag = "settings*" }, float = true })
hl.window_rule({ match = { tag = "viewer*" }, float = true })
hl.window_rule({ match = { class = "([Zz]oom|onedriver|onedriver-launcher)$" }, float = true })
hl.window_rule({ match = { class = "(org.kde.kcalc)", title = "(Kcalc)" }, float = true })
hl.window_rule({ match = { class = "^(mpv|com.github.rafostar.Clapper)$" }, float = true })
hl.window_rule({ match = { class = "^([Qq]alculate-gtk)$" }, float = true })
hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, float = true })
hl.window_rule({ match = { class = "^(org.kde.kgpg)$" }, float = true })

-- popups / dialogs
hl.window_rule({ match = { title = "^(Authentication Required)$" }, float = true, center = true })
hl.window_rule({ match = { class = "^([Ss]team)$", title = "negative:^([Ss]team)$" }, float = true })
hl.window_rule({ match = { class = "([Dd]olphin)", title = "negative:(.*[Dd]olphin.*)" }, float = true })
hl.window_rule({ match = { title = "^(Calendar Reminders)$" }, float = true, center = true })
hl.window_rule({ match = { title = "^(Add Folder to Workspace)$" }, float = true, center = true, size = "70% 60%" })
hl.window_rule({ match = { title = "^(Save As)$" }, float = true, center = true, size = "70% 60%" })
hl.window_rule({ match = { class = "^(.*file.*)$", title = "^(Export.*)$" }, float = true, center = true })
hl.window_rule({ match = { initial_title = "(Open Files)" }, float = true, size = "70% 60%" })
hl.window_rule({ match = { class = "(file_progress)" }, float = true })
hl.window_rule({ match = { class = "(confirm)" }, float = true })
hl.window_rule({ match = { class = "(dialog)" }, float = true })
hl.window_rule({ match = { class = "(download)" }, float = true })
hl.window_rule({ match = { class = "(notification)" }, float = true })
hl.window_rule({ match = { class = "(error)" }, float = true })
hl.window_rule({ match = { class = "(splash)" }, float = true })
hl.window_rule({ match = { class = "(confirmreset)" }, float = true })
hl.window_rule({ match = { class = "(pavucontrol-qt)" }, float = true })
hl.window_rule({ match = { class = "(pavucontrol)" }, float = true })
hl.window_rule({ match = { class = "(file-roller)" }, float = true })
hl.window_rule({ match = { class = "(feh)" }, float = true })
hl.window_rule({ match = { class = "(zen)", title = "(Library)" }, float = true })
hl.window_rule({ match = { title = "^(Volume Control)$" }, float = true, size = "800 600", move = "75 44%" })

-- ---- Opacity ----------------------------------------------------------------

hl.window_rule({ match = { tag = "browser*" }, opacity = "0.9 0.7" })
hl.window_rule({ match = { tag = "projects*" }, opacity = "0.9 0.8" })
hl.window_rule({ match = { tag = "im*" }, opacity = "0.94 0.86" })
hl.window_rule({ match = { tag = "file-manager*" }, opacity = "0.9 0.8" })
hl.window_rule({ match = { tag = "terminal*" }, opacity = "0.8 0.7" })
hl.window_rule({ match = { tag = "settings*" }, opacity = "0.8 0.7" })
hl.window_rule({ match = { tag = "viewer*" }, opacity = "0.82 0.75" })
hl.window_rule({ match = { tag = "wallpaper*" }, opacity = "0.9 0.7" })
hl.window_rule({ match = { class = "^(gedit|org.gnome.TextEditor|mousepad)$" }, opacity = "0.8 0.7" })
hl.window_rule({ match = { class = "^(deluge)$" }, opacity = "0.9 0.8" })
hl.window_rule({ match = { class = "^(im.riot.Riot)$" }, opacity = "0.9 0.8" }) -- Element matrix client
hl.window_rule({ match = { class = "^(seahorse)$" }, opacity = "0.9 0.8" })     -- gnome-keyring gui
hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, opacity = "0.95 0.75" })

-- ---- Size -------------------------------------------------------------------

hl.window_rule({ match = { tag = "wallpaper*" }, size = "70% 70%" })
hl.window_rule({ match = { tag = "settings*" }, size = "70% 70%" })
hl.window_rule({ match = { class = "^([Ww]hatsapp-for-linux|ZapZap|com.rtosta.zapzap)$" }, size = "60% 70%" })
hl.window_rule({ match = { class = "^([Ff]erdium)$" }, size = "60% 70%" })

-- ---- Pinning + extras -------------------------------------------------------

hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, pin = true, keep_aspect_ratio = true })

-- ---- Blur & fullscreen ------------------------------------------------------

hl.window_rule({ match = { tag = "games*" }, no_blur = true, float = true, fullscreen = true })

-- ---- Layer rules ------------------------------------------------------------

hl.layer_rule({ match = { namespace = "notifications" }, blur = true, ignore_alpha = 1.0 })

-- ---- No gaps when only ------------------------------------------------------

hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
hl.workspace_rule({ workspace = "f[1]", gaps_out = 0, gaps_in = 0 })

hl.window_rule({
    name        = "no-gapps-ws-tv1",
    match       = { float = false, workspace = "w[tv1]", tag = "negative:private*" },
    border_size = 0,
    rounding    = 0,
})
hl.window_rule({
    name        = "no-gapps-ws-f1",
    match       = { float = false, workspace = "f[1]", tag = "negative:private*" },
    border_size = 0,
    rounding    = 0,
})

-- =============================================================================
-- 06 — Behaviour
-- =============================================================================

hl.config({
    input = {
        kb_layout                   = "fi",
        kb_variant                  = "nodeadkeys",
        repeat_rate                 = 40,
        repeat_delay                = 185,
        numlock_by_default          = true,

        follow_mouse                = 2,
        sensitivity                 = 0, -- -1.0 - 1.0, 0 means no modification.
        accel_profile               = "flat",
        mouse_refocus               = false,
        natural_scroll              = false,
        float_switch_override_focus = false,

        scroll_method               = "2fg",

        touchpad                    = {
            natural_scroll          = true,
            disable_while_typing    = true,
            clickfinger_behavior    = false,
            middle_button_emulation = true,
            tap_to_click            = true,
            drag_lock               = false,
        },

        -- for devices with a touchscreen
        touchdevice                 = {
            enabled = true,
        },

        tablet                      = {
            transform   = 0,
            left_handed = false,
        },
    },

    dwindle = {
        preserve_split       = true,
        special_scale_factor = 0.8,
    },

    master = {
        new_status = "master",
        new_on_top = true,
        mfact      = 0.5,
    },

    general = {
        -- Gaps and border
        gaps_in                 = 2,
        gaps_out                = 3,
        border_size             = 2,

        -- Fallback colors
        col                     = {
            active_border   = {
                colors = { "rgba(0DB7D4FF)", "rgba(7AA2F7FF)", "rgba(9778D0FF)" },
                angle  = 45,
            },
            inactive_border = "rgba(04404aaa)",
        },

        -- Functionality
        resize_on_border        = false,
        extend_border_grab_area = 5,
        layout                  = "dwindle",
    },

    misc = {
        vrr                          = 2,
        focus_on_activate            = true,
        animate_manual_resizes       = true,
        animate_mouse_windowdragging = true,
        disable_hyprland_logo        = true,
        disable_splash_rendering     = true,
        mouse_move_enables_dpms      = true,
        enable_swallow               = true,
        swallow_regex                = "^(wezterm|ghostty)$",
        initial_workspace_tracking   = 0,
        middle_click_paste           = false,
    },

    decoration = {
        rounding           = 8,

        active_opacity     = 1.0,
        inactive_opacity   = 0.99,
        fullscreen_opacity = 1.0,

        dim_inactive       = true,
        dim_strength       = 0.1,
        dim_special        = 0.5,

        shadow             = {
            enabled      = true,
            range        = 3,
            render_power = 1,
        },

        blur               = {
            enabled           = true,
            size              = 6,
            passes            = 2,
            ignore_opacity    = true,
            new_optimizations = true,
            special           = true,
            popups            = true,
        },
    },

    binds = {
        workspace_back_and_forth = true,
        allow_workspace_cycles   = true,
        pass_mouse_when_bound    = false,
    },

    -- Helps when scaling, avoids pixelating
    xwayland = {
        enabled            = true,
        force_zero_scaling = true,
    },

    render = {
        new_render_scheduling = true,
        direct_scanout        = 0,
    },

    cursor = {
        sync_gsettings_theme     = true,
        no_hardware_cursors      = 2, -- change to 1 to disable
        enable_hyprcursor        = true,
        warp_on_change_workspace = 2,
        no_warps                 = true,
    },

    animations = {
        enabled = true,
    },
})

-- =============================================================================
-- Gestures
-- =============================================================================

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- =============================================================================
-- Animations
-- =============================================================================

hl.curve("overshot", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
hl.curve("smoothOut", { type = "bezier", points = { { 0.36, 0 }, { 0.66, -0.56 } } })
hl.curve("smoothIn", { type = "bezier", points = { { 0.25, 1 }, { 0.5, 1 } } })
hl.curve("winIn", { type = "bezier", points = { { 0.05, 1.1 }, { 0.1, 1.1 } } })
hl.curve("winOut", { type = "bezier", points = { { 0.2, -0.3 }, { 0, 1 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 5, bezier = "overshot", style = "slide" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 5, bezier = "winIn", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 4, bezier = "smoothOut", style = "slide" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 10, bezier = "smoothIn" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 10, bezier = "smoothIn" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "default" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 5, bezier = "winOut", style = "slide" })

-- =============================================================================
-- 07 — Keybinds
-- =============================================================================

-- ---- Multimedia -------------------------------------------------------------

-- was bindel (repeat + locked)
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pamixer --allow-boost -i 5"), { repeating = true, locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pamixer --allow-boost -d 5"), { repeating = true, locked = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("pamixer -t"), { repeating = true, locked = true })

hl.bind("SUPER + ALT + m", hl.dsp.exec_cmd("pamixer -t"), { locked = true })
hl.bind("SUPER + m", hl.dsp.exec_cmd("pamixer --default-source -t"), { locked = true })

hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("dms ipc call mpris playPause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("dms ipc call mpris playPause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("dms ipc call mpris next"))
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("dms ipc call mpris previous"))

hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set +5%"), { repeating = true, locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { repeating = true, locked = true })

-- ---- Lid --------------------------------------------------------------------

hl.bind("switch:on:Lid Switch",
    hl.dsp.exec_cmd("dms ipc lock lock && dms ipc call mpris pause && sleep 1 && systemctl suspend"),
    { locked = true })

-- ---- Launchers --------------------------------------------------------------

hl.bind("SUPER + SUPER_L", hl.dsp.exec_cmd("dms ipc call spotlight toggle"), { release = true })
hl.bind("SUPER + ALT + E", hl.dsp.exec_cmd([[dms ipc call spotlight toggleQuery ":"]]))
hl.bind("SUPER + B", hl.dsp.exec_cmd("zen-browser"))
hl.bind("SUPER + L", hl.dsp.exec_cmd("dms ipc lock lock"))
hl.bind("SUPER + P", hl.dsp.exec_cmd("dms ipc call powermenu toggle"))
hl.bind("SUPER + F1", hl.dsp.exec_cmd(CONFIG_DIR .. "/scripts/keybind.sh"))
hl.bind("SUPER + E", hl.dsp.exec_cmd("dolphin"))
hl.bind("SUPER + X", hl.dsp.exec_cmd("ghostty"))

-- ---- Privacy toggle ---------------------------------------------------------

hl.bind("SUPER + SHIFT + P", hl.dsp.window.tag({ tag = "private*" }))

-- ---- Screenshots ------------------------------------------------------------

hl.bind("Print", hl.dsp.exec_cmd(CONFIG_DIR .. "/scripts/screenshot.sh screen"))
hl.bind("SUPER + Print", hl.dsp.exec_cmd(CONFIG_DIR .. "/scripts/screenshot.sh window"))
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd(CONFIG_DIR .. "/scripts/screenshot.sh area"))
hl.bind("SUPER + ALT + SHIFT + S", hl.dsp.exec_cmd(CONFIG_DIR .. "/scripts/screenshot.sh window"))
hl.bind("SUPER + CTRL + SHIFT + S", hl.dsp.exec_cmd(CONFIG_DIR .. "/scripts/screenshot.sh screen"))

hl.bind("SUPER + SHIFT + B", hl.dsp.exec_cmd(CONFIG_DIR .. "/scripts/battery-alarm-dismiss.sh"))

-- ---- Color picker -----------------------------------------------------------

-- The old bind shelled out to `hyprctl keyword windowrule opaque ...`, which is
-- hyprlang syntax. Instead we keep a permanently-defined but disabled rule and
-- flip it around the picker, re-disabling it once hyprpicker exits.
local pickerOpaque = hl.window_rule({
    name    = "picker-force-opaque",
    match   = { class = "^(.*)$" },
    opaque  = true,
    enabled = false,
})

hl.bind("SUPER + ALT + P", function()
    pickerOpaque:set_enabled(true)
    hl.exec_cmd("hyprpicker -a")

    local watcher
    watcher = hl.timer(function()
        local h = io.popen("pgrep -x hyprpicker >/dev/null 2>&1 && echo running || echo gone")
        local state = h and h:read("*l") or "gone"
        if h then h:close() end
        if state ~= "running" then
            pickerOpaque:set_enabled(false)
            watcher:set_enabled(false)
        end
    end, { timeout = 250, type = "repeat" })
end)

-- ---- Window management ------------------------------------------------------

hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + SHIFT + Q", hl.dsp.exec_cmd(
    [[kill -9 $(hyprctl activewindow | grep -o 'pid: [0-9]*' | cut -d' ' -f2)]]))

-- Two dispatchers on one key: use a function.
hl.bind("ALT + Tab", function()
    hl.dispatch(hl.dsp.window.cycle_next())
    hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top" }))
end)

hl.bind("SUPER + CTRL + SHIFT + ALT + Q", hl.dsp.exit())

hl.bind("SUPER + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "maximized" })) -- fake fullscreen

hl.bind("SUPER + Space", hl.dsp.window.float({ action = "toggle" }))

-- Focus
hl.bind("SUPER + left", hl.dsp.focus({ direction = "l" }))
hl.bind("SUPER + right", hl.dsp.focus({ direction = "r" }))
hl.bind("SUPER + up", hl.dsp.focus({ direction = "u" }))
hl.bind("SUPER + down", hl.dsp.focus({ direction = "d" }))

-- Move window
hl.bind("SUPER + SHIFT + left", hl.dsp.window.move({ direction = "l" }))
hl.bind("SUPER + SHIFT + right", hl.dsp.window.move({ direction = "r" }))
hl.bind("SUPER + SHIFT + up", hl.dsp.window.move({ direction = "u" }))
hl.bind("SUPER + SHIFT + down", hl.dsp.window.move({ direction = "d" }))

-- Resize (was binde -> repeating)
hl.bind("SUPER + CTRL + left", hl.dsp.window.resize({ x = -20, y = 0, relative = true }), { repeating = true })
hl.bind("SUPER + CTRL + right", hl.dsp.window.resize({ x = 20, y = 0, relative = true }), { repeating = true })
hl.bind("SUPER + CTRL + up", hl.dsp.window.resize({ x = 0, y = -20, relative = true }), { repeating = true })
hl.bind("SUPER + CTRL + down", hl.dsp.window.resize({ x = 0, y = 20, relative = true }), { repeating = true })

-- Groups
hl.bind("SUPER + g", hl.dsp.group.toggle())
hl.bind("SUPER + SHIFT + g", hl.dsp.window.move({ out_of_group = true }))
hl.bind("SUPER + tab", hl.dsp.group.next())

-- Special workspaces
hl.bind("SUPER + k", hl.dsp.workspace.toggle_special("keepass"))
hl.bind("SUPER + section", hl.dsp.workspace.toggle_special())

-- Switch / move workspaces
for i = 1, 9 do
    hl.bind("SUPER + " .. i, hl.dsp.focus({ workspace = i }))
    hl.bind("SUPER + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end
hl.bind("SUPER + 0", hl.dsp.focus({ workspace = 10 }))
hl.bind("SUPER + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))

hl.bind("SUPER + ALT + up", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + ALT + down", hl.dsp.focus({ workspace = "e-1" }))
hl.bind("SUPER + SHIFT + section", hl.dsp.window.move({ workspace = "special" }))

-- Move current workspace to monitor (0-indexed monitors, keys 1..5)
for i = 0, 4 do
    hl.bind("SUPER + ALT + SHIFT + " .. (i + 1), hl.dsp.workspace.move({ monitor = i }))
end

-- Mouse
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- =============================================================================
-- 08 — DMS-generated config + local overrides
-- =============================================================================

-- DMS is Lua-only for Hyprland now (its outputsPath is hardcoded to
-- dms/outputs.lua), so its fragments are loaded with plain `require`. DMS greps
-- for these literal require lines — `dms config resolve-include hyprland
-- outputs.lua` must report "included":true, or the Displays settings page will
-- not consider the fragment wired up.
require("dms.outputs")

-- Optional DMS fragments: only present once you touch the matching settings
-- page, so they are loaded defensively. Written as literal require calls so
-- DMS's include check can still find them.
local function require_if_present(name)
    local f = io.open(CONFIG_DIR .. "/dms/" .. name .. ".lua", "r")
    if not f then return end
    f:close()
    local ok, err = pcall(require, "dms." .. name)
    if not ok then
        io.stderr:write("dms/" .. name .. ".lua error: " .. tostring(err) .. "\n")
    end
end

require_if_present("cursor")      -- require("dms.cursor")
require_if_present("windowrules") -- require("dms.windowrules")

-- Deliberately NOT loaded:
--   dms.layout  — would override gaps (4/4 vs 2/3) and rounding (12 vs 8) set
--                 above; the hyprlang config never sourced layout.conf either.
--   dms.colors  — would override the general.col border gradient above.
--   dms.binds   — keybinds are defined in this file, not managed by DMS.

-- Load conf.local.d/*.lua. pcall keeps one bad file from killing the rest.
local lister = io.popen("ls -1 " .. CONFIG_DIR .. "/conf.local.d/*.lua 2>/dev/null")
if lister then
    for path in lister:lines() do
        local ok, err = pcall(dofile, path)
        if not ok then
            -- stderr lands in the Hyprland log (and in --verify-config output);
            -- the notification is for when you're actually logged in.
            io.stderr:write("conf.local.d error in " .. path .. ": " .. tostring(err) .. "\n")
            hl.notification.create({
                text    = "Config error in " .. path .. "\n" .. tostring(err),
                timeout = 6000,
                icon    = 3,
            })
        end
    end
    lister:close()
end

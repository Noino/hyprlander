-- Pull in the wezterm API
local wezterm = require 'wezterm'

local act = wezterm.action
-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
    config = wezterm.config_builder()
end

-- This is where you actually apply your config choices

-- For example, changing the color scheme:
config.color_scheme = 'tokyonight_moon'

config.font = wezterm.font('JetBrains Mono')

config.window_background_opacity = 0.85
config.hide_tab_bar_if_only_one_tab = true
config.audible_bell = 'Disabled'
config.enable_kitty_keyboard = false
config.enable_wayland = false


config.mouse_bindings = {
    {
        event = { Down = { streak = 1, button = "Right" } },
        mods = "NONE",
        action = wezterm.action_callback(function(window, pane)
            local has_selection = window:get_selection_text_for_pane(pane) ~= ""
            if has_selection then
                window:perform_action(act.CopyTo("ClipboardAndPrimarySelection"), pane)
                window:perform_action(act.ClearSelection, pane)
            else
                window:perform_action(act({ PasteFrom = "Clipboard" }), pane)
            end
        end),
    },
}

-- and finally, return the configuration to wezterm
return config

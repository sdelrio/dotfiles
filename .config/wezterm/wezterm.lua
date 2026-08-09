local wezterm = require("wezterm")

local config = wezterm.config_builder()

local function get_appearance()
  if wezterm.gui then
    return wezterm.gui.get_appearance()
  end
  return "Dark"
end

local function scheme_for_appearance(appearance)
  if appearance:find("Dark") then
    return "Solarized Dark - Patched"
  else
    return "Solarized (Light) (Gogh)"
  end
end

local function bg_for_appearance(appearance)
  if appearance:find("Dark") then
  	return "#1a1a1a"
--    return "#1a1d23"
--  	return "#202020"
  else
    return "#808080"
  end
end

config.color_scheme = scheme_for_appearance(get_appearance())
config.colors = {
  background = bg_for_appearance(get_appearance())
}
--config.font = wezterm.font("Hack Nerd Font")
--config.font = wezterm.font("DejaVuSansM")
--config.font = wezterm.font("Fira Code")
-- To get exact facefont name -> fc-list : family | grep -i DejaVu
config.font = wezterm.font("DejaVuSansM Nerd Font Mono")

config.font_size = 12.0

config.window_background_opacity = 1.0
--config.window_background_opacity = 0.92
--config.window_background_opacity = 0.78
--config.window_background_opacity = 0.20

--config.macos_window_background_blur = 50
config.macos_window_background_blur = 0

-- Disable the large fancy title header
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.window_decorations = "RESIZE"
config.mouse_bindings = {
	-- Ctrl-click will open the link under the mouse cursor
	{
	  event = { Up = { streak = 1, button = 'Left' } },
	  mods = 'CTRL',
	  action = wezterm.action.OpenLinkAtMouseCursor,
	}
}

-- High refresh rate cursor physics and distinct modes
--config.default_cursor_style = "BlinkingBar"
--config.cursor_blink_rate = 600
--config.cursor_blink_ease_in = "EaseIn"
--config.cursor_blink_ease_out = "EaseOut"

-- Custom rules to click on Git SHAs, paths, and URLs directly
config.hyperlink_rules = wezterm.default_hyperlink_rules()

-- Dim unfocused windows so the focused one is obvious at a glance.
local UNFOCUSED_FOREGROUND_TEXT_HSB = { hue = 1.0, saturation = 0.65, brightness = 0.45 }
local UNFOCUSED_WINDOW_BACKGROUND_OPACITY = 1.00

-- get_config_overrides() hands back a copy, so the current value is never the
-- same table we last stored; compare the fields instead of the identity.
local function same_text_hsb(actual, expected)
	if actual == nil or expected == nil then
		return actual == expected
	end
	return actual.hue == expected.hue
		and actual.saturation == expected.saturation
		and actual.brightness == expected.brightness
end

wezterm.on("window-focus-changed", function(window)
	local overrides = window:get_config_overrides() or {}
	local text_hsb, opacity
	if not window:is_focused() then
		text_hsb = UNFOCUSED_FOREGROUND_TEXT_HSB
		opacity = UNFOCUSED_WINDOW_BACKGROUND_OPACITY
	end

	-- Only write when one of the two values we own actually changes; a redundant
	-- set_config_overrides() call would trigger another config reload.
	if same_text_hsb(overrides.foreground_text_hsb, text_hsb) and overrides.window_background_opacity == opacity then
		return
	end

	overrides.foreground_text_hsb = text_hsb
	overrides.window_background_opacity = opacity
	window:set_config_overrides(overrides)
end)

return config

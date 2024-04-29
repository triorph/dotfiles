-- Pull in the wezterm API

local wezterm = require 'wezterm'



-- This will hold the configuration.

local config = wezterm.config_builder()

config.wsl_domains = {
  {
    -- The name of this specific domain.  Must be unique amonst all types
    -- of domain in the configuration file.
    name = 'WSL:Ubuntu',

    -- The name of the distribution.  This identifies the WSL distribution.
    -- It must match a valid distribution from your `wsl -l -v` output in
    -- order for the domain to be useful.
    distribution = 'Ubuntu',
  },
}
config.default_domain = 'WSL:Ubuntu'

-- This is where you actually apply your config choices



-- borderless
config.window_decorations = "NONE"

config.color_scheme = 'Tokyo Night'
-- set the font
config.font =
    wezterm.font('JetBrains Mono', { weight = 'Bold', italic = false })
config.font_size = 17
config.tab_bar_at_bottom = true
-- wezterm term requires installing it via:
-- tempfile=$(mktemp) \
--  && curl -o $tempfile https://raw.githubusercontent.com/wez/wezterm/main/termwiz/data/wezterm.terminfo \
--  && tic -x -o ~/.terminfo $tempfile \
--  && rm $tempfile
config.term = "wezterm"

-- and finally, return the configuration to wezterm

return config

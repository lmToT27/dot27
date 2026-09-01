local M = {}

local function get_dot27_accent()
  local accent_file = vim.fn.expand("~/.cache/theme/prompt_color.txt")
  local file = io.open(accent_file, "r")
  local accent = "#f38ba8"
  if file then
    local hex = file:read("l")
    if hex and hex:match("^#%x%x%x%x%x%x$") then
      accent = hex
    end
    file:close()
  end
  return accent
end

local my_accent = get_dot27_accent()

-- dot27 light/dark sync: base46 has no "tokyonight-day" counterpart to the
-- built-in "tokyonight" theme, so github_light stands in for light mode.
-- Live-reload on mode changes is wired in lua/theme_sync.lua.
M.dot27_dark_theme = "tokyonight"
M.dot27_light_theme = "github_light"

function M.dot27_theme_for_mode()
  local mode_file = vim.fn.expand("~/.cache/theme/mode")
  local file = io.open(mode_file, "r")
  local mode = "dark"
  if file then
    local content = file:read("l")
    if content == "light" then
      mode = "light"
    end
    file:close()
  end
  return mode == "light" and M.dot27_light_theme or M.dot27_dark_theme
end

vim.api.nvim_create_autocmd({"UIEnter", "ColorScheme"}, {
  callback = function()
    vim.api.nvim_set_hl(0, "NvdashAscii", { fg = my_accent, bold = true })
    vim.api.nvim_set_hl(0, "NvdashButtons", { fg = my_accent })
  end,
})

M.base46 = {
  transparency = true,
  theme = M.dot27_theme_for_mode(),
  theme_toggle = { M.dot27_dark_theme, M.dot27_light_theme },
  hl_override = {
    NvdashAscii = { fg = my_accent },
    NvdashButtons = { fg = my_accent },
  },
}

M.ui = {
  statusline = {
    theme = "vscode",
    separator_style = "round",
  },
  tabufline = {
    enabled = true,
    lazyload = false,
    order = { "treeOffset", "buffers", "tabs" },
  },
}

local nvdash_center_pad = string.rep(" ", 8)

local function nvdash_center(s)
  return nvdash_center_pad .. s
end

M.nvdash = {
  load_on_startup = true,
  header = function()
    local lines
    if vim.o.columns < 79 then
      lines = { "", "NEOVIM", "" }
    else
      lines = {
        "███╗   ██╗ ███████╗  ██████╗  ██╗   ██╗ ██╗ ███╗   ███╗",
        "████╗  ██║ ██╔════╝ ██╔═══██╗ ██║   ██║ ██║ ████╗ ████║",
        "██╔██╗ ██║ █████╗   ██║   ██║ ██║   ██║ ██║ ██╔████╔██║",
        "██║╚██╗██║ ██╔══╝   ██║   ██║ ╚██╗ ██╔╝ ██║ ██║╚██╔╝██║",
        "██║ ╚████║ ███████╗ ╚██████╔╝  ╚████╔╝  ██║ ██║ ╚═╝ ██║",
        "╚═╝  ╚═══╝ ╚══════╝  ╚═════╝    ╚═══╝   ╚═╝ ╚═╝     ╚═╝",
        "",
      }
    end
    return vim.tbl_map(nvdash_center, lines)
  end,
  buttons = {
    { txt = nvdash_center("  Find File"), keys = "ff", cmd = "Telescope find_files" },
    { txt = nvdash_center("  Recent Files"), keys = "fo", cmd = "Telescope oldfiles" },
    { txt = nvdash_center("󰈭  Find Word"), keys = "fw", cmd = "Telescope live_grep" },
    { txt = nvdash_center("󱥚  Themes"), keys = "th", cmd = ":lua require('nvchad.themes').open()" },
    { txt = nvdash_center("  Mappings"), keys = "ch", cmd = "NvCheatsheet" },
  },
}

return M

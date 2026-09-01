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

vim.api.nvim_create_autocmd({"UIEnter", "ColorScheme"}, {
  callback = function()
    vim.api.nvim_set_hl(0, "NvdashAscii", { fg = my_accent, bold = true })
    vim.api.nvim_set_hl(0, "NvdashButtons", { fg = my_accent })
  end,
})

M.base46 = {
  transparency = true,
  theme = "chadracula",
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

-- Live dark/light sync with dot27's shell-level theme toggle
-- (~/dot27/dotfiles/scripts/toggle-theme-mode.sh writes "light"/"dark" into
-- ~/.cache/theme/mode and signals every zsh + nvim process). See
-- dot27_theme_for_mode() in chadrc.lua for the startup half of this.

local function sync_theme()
  package.loaded.chadrc = nil
  local chadrc = require "chadrc"
  local target = chadrc.dot27_theme_for_mode()

  local nvconfig = require "nvconfig"
  if nvconfig.base46.theme == target then
    return
  end

  nvconfig.base46.theme = target
  require("base46").load_all_highlights()
  vim.notify("Theme synced: " .. target, vim.log.levels.INFO, { title = "dot27" })
end

local signal = vim.uv.new_signal()
signal:start("sigusr1", function()
  -- libuv callbacks run outside Neovim's main event loop — API calls are
  -- only safe once scheduled back onto it.
  vim.schedule(sync_theme)
end)

-- Pinned on _G (a plain Lua table, unlike vim.g which bridges to VimL and
-- doesn't hold arbitrary userdata) so the handle can't be GC'd mid-session.
_G.dot27_theme_signal = signal

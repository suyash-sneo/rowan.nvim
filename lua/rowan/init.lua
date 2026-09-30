local config = require('rowan.config')
local keymaps = require('rowan.keymaps')

local M = {}

function M.setup(opts)
  config.setup(opts)
end

function M.attach(buf)
  local bo = vim.bo[buf]
  bo.textwidth = config.options.width
  bo.expandtab = true
  bo.shiftwidth = 2
  bo.softtabstop = 2
  -- textwidth is for gq; don't hard-wrap while typing tables and URLs.
  bo.formatoptions = bo.formatoptions:gsub('t', '')

  keymaps.apply(buf)

  vim.b[buf].undo_ftplugin = 'setlocal textwidth< expandtab< shiftwidth< softtabstop< formatoptions<'
    .. " | lua require('rowan.keymaps').remove(0)"
end

return M

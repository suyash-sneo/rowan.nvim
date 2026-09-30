local config = require('rowan.config')
local keymaps = require('rowan.keymaps')

local M = {}

function M.setup(opts)
  config.setup(opts)
end

function M.attach(buf)
  local bo = vim.bo[buf]
  bo.textwidth = config.options.width
  bo.autoindent = true
  bo.expandtab = true
  bo.shiftwidth = 2
  bo.softtabstop = 2
  -- textwidth is for gq; don't hard-wrap while typing tables and URLs.
  bo.formatoptions = bo.formatoptions:gsub('t', '')

  local opt = vim.opt_local
  opt.foldmethod = 'expr'
  opt.foldexpr = "v:lua.require'rowan.fold'.expr(v:lnum)"
  opt.foldtext = "v:lua.require'rowan.fold'.text()"
  opt.foldlevel = 99

  keymaps.apply(buf)

  -- Folds made by foldexpr outlive it as manual folds, so drop them before restoring.
  vim.b[buf].undo_ftplugin = 'setlocal foldmethod=manual | silent! normal! zE'
    .. ' | setlocal foldmethod< foldexpr< foldtext< foldlevel<'
    .. ' textwidth< autoindent< expandtab< shiftwidth< softtabstop< formatoptions<'
    .. " | lua require('rowan.keymaps').remove(0)"
end

return M

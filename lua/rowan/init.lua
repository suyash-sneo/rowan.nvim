local config = require('rowan.config')
local grid = require('rowan.grid')
local keymaps = require('rowan.keymaps')
local kv = require('rowan.kv')
local ref = require('rowan.ref')

local M = {}

function M.setup(opts)
  config.setup(opts)
end

local group = vim.api.nvim_create_augroup('rowan_buffer', { clear = true })

local function watch(buf)
  vim.api.nvim_clear_autocmds({ group = group, buffer = buf })
  local function on(event, callback)
    vim.api.nvim_create_autocmd(event, { group = group, buffer = buf, callback = callback })
  end
  on('TextChangedI', grid.on_text_changed)
  on('InsertLeave', function()
    grid.on_insert_leave()
    kv.align({ join_undo = true })
  end)
  on('BufWritePre', function()
    kv.align({ join_undo = true })
  end)
  on('BufWritePost', function()
    ref.check(buf)
  end)
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
  vim.b[buf].rowan_live_align = config.options.live_align
  watch(buf)
  ref.check(buf)

  -- Folds made by foldexpr outlive it as manual folds, so drop them before restoring.
  -- :normal would swallow the rest of the line, hence exe.
  vim.b[buf].undo_ftplugin = 'setlocal foldmethod=manual | silent! exe "normal! zE"'
    .. ' | setlocal foldmethod< foldexpr< foldtext< foldlevel<'
    .. ' textwidth< autoindent< expandtab< shiftwidth< softtabstop< formatoptions<'
    .. " | lua require('rowan').detach(0)"
end

function M.detach(buf)
  keymaps.remove(buf)
  ref.clear(buf)
  vim.api.nvim_clear_autocmds({ group = group, buffer = buf })
end

return M

local M = {}

M.defaults = {
  width = 100,
  notes_dirs = {},
  prefix = '<space>',
  live_align = true,
  keymaps = true,
}

M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
  opts = opts or {}
  vim.validate('width', opts.width, 'number', true)
  vim.validate('notes_dirs', opts.notes_dirs, 'table', true)
  vim.validate('prefix', opts.prefix, 'string', true)
  vim.validate('live_align', opts.live_align, 'boolean', true)
  vim.validate('keymaps', opts.keymaps, 'boolean', true)

  M.options = vim.tbl_deep_extend('force', M.defaults, opts)
  M.options.notes_dirs = vim.tbl_map(vim.fs.normalize, M.options.notes_dirs)
end

return M

-- Resolves symlinks via the parent dir, so it also works for files not written yet.
local function realpath(path)
  path = vim.fs.normalize(path)
  local dir = vim.uv.fs_realpath(vim.fs.dirname(path))
  return dir and (dir .. '/' .. vim.fs.basename(path)) or path
end

local function in_notes_dir(path)
  path = realpath(path)
  for _, dir in ipairs(require('rowan.config').options.notes_dirs) do
    if vim.startswith(path, dir .. '/') then
      return true
    end
  end
  return false
end

vim.filetype.add({
  pattern = {
    ['.*%.txt'] = function(path)
      if in_notes_dir(path) then
        return 'rowan'
      end
    end,
  },
})

local highlight = require('rowan.highlight')
highlight.apply()
vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.api.nvim_create_augroup('rowan_highlight', {}),
  callback = highlight.apply,
})

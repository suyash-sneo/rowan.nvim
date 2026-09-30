local config = require('rowan.config')

local M = {}

--- Where notes live: the configured notes_dirs, or else the current file's directory.
function M.roots()
  if #config.options.notes_dirs > 0 then
    return config.options.notes_dirs
  end
  return { vim.fn.expand('%:p:h') }
end

--- Every .txt file under the roots.
function M.list()
  local files = {}
  for _, root in ipairs(M.roots()) do
    vim.list_extend(files, vim.fs.find(function(name)
      return name:match('%.txt$') ~= nil
    end, { path = root, type = 'file', limit = math.huge }))
  end
  return files
end

function M.name(path)
  return vim.fn.fnamemodify(path, ':t:r')
end

--- The file for [[name]]: next to the current file first, then anywhere under the roots.
--- Returns the sibling path, not yet existing, when there is no such note.
function M.resolve(name)
  local sibling = vim.fs.joinpath(vim.fn.expand('%:p:h'), name .. '.txt')
  if vim.uv.fs_stat(sibling) then
    return sibling
  end
  for _, path in ipairs(M.list()) do
    if M.name(path):lower() == name:lower() then
      return path
    end
  end
  return sibling
end

return M

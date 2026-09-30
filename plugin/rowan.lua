local function in_notes_dir(path)
  path = vim.fs.normalize(path)
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

if vim.b.did_ftplugin then
  return
end
vim.b.did_ftplugin = true

require('rowan').attach(0)

local config = require('rowan.config')

local M = {}

-- A leading P in lhs stands for config.options.prefix.
M.list = {
  {
    group = 'Help',
    mode = 'n',
    lhs = 'P?',
    desc = 'Show rowan keys',
    rhs = function()
      require('rowan.cheatsheet').open()
    end,
  },
}

local function expand(lhs)
  return (lhs:gsub('^P', function()
    return config.options.prefix
  end))
end

--- M.list with each lhs expanded to the real key sequence.
function M.entries()
  return vim.tbl_map(function(entry)
    return vim.tbl_extend('force', entry, { lhs = expand(entry.lhs) })
  end, M.list)
end

function M.apply(buf)
  if not config.options.keymaps then
    return
  end
  for _, entry in ipairs(M.entries()) do
    vim.keymap.set(entry.mode, entry.lhs, entry.rhs, { buffer = buf, desc = 'rowan: ' .. entry.desc })
  end
end

function M.remove(buf)
  for _, entry in ipairs(M.entries()) do
    pcall(vim.keymap.del, entry.mode, entry.lhs, { buffer = buf })
  end
end

return M

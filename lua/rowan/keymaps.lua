local config = require('rowan.config')
local heading = require('rowan.heading')

local M = {}

M.list = {}

-- A leading P in lhs stands for config.options.prefix.
local function add(group, mode, lhs, desc, rhs)
  table.insert(M.list, { group = group, mode = mode, lhs = lhs, desc = desc, rhs = rhs })
end

add('Help', 'n', 'P?', 'Show rowan keys', function()
  require('rowan.cheatsheet').open()
end)

for level = 1, 3 do
  add('Headings', 'n', 'P' .. level, 'Make line an H' .. level, function()
    heading.set(level)
  end)
end
add('Headings', 'n', 'P0', 'Back to plain text', function()
  heading.set(0)
end)
add('Headings', 'n', 'Ph', 'Cycle heading down (plain > H1 > H2 > H3)', function()
  heading.cycle(1)
end)
add('Headings', 'n', 'PH', 'Cycle heading up', function()
  heading.cycle(-1)
end)
add('Headings', 'n', '>>', 'Demote heading (or indent line)', function()
  heading.shift(1)
end)
add('Headings', 'n', '<<', 'Promote heading (or outdent line)', function()
  heading.shift(-1)
end)

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

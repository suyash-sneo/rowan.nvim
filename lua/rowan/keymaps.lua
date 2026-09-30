local config = require('rowan.config')
local heading = require('rowan.heading')
local inline = require('rowan.inline')
local list = require('rowan.list')
local nav = require('rowan.nav')
local pickers = require('rowan.pickers')

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

local motion = { 'n', 'x', 'o' }
add('Navigate', motion, ']]', 'Next heading', function()
  nav.jump(1)
end)
add('Navigate', motion, '[[', 'Previous heading', function()
  nav.jump(-1)
end)
for level = 1, 3 do
  add('Navigate', motion, ']' .. level, 'Next H' .. level, function()
    nav.jump(1, level)
  end)
  add('Navigate', motion, '[' .. level, 'Previous H' .. level, function()
    nav.jump(-1, level)
  end)
end
add('Navigate', 'n', 'Po', 'Outline of this file', pickers.outline)

local text = { 'n', 'x' }
add('Inline', text, 'Ps', 'Toggle STRONG (uppercase)', function()
  inline.toggle('strong')
end)
add('Inline', text, 'Pi', 'Toggle ==soft==', function()
  inline.toggle('soft')
end)
add('Inline', text, 'Pc', 'Toggle `literal`', function()
  inline.toggle('literal')
end)

add('Tasks', text, 'Px', 'Cycle task: plain > [ ] > [x] > [ ]', list.task_cycle)
add('Tasks', text, 'P>', 'Mark task moved [>]', list.task_moved)

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

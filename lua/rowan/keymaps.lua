local config = require('rowan.config')
local grid = require('rowan.grid')
local grid_edit = require('rowan.grid_edit')
local heading = require('rowan.heading')
local inline = require('rowan.inline')
local keys = require('rowan.keys')
local kv = require('rowan.kv')
local link = require('rowan.link')
local list = require('rowan.list')
local nav = require('rowan.nav')
local pickers = require('rowan.pickers')
local ref = require('rowan.ref')

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
add('Navigate', 'n', 'PO', 'Headings of all notes', pickers.all_headings)

add('Links', 'n', '<CR>', 'Follow [[note]], [n] or URL', link.follow)
add('Links', 'n', '<BS>', 'Go back', '<C-o>')
add('Links', 'n', 'Pl', 'Insert [[link]] to a note', link.insert)
add('Links', 'n', 'Pf', 'Find note', pickers.find)
add('Links', 'n', 'P/', 'Search all notes', pickers.grep)
add('Links', 'n', 'Pr', 'Turn URL into a [n] reference', ref.from_url)

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

add('Lists (insert mode)', 'i', '<CR>', 'Continue list, or end it on an empty item', list.enter)
add('Lists (insert mode)', 'i', '<Tab>', 'Nest list item deeper', function()
  list.indent(1)
end)
add('Lists (insert mode)', 'i', '<S-Tab>', 'Nest list item shallower', function()
  list.indent(-1)
end)

add('Tables', 'n', 'Pa', 'Align table (or key :: value block)', function()
  if not grid.align() then
    kv.align()
  end
end)
add('Tables', 'n', 'PA', 'Toggle live table align', grid.toggle_live_align)
add('Tables', 'n', 'Pn', 'New table (asks for columns x rows)', grid_edit.new)
add('Tables', 'n', 'Pki', 'Insert column after this one', grid_edit.insert_column)
add('Tables', 'n', 'Pkd', 'Delete column', grid_edit.delete_column)
add('Tables', 'n', 'Pkh', 'Move column left', function()
  grid_edit.move_column(-1)
end)
add('Tables', 'n', 'Pkl', 'Move column right', function()
  grid_edit.move_column(1)
end)
add('Tables', 'n', 'Pkr', 'Add row below', grid_edit.add_row)
add('Tables', 'n', 'Pkx', 'Delete row', grid_edit.delete_row)

-- Outside a table these keys keep their usual insert-mode meaning.
local cell_moves = {
  { '<C-i>', 'up', 'Table: cell above' },
  { '<C-k>', 'down', 'Table: cell below' },
  { '<C-j>', 'left', 'Table: previous cell' },
  { '<C-l>', 'right', 'Table: next cell' },
}
for _, move in ipairs(cell_moves) do
  local key, dir, desc = unpack(move)
  add('Tables (insert mode)', 'i', key, desc, function()
    if not grid.move(dir) then
      keys.fall_back('i', key)
    end
  end)
end

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

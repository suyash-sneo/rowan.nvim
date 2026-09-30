local command = require('rowan.command')
local keymaps = require('rowan.keymaps')
local parse = require('rowan.parse')

local M = {}

local GAP = 4

local function rows()
  local result = {}
  for _, entry in ipairs(keymaps.entries()) do
    table.insert(result, { group = entry.group, key = entry.lhs, desc = entry.desc })
  end
  for _, name in ipairs(command.names()) do
    table.insert(result, { group = 'Commands', key = ':Rowan ' .. name, desc = command.subcommands[name].desc })
  end
  return result
end

-- One block of lines per group, headed by an H3 so the rowan syntax highlights it.
local function group_blocks()
  local all = rows()
  local key_width = 0
  for _, row in ipairs(all) do
    key_width = math.max(key_width, #row.key)
  end

  local blocks, width = {}, 0
  for _, row in ipairs(all) do
    if #blocks == 0 or blocks[#blocks].group ~= row.group then
      table.insert(blocks, { group = row.group })
    end
    local line = ('  %-' .. key_width .. 's   %s'):format(row.key, row.desc)
    table.insert(blocks[#blocks], line)
    width = math.max(width, #line)
  end
  for _, block in ipairs(blocks) do
    table.insert(block, 1, parse.render_heading(3, block.group, width)[1])
  end
  return blocks, width
end

-- Fills columns in order, starting a new one once a column reaches its share of the lines.
local function split(blocks, count)
  local total = 0
  for _, block in ipairs(blocks) do
    total = total + #block + 1
  end
  local target = math.ceil(total / count)

  local columns = { {} }
  for _, block in ipairs(blocks) do
    local column = columns[#columns]
    if #column > 0 and #column + #block > target and #columns < count then
      column = {}
      table.insert(columns, column)
    end
    if #column > 0 then
      table.insert(column, '')
    end
    vim.list_extend(column, block)
  end
  return columns
end

local function side_by_side(columns, width)
  local height = 0
  for _, column in ipairs(columns) do
    height = math.max(height, #column)
  end
  local lines = {}
  for i = 1, height do
    local parts = {}
    for _, column in ipairs(columns) do
      table.insert(parts, ('%-' .. width .. 's'):format(column[i] or ''))
    end
    lines[i] = (table.concat(parts, (' '):rep(GAP)):gsub('%s+$', ''))
  end
  return lines
end

-- At least two columns when they fit, more if the sheet is still taller than the screen.
local function build_lines()
  local blocks, width = group_blocks()
  local fit = math.floor((vim.o.columns - 2 + GAP) / (width + GAP))
  local most = math.max(1, math.min(fit, #blocks))
  local lines
  for count = math.min(2, most), most do
    lines = side_by_side(split(blocks, count), width)
    if #lines <= vim.o.lines - 4 then
      break
    end
  end
  return lines
end

function M.open()
  local lines = build_lines()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].syntax = 'rowan'
  vim.bo[buf].modifiable = false

  -- Leave room for the border so small terminals still show the whole float.
  local width = 0
  for _, line in ipairs(lines) do
    width = math.max(width, #line)
  end
  width = math.min(width, vim.o.columns - 2)
  local height = math.min(#lines, vim.o.lines - 4)
  vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    style = 'minimal',
    border = 'rounded',
    title = ' rowan keys ',
    title_pos = 'center',
    width = width,
    height = height,
    row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
    col = math.max(0, math.floor((vim.o.columns - width) / 2) - 1),
  })
  for _, key in ipairs({ 'q', '<Esc>' }) do
    vim.keymap.set('n', key, '<cmd>close<cr>', { buffer = buf, nowait = true })
  end
end

return M

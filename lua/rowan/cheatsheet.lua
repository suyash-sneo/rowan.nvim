local command = require('rowan.command')
local keymaps = require('rowan.keymaps')
local parse = require('rowan.parse')

local M = {}

local WIDTH = 60

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

-- Rendered in the rowan format itself, so groups show up as highlighted H3 headings.
local function build_lines()
  local all = rows()
  local key_width = 0
  for _, row in ipairs(all) do
    key_width = math.max(key_width, #row.key)
  end

  local lines, group = {}, nil
  for _, row in ipairs(all) do
    if row.group ~= group then
      group = row.group
      if #lines > 0 then
        table.insert(lines, '')
      end
      table.insert(lines, parse.render_heading(3, group, WIDTH)[1])
    end
    table.insert(lines, ('  %-' .. key_width .. 's   %s'):format(row.key, row.desc))
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
  local width = math.min(WIDTH, vim.o.columns - 2)
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

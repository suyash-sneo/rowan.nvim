local keys = require('rowan.keys')
local parse = require('rowan.parse')

local M = {}

local function is_heading_or_rule(line)
  return line:match('^%s*[=-]+%s*$') or parse.heading({ line }, 1)
end

local function as_task(line, state)
  if is_heading_or_rule(line) then
    return line
  end
  local item = parse.list_item(line)
  local indent, text
  if item then
    -- '- [ ] x' is a bullet holding a task; keep one checkbox.
    indent, text = item.indent, item.text:gsub('^%[[ x>]%] ', '')
  else
    indent, text = line:match('^(%s*)(.*)$')
  end
  if text == '' then
    return line
  end
  return ('%s[%s] %s'):format(indent, state, text)
end

local function task_state(line)
  local item = parse.list_item(line)
  return item and item.task
end

local cycle_next = { [' '] = 'x', x = ' ', ['>'] = ' ' }

local function cycled(line)
  return as_task(line, cycle_next[task_state(line)] or ' ')
end

local function moved(line)
  return as_task(line, task_state(line) == '>' and ' ' or '>')
end

-- The visual selection, or count lines from the cursor.
local function target_lines()
  if vim.fn.mode():find('^[vV\22]') then
    vim.cmd('normal! \27')
    return vim.fn.line("'<"), vim.fn.line("'>")
  end
  local first = vim.fn.line('.')
  return first, math.min(first + vim.v.count1 - 1, vim.fn.line('$'))
end

local function update_lines(fn)
  local first, last = target_lines()
  local old = vim.api.nvim_buf_get_lines(0, first - 1, last, false)
  local new = vim.tbl_map(fn, old)
  if not vim.deep_equal(old, new) then
    vim.api.nvim_buf_set_lines(0, first - 1, last, false, new)
  end
end

--- Cycles plain > [ ] > [x] > [ ]; a bullet becomes a task.
function M.task_cycle()
  update_lines(cycled)
end

--- Marks [>] moved, or back to [ ] if it already is.
function M.task_moved()
  update_lines(moved)
end

local markers = { '-', '*', '+' }

-- Nesting picks the marker: - then * then +, repeating.
local function marker_for(indent)
  local depth = math.floor(#indent / vim.fn.shiftwidth())
  return markers[depth % #markers + 1]
end

local function prefix_length(item)
  return #item.indent + (item.task and 4 or 2)
end

-- The list item on the cursor line, if the cursor is past its marker.
local function item_before_cursor()
  local item = parse.list_item(vim.api.nvim_get_current_line())
  if item and vim.fn.col('.') > prefix_length(item) then
    return item
  end
end

--- Insert-mode <CR>: starts the next item, or ends the list on an empty one.
function M.enter()
  local item = not keys.completion_visible() and item_before_cursor()
  if not item then
    keys.fall_back('i', '<CR>')
  elseif vim.trim(item.text) == '' then
    vim.api.nvim_set_current_line('')
  else
    keys.feed(vim.keycode('<CR>') .. (item.task and '[ ] ' or item.marker .. ' '))
  end
end

local function shift_item(item, dir)
  local width = #item.indent + dir * vim.fn.shiftwidth()
  if width < 0 then
    return
  end
  local indent = (' '):rep(width)
  local head = item.task and ('[%s]'):format(item.task) or marker_for(indent)
  local line = vim.api.nvim_get_current_line()
  local new = ('%s%s %s'):format(indent, head, item.text)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  vim.api.nvim_set_current_line(new)
  vim.api.nvim_win_set_cursor(0, { row, math.max(0, col + #new - #line) })
end

--- Insert-mode <Tab>/<S-Tab>: nests a list item deeper (dir 1) or shallower (-1).
function M.indent(dir)
  local item = not keys.completion_visible() and parse.list_item(vim.api.nvim_get_current_line())
  if item then
    shift_item(item, dir)
  else
    keys.fall_back('i', dir > 0 and '<Tab>' or '<S-Tab>')
  end
end

return M

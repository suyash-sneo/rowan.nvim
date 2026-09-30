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

return M

local keys = require('rowan.keys')
local parse = require('rowan.parse')

local M = {}

local function pipe_positions(line)
  local positions = {}
  for pos in line:gmatch('()|') do
    table.insert(positions, pos)
  end
  return positions
end

-- While a row is being typed, show only the cells typed so far, so the next | starts the
-- next cell instead of adding a column.
local function only_typed_cells(line, count)
  return line:sub(1, pipe_positions(line)[count + 1])
end

-- The cell holding 0-based column col, and how far into the cell's text the cursor is.
local function cell_at(line, col)
  local pipes = pipe_positions(line)
  local k = #vim.tbl_filter(function(pos)
    return pos <= col
  end, pipes)
  local raw = parse.table_cells(line)[k]
  if raw then
    return k, math.max(0, col - pipes[k] - #raw:match('^%s*'))
  end
end

--- The table under the cursor, unless it is an example in a code block: { first, last,
--- lines, rows (from parse_table), r (cursor row), k and offset (cursor cell, if any) }.
function M.current()
  local lnum, col = unpack(vim.api.nvim_win_get_cursor(0))
  if not parse.is_table_line(vim.fn.getline(lnum)) then
    return
  end
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  if parse.in_code(lines, lnum) then
    return
  end
  local first, last = parse.table_range(lines, lnum)
  local t = { first = first, last = last, lines = vim.list_slice(lines, first, last) }
  t.rows = parse.parse_table(t.lines)
  t.r = lnum - first + 1
  t.k, t.offset = cell_at(t.lines[t.r], col)
  return t
end

--- Replaces the lines of table t with rows, aligned. opts.keep_typed leaves the cursor row
--- as typed so far, opts.join_undo joins the change to the previous undo step.
function M.write(t, rows, opts)
  opts = opts or {}
  local new = parse.render_table(rows, t.lines[1]:match('^%s*'))
  if new and opts.keep_typed and rows[t.r] ~= 'rule' then
    new[t.r] = only_typed_cells(new[t.r], math.max(1, #rows[t.r]))
  end
  if not new or vim.deep_equal(new, t.lines) then
    return
  end
  if opts.join_undo then
    pcall(vim.cmd.undojoin)
  end
  vim.api.nvim_buf_set_lines(0, t.first - 1, t.last, false, new)
end

--- Puts the cursor offset bytes into the text of cell k on line lnum, or at the end of it.
function M.put_cursor(lnum, k, offset)
  local line = vim.fn.getline(lnum)
  local cells = parse.table_cells(line)
  if #cells == 0 then
    return
  end
  k = math.min(k, #cells)
  local text_start = cells[k]:find('%S') or math.min(2, #cells[k] + 1)
  local col = pipe_positions(line)[k] + text_start - 1 + (offset or #vim.trim(cells[k]))
  vim.api.nvim_win_set_cursor(0, { lnum, math.min(col, #line) })
end

-- The spaces before the cursor are kept, so live align doesn't eat a space just typed.
local function typed_text(raw, offset)
  local text = raw:gsub('^%s+', '')
  return text:sub(1, offset) .. text:sub(offset + 1):gsub('%s+$', '')
end

local function align(opts)
  local t = M.current()
  if not t then
    return false
  end
  if t.k and opts.keep_typed then
    t.rows[t.r][t.k] = typed_text(parse.table_cells(t.lines[t.r])[t.k], t.offset)
  end
  M.write(t, t.rows, opts)
  if t.k then
    M.put_cursor(t.first + t.r - 1, t.k, math.min(t.offset, #t.rows[t.r][t.k]))
  end
  return true
end

--- Aligns the table under the cursor; returns false if there is none.
function M.align()
  return align({})
end

function M.on_text_changed()
  if vim.b.rowan_live_align and not keys.completion_visible() then
    align({ keep_typed = true, join_undo = true })
  end
end

function M.on_insert_leave()
  if vim.b.rowan_live_align then
    align({ join_undo = true })
  end
end

function M.toggle_live_align()
  vim.b.rowan_live_align = not vim.b.rowan_live_align
  vim.notify('rowan: live table align ' .. (vim.b.rowan_live_align and 'on' or 'off'))
end

function M.column_count(rows)
  local count = 0
  for _, row in ipairs(rows) do
    if row ~= 'rule' then
      count = math.max(count, #row)
    end
  end
  return count
end

-- In a row still being typed, moving right past its last cell opens the next one.
local function open_next_cell(lnum)
  local line = vim.fn.getline(lnum):gsub('%s+$', '')
  if not line:match('|$') then
    line = line .. ' |'
  end
  line = line .. ' '
  vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, false, { line })
  vim.api.nvim_win_set_cursor(0, { lnum, #line })
end

local steps = { up = { -1, 0 }, down = { 1, 0 }, left = { 0, -1 }, right = { 0, 1 } }

--- Moves to the end of the neighbouring cell, stopping at the table's edges. Returns false
--- outside a table cell.
function M.move(dir)
  local t = M.current()
  if not (t and t.k) then
    return false
  end
  local dr, dk = unpack(steps[dir])
  local r, k = t.r + dr, t.k + dk
  while t.rows[r] == 'rule' do
    r = r + dr
  end
  if t.rows[r] and k >= 1 and k <= #t.rows[t.r] then
    M.put_cursor(t.first + r - 1, k)
  elseif dir == 'right' and k <= M.column_count(t.rows) then
    open_next_cell(t.first + t.r - 1)
  end
  return true
end

return M

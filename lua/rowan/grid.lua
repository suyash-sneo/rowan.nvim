local keys = require('rowan.keys')
local parse = require('rowan.parse')

local M = {}

-- The table around lnum, unless it is an example inside a code block.
local function table_at(lnum)
  if not parse.is_table_line(vim.fn.getline(lnum)) then
    return
  end
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  if parse.in_code(lines, lnum) then
    return
  end
  local first, last = parse.table_range(lines, lnum)
  return first, last, vim.list_slice(lines, first, last)
end

local function pipe_positions(line)
  local positions = {}
  for pos in line:gmatch('()|') do
    table.insert(positions, pos)
  end
  return positions
end

-- The cell holding 0-based column col, how far into its text the cursor is, and its text.
-- keep_typed keeps spaces up to the cursor, so aligning while typing doesn't eat them.
local function cursor_cell(line, col, keep_typed)
  local pipes = pipe_positions(line)
  local k = #vim.tbl_filter(function(pos)
    return pos <= col
  end, pipes)
  local raw = parse.table_cells(line)[k]
  if not raw then
    return
  end
  local lead = #raw:match('^%s*')
  local text = raw:sub(lead + 1)
  local offset = math.max(0, col - pipes[k] - lead)
  if keep_typed then
    text = text:sub(1, offset) .. text:sub(offset + 1):gsub('%s+$', '')
  else
    text = vim.trim(text)
  end
  return k, math.min(offset, #text), text
end

local function align(opts)
  local lnum, col = unpack(vim.api.nvim_win_get_cursor(0))
  local first, last, lines = table_at(lnum)
  if not first then
    return false
  end
  local rows = parse.parse_table(lines)
  local r = lnum - first + 1
  local k, offset, text = cursor_cell(lines[r], col, opts.keep_typed)
  if k then
    rows[r][k] = text
  end

  local new = parse.render_table(rows, lines[1]:match('^%s*'))
  if not new or vim.deep_equal(new, lines) then
    return true
  end
  if opts.join_undo then
    pcall(vim.cmd.undojoin)
  end
  vim.api.nvim_buf_set_lines(0, first - 1, last, false, new)
  if k then
    col = pipe_positions(new[r])[k] + 1 + offset
  end
  vim.api.nvim_win_set_cursor(0, { lnum, math.min(col, #new[r]) })
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

local function empty_row(columns)
  local row = {}
  for k = 1, columns do
    row[k] = ''
  end
  return row
end

local function empty_table(columns, rows)
  local grid = { 'rule', empty_row(columns), 'rule' }
  for _ = 1, rows do
    table.insert(grid, empty_row(columns))
  end
  table.insert(grid, 'rule')
  return parse.render_table(grid, '')
end

--- Asks for a size like 3x2 (columns x rows) and inserts an empty table below the cursor.
function M.new()
  vim.ui.input({ prompt = 'Table size (columns x rows): ', default = '3x2' }, function(input)
    local columns, rows = (input or ''):match('^%s*(%d+)%s*[xX]%s*(%d+)%s*$')
    if not columns or tonumber(columns) == 0 then
      return
    end
    local lnum = vim.fn.line('.')
    local lines = empty_table(tonumber(columns), tonumber(rows))
    local gap = vim.fn.getline(lnum):match('%S') and 1 or 0
    if gap == 1 then
      table.insert(lines, 1, '')
    end
    vim.api.nvim_buf_set_lines(0, lnum, lnum, false, lines)
    local header = lnum + gap + 2
    vim.api.nvim_win_set_cursor(0, { header, 2 })
  end)
end

return M

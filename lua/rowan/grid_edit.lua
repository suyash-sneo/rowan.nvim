local grid = require('rowan.grid')
local parse = require('rowan.parse')

local M = {}

local function empty_row(columns)
  local row = {}
  for k = 1, columns do
    row[k] = ''
  end
  return row
end

local function empty_table(columns, rows)
  local grid_rows = { 'rule', empty_row(columns), 'rule' }
  for _ = 1, rows do
    table.insert(grid_rows, empty_row(columns))
  end
  table.insert(grid_rows, 'rule')
  return parse.render_table(grid_rows, '')
end

--- Asks for a size like 3x2 (columns x rows) and inserts an empty table below the cursor.
function M.new()
  vim.ui.input({ prompt = 'Table size (columns x rows): ', default = '3x2' }, function(input)
    local columns, rows = (input or ''):match('^%s*(%d+)%s*[xX]%s*(%d+)%s*$')
    if not columns or tonumber(columns) == 0 then
      if input then
        vim.notify('rowan: size should look like 3x2', vim.log.levels.WARN)
      end
      return
    end
    local lnum = vim.fn.line('.')
    local lines = empty_table(tonumber(columns), tonumber(rows))
    local gap = vim.fn.getline(lnum):match('%S') and 1 or 0
    if gap == 1 then
      table.insert(lines, 1, '')
    end
    if vim.fn.getline(lnum + 1):match('%S') then
      table.insert(lines, '')
    end
    vim.api.nvim_buf_set_lines(0, lnum, lnum, false, lines)
    local header = lnum + gap + 2
    vim.api.nvim_win_set_cursor(0, { header, 2 })
  end)
end

local function cell_rows(rows)
  return vim.tbl_filter(function(row)
    return row ~= 'rule'
  end, rows)
end

-- Runs fn(rows, r, k) on the table under the cursor. fn edits rows in place, with every row
-- padded to full width, and returns the cell to put the cursor in, or nothing to cancel.
local function edit(fn)
  local t = grid.current()
  if not (t and t.k) then
    return
  end
  local columns = grid.column_count(t.rows)
  for _, row in ipairs(cell_rows(t.rows)) do
    vim.list_extend(row, empty_row(columns - #row))
  end
  local r, k = fn(t.rows, t.r, t.k)
  if r then
    grid.write(t, t.rows)
    grid.put_cursor(t.first + r - 1, k)
  end
end

function M.insert_column()
  edit(function(rows, r, k)
    for _, row in ipairs(cell_rows(rows)) do
      table.insert(row, k + 1, '')
    end
    return r, k + 1
  end)
end

function M.delete_column()
  edit(function(rows, r, k)
    if grid.column_count(rows) == 1 then
      return
    end
    for _, row in ipairs(cell_rows(rows)) do
      table.remove(row, k)
    end
    return r, math.min(k, grid.column_count(rows))
  end)
end

function M.move_column(dir)
  edit(function(rows, r, k)
    local j = k + dir
    if j < 1 or j > grid.column_count(rows) then
      return
    end
    for _, row in ipairs(cell_rows(rows)) do
      row[k], row[j] = row[j], row[k]
    end
    return r, j
  end)
end

--- Adds an empty row below the cursor row; below the header, that means after its rule.
function M.add_row()
  edit(function(rows, r, k)
    local at = r + 1
    if rows[at] == 'rule' and rows[at + 1] then
      at = at + 1
    end
    table.insert(rows, at, empty_row(grid.column_count(rows)))
    return at, k
  end)
end

function M.delete_row()
  edit(function(rows, r, k)
    if #cell_rows(rows) == 1 then
      vim.notify('rowan: a table keeps at least one row', vim.log.levels.WARN)
      return
    end
    table.remove(rows, r)
    if rows[r - 1] == 'rule' and rows[r] == 'rule' then
      table.remove(rows, r)
    end
    local target = math.min(r, #rows)
    while rows[target] == 'rule' and target > 1 do
      target = target - 1
    end
    return target, k
  end)
end

return M

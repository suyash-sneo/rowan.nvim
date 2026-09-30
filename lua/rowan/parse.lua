local M = {}

local function is_h1_rule(line)
  return line ~= nil and line:match('^===+$') ~= nil
end

local function between_rules(lines, i)
  local line = lines[i]
  return line ~= nil
    and line:match('%S') ~= nil
    and not is_h1_rule(line)
    and is_h1_rule(lines[i - 1])
    and is_h1_rule(lines[i + 1])
end

-- The rule above must not already be the bottom rule of the H1 before it.
local function is_h1_title(lines, i)
  return between_rules(lines, i) and not is_h1_title(lines, i - 2)
end

-- Finds the H1 whose title or rules include line i; prefers the title above.
local function h1_title_near(lines, i)
  for _, t in ipairs({ i, i - 1, i + 1 }) do
    if is_h1_title(lines, t) then
      return t
    end
  end
end

local function h1(lines, title)
  return { level = 1, text = vim.trim(lines[title]), first = title - 1, last = title + 1 }
end

local function single_line_heading(line, i)
  local h2 = line:match('^== (.-%S) ===+$')
  if h2 then
    return { level = 2, text = h2, first = i, last = i }
  end
  local h3 = line:match('^%-%- (.-%S) %-%-%-+$')
  if h3 then
    return { level = 3, text = h3, first = i, last = i }
  end
end

--- Returns { level, text, first, last } if line i is part of a heading.
function M.heading(lines, i)
  local t = h1_title_near(lines, i)
  if t then
    return h1(lines, t)
  end
  return single_line_heading(lines[i] or '', i)
end

--- Returns every heading in order, skipping ~~~ code blocks.
function M.headings(lines)
  local result, in_code, i = {}, false, 1
  while i <= #lines do
    local h
    if lines[i]:match('^~~~') then
      in_code = not in_code
    elseif not in_code then
      h = between_rules(lines, i + 1) and h1(lines, i + 1) or single_line_heading(lines[i], i)
    end
    if h then
      table.insert(result, h)
      i = h.last + 1
    else
      i = i + 1
    end
  end
  return result
end

--- Returns the line and 0-based column where a heading's title starts.
function M.title_pos(h)
  if h.level == 1 then
    return h.first + 1, 0
  end
  return h.first, 3
end

--- Returns { indent, marker, task, text } for a bullet ('-', '*', '+') or task ([ ], [x], [>]).
function M.list_item(line)
  local indent, task, text = line:match('^(%s*)%[([ x>])%] (.*)$')
  if indent then
    return { indent = indent, task = task, text = text }
  end
  local marker
  indent, marker, text = line:match('^(%s*)([-*+]) (.*)$')
  if indent then
    return { indent = indent, marker = marker, text = text }
  end
end

--- Whether line i sits inside a ~~~ code block.
function M.in_code(lines, i)
  local inside = false
  for n = 1, i - 1 do
    if lines[n]:match('^~~~') then
      inside = not inside
    end
  end
  return inside
end

local function is_table_rule(line)
  return line:match('^%s*%+[-=+]*%s*$') ~= nil
end

function M.is_table_line(line)
  return is_table_rule(line) or line:match('^%s*|') ~= nil
end

--- Returns the first and last line of the table around line i.
function M.table_range(lines, i)
  if not (lines[i] and M.is_table_line(lines[i])) then
    return
  end
  local first, last = i, i
  while lines[first - 1] and M.is_table_line(lines[first - 1]) do
    first = first - 1
  end
  while lines[last + 1] and M.is_table_line(lines[last + 1]) do
    last = last + 1
  end
  return first, last
end

--- Returns a row's cells as typed, between the pipes. A closing pipe is optional.
function M.table_cells(line)
  local cells = vim.split(line, '|', { plain = true })
  table.remove(cells, 1)
  if cells[#cells] and not cells[#cells]:match('%S') then
    table.remove(cells)
  end
  return cells
end

--- Returns each line of a table as 'rule' or a list of trimmed cells.
function M.parse_table(lines)
  return vim.tbl_map(function(line)
    if is_table_rule(line) then
      return 'rule'
    end
    return vim.tbl_map(vim.trim, M.table_cells(line))
  end, lines)
end

local function column_widths(rows)
  local widths = {}
  for _, row in ipairs(rows) do
    if row ~= 'rule' then
      for k, cell in ipairs(row) do
        widths[k] = math.max(widths[k] or 1, vim.api.nvim_strwidth(cell))
      end
    end
  end
  return widths
end

--- Renders rows from parse_table as an aligned grid, or nil if there are no cells.
function M.render_table(rows, indent)
  local widths = column_widths(rows)
  if #widths == 0 then
    return
  end
  return vim.tbl_map(function(row)
    local parts = {}
    for k, width in ipairs(widths) do
      if row == 'rule' then
        parts[k] = ('-'):rep(width + 2)
      else
        local cell = row[k] or ''
        parts[k] = ' ' .. cell .. (' '):rep(width - vim.api.nvim_strwidth(cell)) .. ' '
      end
    end
    local edge = row == 'rule' and '+' or '|'
    return indent .. edge .. table.concat(parts, edge) .. edge
  end, rows)
end

--- Returns the number of `key :: value` lines at the top of the file.
function M.kv_length(lines)
  local n = 0
  while lines[n + 1] and lines[n + 1]:match('^%S.-::') do
    n = n + 1
  end
  return n
end

--- Aligns the :: of key-value lines.
function M.render_kv(lines)
  local entries, width = {}, 0
  for i, line in ipairs(lines) do
    local key, value = line:match('^(.-)::(.*)$')
    entries[i] = { vim.trim(key), vim.trim(value) }
    width = math.max(width, vim.api.nvim_strwidth(entries[i][1]))
  end
  return vim.tbl_map(function(entry)
    local key, value = unpack(entry)
    local line = key .. (' '):rep(width - vim.api.nvim_strwidth(key)) .. ' :: ' .. value
    return (line:gsub('%s+$', ''))
  end, entries)
end

-- The first match of pattern that spans 1-based column col.
local function match_at(line, col, pattern)
  local init = 1
  while true do
    local s, e = line:find(pattern, init)
    if not s or s > col then
      return
    end
    if col <= e then
      return s, e
    end
    init = e + 1
  end
end

--- Returns the link at 1-based column col: { note, heading }, { ref } or { url }.
function M.link_at(line, col)
  local s, e = match_at(line, col, '%[%[.-%]%]')
  if s then
    local note, heading = line:sub(s + 2, e - 2):match('^([^|]*)|?(.*)$')
    return { note = vim.trim(note), heading = heading ~= '' and vim.trim(heading) or nil }
  end
  s, e = match_at(line, col, '%[%d+%]')
  if s then
    return { ref = tonumber(line:sub(s + 1, e - 1)) }
  end
  s, e = match_at(line, col, 'https?://%S+')
  if s then
    return { url = (line:sub(s, e):gsub('[%.,;:!%?%)%]>\'"]+$', '')) }
  end
end

local function padded(lead, text, fill, width)
  local line = lead .. ' ' .. text .. ' '
  local pad = math.max(3, width - vim.api.nvim_strwidth(line))
  return line .. fill:rep(pad)
end

--- Returns the lines for a heading; level 0 is plain text.
function M.render_heading(level, text, width)
  if level == 1 then
    local rule = ('='):rep(width)
    return { rule, text, rule }
  elseif level == 2 then
    return { padded('==', text, '=', width) }
  elseif level == 3 then
    return { padded('--', text, '-', width) }
  end
  return { text }
end

return M

local M = {}

local markers = { soft = '==', literal = '`' }

-- The non-blank run under the cursor, with surrounding punctuation left out. `other` holds
-- the characters of other markers, so ==x== stays outside a new `x` and vice versa.
local function word_at(line, c, other)
  if not line:sub(c, c):match('%S') then
    return
  end
  local s, e = c, c
  while s > 1 and line:sub(s - 1, s - 1):match('%S') do
    s = s - 1
  end
  while e < #line and line:sub(e + 1, e + 1):match('%S') do
    e = e + 1
  end
  local leading, trailing = '[%(%["\'' .. other .. ']', '[%.,;:!%?%)%]"\'' .. other .. ']'
  while s < e and line:sub(s, s):match(leading) do
    s = s + 1
  end
  while e > s and line:sub(e, e):match(trailing) do
    e = e - 1
  end
  return s, e
end

local span_patterns = { soft = '==[^%s=][^=]-==', literal = '`[^`]+`' }

-- Same rule as the syntax file: not glued to letters on the outside, no space on the inside.
local function is_soft_boundary(line, s, e)
  local text = line:sub(s + 2, e - 2)
  return not line:sub(s - 1, s - 1):match('[%w=]')
    and not line:sub(e + 1, e + 1):match('[%w=]')
    and not text:match('%s$')
end

-- A marked span like ==a b== or `x` that contains column c.
local function marked_span_at(line, c, kind)
  local init = 1
  while true do
    local s, e = line:find(span_patterns[kind], init)
    if not s or s > c then
      return
    end
    if c <= e and (kind ~= 'soft' or is_soft_boundary(line, s, e)) then
      return s, e
    end
    init = s + 1
  end
end

local function visual_span(line)
  local first, last = vim.fn.getpos("'<"), vim.fn.getpos("'>")
  if first[2] ~= last[2] then
    return
  end
  if vim.fn.visualmode() == 'V' then
    return (line:find('%S')), #line
  end
  local last_col = math.min(last[3], #line) -- v$ reports a column past the end
  return first[3], last_col + vim.str_utf_end(line, last_col)
end

-- Returns the new line and where the changed text now starts.
local function toggle_marker(line, s, e, marker)
  local n = #marker
  local text = line:sub(s, e)
  if #text >= 2 * n and text:sub(1, n) == marker and text:sub(-n) == marker then
    return line:sub(1, s - 1) .. text:sub(n + 1, -n - 1) .. line:sub(e + 1), s
  end
  if line:sub(s - n, s - 1) == marker and line:sub(e + 1, e + n) == marker then
    return line:sub(1, s - n - 1) .. text .. line:sub(e + n + 1), s - n
  end
  return line:sub(1, s - 1) .. marker .. text .. marker .. line:sub(e + 1), s
end

local function toggle_case(line, s, e)
  local text = line:sub(s, e)
  local upper = vim.fn.toupper(text)
  local toggled = text == upper and vim.fn.tolower(text) or upper
  return line:sub(1, s - 1) .. toggled .. line:sub(e + 1), s
end

--- Toggles 'strong' (UPPERCASE), 'soft' (==x==) or 'literal' (`x`) on the word under the
--- cursor, or on the visual selection. Inside an existing ==..== or `..` span, removes it.
function M.toggle(kind)
  local visual = vim.fn.mode():find('^[vV]') ~= nil
  if visual then
    vim.cmd('normal! \27')
  end

  local lnum = vim.fn.line('.')
  local line = vim.api.nvim_get_current_line()
  local c = vim.fn.col('.')
  local s, e
  if visual then
    s, e = visual_span(line)
    if not s then
      vim.notify('rowan: select text within one line', vim.log.levels.WARN)
      return
    end
  elseif markers[kind] then
    s, e = marked_span_at(line, c, kind)
  end
  if not s then
    local other = ({ soft = '`', literal = '=', strong = '`=' })[kind]
    s, e = word_at(line, c, other)
  end
  if not s then
    return
  end

  local new, start
  if kind == 'strong' then
    new, start = toggle_case(line, s, e)
  else
    new, start = toggle_marker(line, s, e, markers[kind])
  end
  if new ~= line then
    vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, false, { new })
    vim.api.nvim_win_set_cursor(0, { lnum, start - 1 })
  end
end

return M

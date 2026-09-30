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

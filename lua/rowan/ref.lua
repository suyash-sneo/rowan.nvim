local parse = require('rowan.parse')

local M = {}

local ns = vim.api.nvim_create_namespace('rowan_refs')

-- Uses of [n] and definition lines ([n] url), in order, outside ~~~ code blocks.
local function scan(lines)
  local uses, definitions, in_code = {}, {}, false
  for lnum, line in ipairs(lines) do
    if line:match('^~~~') then
      in_code = not in_code
    elseif not in_code then
      local n, url = line:match('^%[(%d+)%] (%S+)')
      if n then
        table.insert(definitions, { n = tonumber(n), lnum = lnum, url = url })
      else
        for col, m in line:gmatch('()%[(%d+)%]') do
          table.insert(uses, { n = tonumber(m), lnum = lnum, col = col })
        end
      end
    end
  end
  return uses, definitions
end

local function renumber_line(line, is_definition, number)
  local pattern = is_definition and '^%[(%d+)%]' or '%[(%d+)%]'
  return (line:gsub(pattern, function(n)
    return '[' .. number[tonumber(n)] .. ']'
  end))
end

-- Sorts each run of consecutive definition lines by number.
local function sort_definitions(lines, definitions)
  local i = 1
  while i <= #definitions do
    local j = i
    while definitions[j + 1] and definitions[j + 1].lnum == definitions[j].lnum + 1 do
      j = j + 1
    end
    local first, last = definitions[i].lnum, definitions[j].lnum
    local block = vim.list_slice(lines, first, last)
    table.sort(block, function(a, b)
      return tonumber(a:match('^%[(%d+)%]')) < tonumber(b:match('^%[(%d+)%]'))
    end)
    for offset, line in ipairs(block) do
      lines[first + offset - 1] = line
    end
    i = j + 1
  end
end

--- Returns lines with references numbered 1, 2, 3... in order of first use.
function M.renumbered(lines)
  local uses, definitions = scan(lines)
  local number, next_number = {}, 1
  for _, item in ipairs(vim.list_extend(vim.list_slice(uses), definitions)) do
    if not number[item.n] then
      number[item.n] = next_number
      next_number = next_number + 1
    end
  end

  local result = vim.list_slice(lines)
  for _, use in ipairs(uses) do
    result[use.lnum] = renumber_line(lines[use.lnum], false, number)
  end
  for _, definition in ipairs(definitions) do
    result[definition.lnum] = renumber_line(lines[definition.lnum], true, number)
  end
  sort_definitions(result, definitions)
  return result
end

-- Where a new definition goes for a use on line lnum: after the last text of its H2 section,
-- joining the definitions already there. Returns the line to insert after and the new lines.
local function definition_slot(lines, lnum, definition)
  local section_end = #lines
  for _, h in ipairs(parse.headings(lines)) do
    if h.level <= 2 and h.first > lnum then
      section_end = h.first - 1
      break
    end
  end
  local last = section_end
  while last > lnum and not lines[last]:match('%S') do
    last = last - 1
  end
  if lines[last]:match('^%[%d+%] ') then
    return last, { definition }
  end
  return last, { '', definition }
end

-- Sets only the lines that differ, so marks and folds elsewhere survive.
local function replace_changed(old, new)
  local top = 0
  while top < #old and top < #new and old[top + 1] == new[top + 1] do
    top = top + 1
  end
  local bottom = 0
  while bottom < #old - top and bottom < #new - top and old[#old - bottom] == new[#new - bottom] do
    bottom = bottom + 1
  end
  vim.api.nvim_buf_set_lines(0, top, #old - bottom, false, vim.list_slice(new, top + 1, #new - bottom))
end

local function number_for(url, uses, definitions)
  local highest = 0
  for _, item in ipairs(vim.list_extend(vim.list_slice(uses), definitions)) do
    if item.url == url then
      return item.n, true
    end
    highest = math.max(highest, item.n)
  end
  return highest + 1, false
end

--- Replaces the URL under the cursor with [n] and adds its definition to the section,
--- reusing the number of an existing definition of the same URL.
function M.from_url()
  local lnum, col = vim.fn.line('.'), vim.fn.col('.')
  local line = vim.api.nvim_get_current_line()
  local link = parse.link_at(line, col)
  if not (link and link.url) then
    vim.notify('rowan: no URL under the cursor', vim.log.levels.WARN)
    return
  end

  local old = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local lines = vim.list_slice(old)
  local n, defined = number_for(link.url, scan(lines))
  local s, e = parse.find_at(line, col, link.url, true)
  local marker = '[' .. n .. ']'
  lines[lnum] = line:sub(1, s - 1) .. marker .. line:sub(e + 1)
  if not defined then
    local after, new = definition_slot(lines, lnum, marker .. ' ' .. link.url)
    for i, text in ipairs(new) do
      table.insert(lines, after + i, text)
    end
  end

  local renumbered = M.renumbered(lines)
  replace_changed(old, renumbered)
  vim.api.nvim_win_set_cursor(0, { lnum, s - 1 })
  M.check()
end

function M.renumber()
  local old = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  replace_changed(old, M.renumbered(old))
  M.check()
end

local function warning(lnum, col, n, message)
  return {
    lnum = lnum - 1,
    col = col - 1,
    end_col = col + #tostring(n) + 1,
    severity = vim.diagnostic.severity.WARN,
    message = message:format(n),
  }
end

--- Warns about [n] with no definition, definitions never used, and duplicate definitions.
function M.check(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local uses, definitions = scan(vim.api.nvim_buf_get_lines(buf, 0, -1, false))
  local defined, used, found = {}, {}, {}
  for _, use in ipairs(uses) do
    used[use.n] = true
  end
  for _, definition in ipairs(definitions) do
    if defined[definition.n] then
      table.insert(found, warning(definition.lnum, 1, definition.n, '[%d] is defined twice'))
    elseif not used[definition.n] then
      table.insert(found, warning(definition.lnum, 1, definition.n, '[%d] is never used'))
    end
    defined[definition.n] = true
  end
  for _, use in ipairs(uses) do
    if not defined[use.n] then
      table.insert(found, warning(use.lnum, use.col, use.n, '[%d] has no definition'))
    end
  end
  vim.diagnostic.set(ns, buf, found)
end

function M.clear(buf)
  vim.diagnostic.reset(ns, buf)
end

return M

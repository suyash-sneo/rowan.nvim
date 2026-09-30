local config = require('rowan.config')
local parse = require('rowan.parse')

local M = {}

-- An H1 spans up to two lines on either side of the cursor, and telling it apart from the
-- H1 before it needs two more lines above, so parse just that window.
local function heading_at(lnum)
  local offset = math.max(0, lnum - 5)
  local lines = vim.api.nvim_buf_get_lines(0, offset, lnum + 2, false)
  local h = parse.heading(lines, lnum - offset)
  if h then
    h.first, h.last = h.first + offset, h.last + offset
  end
  return h
end

local function heading_or_line(lnum)
  local h = heading_at(lnum)
  if h then
    return h
  end
  local text = vim.trim(vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1])
  if text:match('^[=-]+$') then
    text = '' -- a lone rule or divider has no title to keep
  end
  return { level = 0, text = text, first = lnum, last = lnum }
end

local function replace(h, level)
  local old = vim.api.nvim_buf_get_lines(0, h.first - 1, h.last, false)
  local new = parse.render_heading(level, h.text, config.options.width)
  if not vim.deep_equal(old, new) then
    vim.api.nvim_buf_set_lines(0, h.first - 1, h.last, false, new)
  end

  if level == 0 then
    vim.api.nvim_win_set_cursor(0, { h.first, 0 })
  else
    vim.api.nvim_win_set_cursor(0, { parse.title_pos({ level = level, first = h.first }) })
  end
end

--- Makes the line or heading under the cursor the given level; 0 turns it into plain text.
function M.set(level)
  local h = heading_or_line(vim.fn.line('.'))
  if h.text ~= '' then
    replace(h, level)
  end
end

--- Steps through plain > H1 > H2 > H3 > plain; dir is 1 or -1.
function M.cycle(dir)
  local h = heading_or_line(vim.fn.line('.'))
  if h.text ~= '' then
    replace(h, (h.level + dir) % 4)
  end
end

--- >> and << demote and promote headings, and shift any other line as usual.
function M.shift(dir)
  local h = heading_at(vim.fn.line('.'))
  if not h then
    vim.cmd('normal! ' .. vim.v.count1 .. (dir > 0 and '>>' or '<<'))
    return
  end
  replace(h, math.min(3, math.max(1, h.level + dir)))
end

return M

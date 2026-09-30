local parse = require('rowan.parse')

local M = {}

--- Puts the cursor on a heading's title, leaving a jumplist entry for Ctrl-o.
function M.goto_heading(h)
  vim.cmd("normal! m'")
  vim.api.nvim_win_set_cursor(0, { parse.title_pos(h) })
end

local function candidates(dir, level)
  local cur = vim.fn.line('.')
  local result = {}
  for _, h in ipairs(parse.headings(vim.api.nvim_buf_get_lines(0, 0, -1, false))) do
    if not level or h.level == level then
      if dir > 0 and h.first > cur then
        table.insert(result, h)
      elseif dir < 0 and h.last < cur then
        table.insert(result, 1, h) -- nearest first
      end
    end
  end
  return result
end

-- Operators act on whole lines up to the heading, so d]] or y[[ never split one.
local function select_lines(dir, h)
  local cur = vim.fn.line('.')
  local from, to = cur, h.first - 1
  if dir < 0 then
    from, to = cur - 1, h.first
  end
  vim.api.nvim_win_set_cursor(0, { from, 0 })
  vim.cmd('normal! V')
  vim.api.nvim_win_set_cursor(0, { to, 0 })
end

--- Moves count headings forward (dir 1) or back (dir -1); level limits it to H1, H2 or H3.
function M.jump(dir, level)
  local found = candidates(dir, level)
  if #found == 0 then
    return
  end
  local h = found[math.min(vim.v.count1, #found)]
  if vim.api.nvim_get_mode().mode:find('^no') then
    select_lines(dir, h)
  else
    M.goto_heading(h)
  end
end

return M

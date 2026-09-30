local parse = require('rowan.parse')

local M = {}

-- foldexpr runs once per line, so parse the buffer once per change.
local cache = {}

local function fold_starts(buf)
  local tick = vim.b[buf].changedtick
  if cache.buf ~= buf or cache.tick ~= tick then
    local starts = {}
    for _, h in ipairs(parse.headings(vim.api.nvim_buf_get_lines(buf, 0, -1, false))) do
      starts[h.first] = '>' .. h.level
    end
    cache = { buf = buf, tick = tick, starts = starts }
  end
  return cache.starts
end

function M.expr(lnum)
  return fold_starts(vim.api.nvim_get_current_buf())[lnum] or '='
end

local markers = { '===', '==', '--' }

--- Shows a closed fold as its heading title instead of the H1 rule line.
function M.text()
  local first = vim.v.foldstart
  local lines = vim.api.nvim_buf_get_lines(0, first - 1, first + 2, false)
  local h = parse.heading(lines, 1)
  local title = h and (markers[h.level] .. ' ' .. h.text) or lines[1]
  return ('%s  ... %d lines'):format(title, vim.v.foldend - first + 1)
end

return M

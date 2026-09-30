local nav = require('rowan.nav')
local parse = require('rowan.parse')

local M = {}

local function label(h)
  return ('  '):rep(h.level - 1) .. h.text
end

--- Headings of the current buffer, indented by level; fzf-lua if installed, else vim.ui.select.
function M.outline()
  local headings = parse.headings(vim.api.nvim_buf_get_lines(0, 0, -1, false))
  if #headings == 0 then
    vim.notify('rowan: no headings', vim.log.levels.INFO)
    return
  end

  local ok, fzf = pcall(require, 'fzf-lua')
  if not ok then
    vim.ui.select(headings, { prompt = 'Outline', format_item = label }, function(h)
      if h then
        nav.goto_heading(h)
      end
    end)
    return
  end

  -- fzf only hands back text, so each entry carries its index, hidden from view.
  local entries = {}
  for i, h in ipairs(headings) do
    entries[i] = i .. '\t' .. label(h)
  end
  fzf.fzf_exec(entries, {
    prompt = 'Outline> ',
    fzf_opts = { ['--delimiter'] = '\t', ['--with-nth'] = '2..', ['--no-sort'] = true },
    actions = {
      default = function(selected)
        nav.goto_heading(headings[tonumber(selected[1]:match('^%d+'))])
      end,
    },
  })
end

return M

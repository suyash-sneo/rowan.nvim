local M = {}

-- Themes often give every heading level the same color, so borrow three distinct ones.
local headings = { rowanH1 = 'Title', rowanH2 = 'Statement', rowanH3 = 'Type' }

local function fg(group)
  return vim.api.nvim_get_hl(0, { name = group, link = false }).fg
end

function M.apply()
  for group, source in pairs(headings) do
    vim.api.nvim_set_hl(0, group, { fg = fg(source), bold = true, default = true })
  end
  vim.api.nvim_set_hl(0, 'rowanTaskMoved', { fg = fg('Comment'), italic = true, default = true })
end

return M

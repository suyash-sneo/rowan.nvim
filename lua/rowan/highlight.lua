local M = {}

-- Themes often give every heading level the same color, so borrow three distinct ones.
local sources = { rowanH1 = 'Title', rowanH2 = 'Statement', rowanH3 = 'Type' }

function M.apply()
  for group, source in pairs(sources) do
    local fg = vim.api.nvim_get_hl(0, { name = source, link = false }).fg
    vim.api.nvim_set_hl(0, group, { fg = fg, bold = true, default = true })
  end
end

return M

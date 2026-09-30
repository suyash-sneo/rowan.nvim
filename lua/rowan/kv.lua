local parse = require('rowan.parse')

local M = {}

--- Aligns the :: of the key-value block at the top of the file.
function M.align(opts)
  local n = parse.kv_length(vim.api.nvim_buf_get_lines(0, 0, -1, false))
  if n == 0 then
    return false
  end
  local lines = vim.api.nvim_buf_get_lines(0, 0, n, false)
  local new = parse.render_kv(lines)
  if not vim.deep_equal(new, lines) then
    if opts and opts.join_undo then
      pcall(vim.cmd.undojoin)
    end
    vim.api.nvim_buf_set_lines(0, 0, n, false, new)
  end
  return true
end

return M

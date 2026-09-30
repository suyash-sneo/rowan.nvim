-- Hands a key back to whatever it did before rowan's buffer-local map (e.g. CoC's global
-- insert-mode <CR>/<Tab>), so rowan only takes over keys where it has something to do.
local M = {}

local function global_map(mode, key)
  local code = vim.keycode(key)
  for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do
    if vim.keycode(map.lhs) == code then
      return map
    end
  end
end

-- The keys that `key` would produce without rowan.
local function original(mode, key)
  local map = global_map(mode, key)
  if not map then
    return vim.keycode(key)
  end
  if map.callback then
    local result = map.callback()
    return map.expr == 1 and vim.keycode(result or '') or ''
  end
  if map.expr == 1 then
    return vim.api.nvim_eval(map.rhs)
  end
  return vim.keycode(map.rhs)
end

function M.completion_visible()
  if vim.fn.pumvisible() == 1 then
    return true
  end
  return vim.fn.exists('*coc#pum#visible') == 1 and vim.fn['coc#pum#visible']() == 1
end

--- Types `keys` next, ahead of anything already waiting, without remapping.
function M.feed(keys)
  vim.api.nvim_feedkeys(keys, 'in', false)
end

--- Does whatever `key` did before rowan mapped it.
function M.fall_back(mode, key)
  M.feed(original(mode, key))
end

return M

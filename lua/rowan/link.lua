local keys = require('rowan.keys')
local notes = require('rowan.notes')
local parse = require('rowan.parse')
local pickers = require('rowan.pickers')

local M = {}

local function goto_pos(lnum, col)
  vim.cmd("normal! m'")
  vim.api.nvim_win_set_cursor(0, { lnum, col })
end

local function open_note(link)
  local path = notes.resolve(link.note)
  vim.cmd.edit(vim.fn.fnameescape(path))
  vim.bo.filetype = 'rowan' -- a note linked from a note is one too, wherever it lives
  if not vim.uv.fs_stat(path) then
    vim.notify('rowan: new note ' .. link.note)
  end
  if not link.heading then
    return
  end
  for _, h in ipairs(parse.headings(vim.api.nvim_buf_get_lines(0, 0, -1, false))) do
    if h.text:lower() == link.heading:lower() then
      -- Opening the note already left a jumplist entry for <BS> to return to.
      vim.api.nvim_win_set_cursor(0, { parse.title_pos(h) })
      return
    end
  end
  vim.notify('rowan: no heading ' .. link.heading .. ' in ' .. link.note, vim.log.levels.WARN)
end

-- From a use of [n] to its definition line, and from the definition back to the first use.
local function follow_ref(n)
  local function is_definition(line)
    return line:match('^%[' .. n .. '%] ') ~= nil
  end
  local want_definition = not is_definition(vim.api.nvim_get_current_line())
  for lnum, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
    local col = line:find('[' .. n .. ']', 1, true)
    if is_definition(line) == want_definition and col then
      goto_pos(lnum, col - 1)
      return
    end
  end
  local missing = want_definition and 'definition' or 'use'
  vim.notify(('rowan: no %s of [%d]'):format(missing, n), vim.log.levels.WARN)
end

local function open_url(url)
  local _, err = vim.ui.open(url)
  if err then
    vim.notify('rowan: ' .. err, vim.log.levels.ERROR)
  end
end

--- Follows the [[note]], [n] reference or URL under the cursor, or does a normal Enter.
function M.follow()
  local link = parse.link_at(vim.api.nvim_get_current_line(), vim.fn.col('.'))
  if not link then
    keys.fall_back('n', '<CR>')
  elseif link.note then
    open_note(link)
  elseif link.ref then
    follow_ref(link.ref)
  else
    open_url(link.url)
  end
end

--- Picks a note (and optionally a heading) and inserts a [[link]] after the cursor.
function M.insert()
  pickers.link_target(function(text)
    vim.api.nvim_put({ text }, 'c', true, true)
  end)
end

return M

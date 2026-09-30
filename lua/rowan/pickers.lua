local nav = require('rowan.nav')
local notes = require('rowan.notes')
local parse = require('rowan.parse')

local M = {}

local function has_fzf()
  return (pcall(require, 'fzf-lua'))
end

--- Lets the user pick one of items, shown with label(item); fzf-lua if installed, else
--- vim.ui.select.
function M.pick(items, prompt, label, on_choice)
  if not has_fzf() then
    vim.ui.select(items, { prompt = prompt, format_item = label }, function(item)
      if item then
        on_choice(item)
      end
    end)
    return
  end
  -- fzf only hands back text, so each entry carries its index, hidden from view.
  local entries = {}
  for i, item in ipairs(items) do
    entries[i] = i .. '\t' .. label(item)
  end
  require('fzf-lua').fzf_exec(entries, {
    prompt = prompt .. '> ',
    fzf_opts = { ['--delimiter'] = '\t', ['--with-nth'] = '2..', ['--no-sort'] = true },
    actions = {
      default = function(selected)
        on_choice(items[tonumber(selected[1]:match('^%d+'))])
      end,
    },
  })
end

local function indented(h)
  return ('  '):rep(h.level - 1) .. h.text
end

--- Headings of the current buffer, indented by level.
function M.outline()
  local headings = parse.headings(vim.api.nvim_buf_get_lines(0, 0, -1, false))
  if #headings == 0 then
    vim.notify('rowan: no headings', vim.log.levels.INFO)
    return
  end
  M.pick(headings, 'Outline', indented, nav.goto_heading)
end

local function note_headings()
  local found = {}
  for _, path in ipairs(notes.list()) do
    for _, h in ipairs(parse.headings(vim.fn.readfile(path))) do
      table.insert(found, { path = path, heading = h })
    end
  end
  return found
end

--- Headings of every note.
function M.all_headings()
  M.pick(note_headings(), 'Headings', function(item)
    return notes.name(item.path) .. ': ' .. indented(item.heading)
  end, function(item)
    vim.cmd.edit(vim.fn.fnameescape(item.path))
    nav.goto_heading(item.heading)
  end)
end

--- Opens a note, picked by file name.
function M.find()
  if has_fzf() then
    -- With one root, list paths relative to it so note names stay short and match cleanly.
    local roots = notes.roots()
    local cmd = { 'rg', '--files', '--glob', '*.txt' }
    if #roots > 1 then
      vim.list_extend(cmd, roots)
    end
    require('fzf-lua').files({
      cmd = table.concat(vim.tbl_map(vim.fn.shellescape, cmd), ' '),
      cwd = #roots == 1 and roots[1] or nil,
    })
    return
  end
  M.pick(notes.list(), 'Notes', notes.name, function(path)
    vim.cmd.edit(vim.fn.fnameescape(path))
  end)
end

--- Searches the text of every note.
function M.grep()
  if has_fzf() then
    require('fzf-lua').live_grep({ search_paths = notes.roots() })
    return
  end
  vim.ui.input({ prompt = 'Search notes: ' }, function(pattern)
    if pattern and pattern ~= '' then
      local files = vim.tbl_map(vim.fn.fnameescape, notes.list())
      vim.cmd('silent! vimgrep /' .. vim.fn.escape(pattern, '/') .. '/j ' .. table.concat(files, ' '))
      vim.cmd.copen()
    end
  end)
end

--- Picks a note, then optionally one of its headings, and returns [[Note]] or [[Note|Heading]].
function M.link_target(on_choice)
  M.pick(notes.list(), 'Link to', notes.name, function(path)
    local name = notes.name(path)
    local choices = { { text = name } }
    for _, h in ipairs(parse.headings(vim.fn.readfile(path))) do
      table.insert(choices, { text = name .. '|' .. h.text, heading = h })
    end
    -- Open the second picker once the first one has closed.
    vim.schedule(function()
      M.pick(choices, 'Heading', function(choice)
        return choice.heading and indented(choice.heading) or '(whole note)'
      end, function(choice)
        on_choice('[[' .. choice.text .. ']]')
      end)
    end)
  end)
end

return M

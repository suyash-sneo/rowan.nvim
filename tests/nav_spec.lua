local fold = require('rowan.fold')
local nav = require('rowan.nav')

local H1 = ('='):rep(10)

local lines = {
  'intro', -- 1
  H1, -- 2
  'One', -- 3
  H1, -- 4
  '== Two ===', -- 5
  'text', -- 6
  '-- Three ---', -- 7
  'text', -- 8
  H1, -- 9
  'Four', -- 10
  H1, -- 11
  'end', -- 12
}

local function buffer(cursor_lnum)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_win_set_cursor(0, { cursor_lnum, 0 })
  vim.cmd('clearjumps')
  require('rowan.keymaps').apply(buf)
end

local function cursor()
  return vim.api.nvim_win_get_cursor(0)
end

describe('nav.jump', function()
  it('moves to the next and previous heading titles', function()
    buffer(1)
    nav.jump(1)
    assert.same({ 3, 0 }, cursor())
    nav.jump(1)
    assert.same({ 5, 3 }, cursor())
    nav.jump(-1)
    assert.same({ 3, 0 }, cursor())
  end)

  it('skips the H1 the cursor is on, from any of its lines', function()
    buffer(2)
    nav.jump(1)
    assert.same({ 5, 3 }, cursor())
    buffer(4)
    nav.jump(-1)
    assert.same({ 4, 0 }, cursor())
  end)

  it('filters by level', function()
    buffer(1)
    nav.jump(1, 1)
    nav.jump(1, 1)
    assert.same({ 10, 0 }, cursor())
    nav.jump(-1, 3)
    assert.same({ 7, 3 }, cursor())
  end)

  it('stays put when there is nothing to jump to', function()
    buffer(12)
    nav.jump(1)
    assert.same({ 12, 0 }, cursor())
  end)

  it('honours a count and stops at the last heading', function()
    buffer(1)
    vim.cmd('normal 3]]')
    assert.same({ 7, 3 }, cursor())
    vim.cmd('normal 9]]')
    assert.same({ 10, 0 }, cursor())
  end)

  it('leaves a jumplist entry', function()
    buffer(1)
    nav.jump(1, 1)
    nav.jump(1, 1)
    vim.cmd('execute "normal! \\<C-o>"')
    assert.same(3, cursor()[1])
  end)
end)

describe('operators with heading motions', function()
  it('d]] deletes whole lines up to the next heading', function()
    buffer(6)
    vim.cmd('normal d]]')
    assert.same({ 'intro', H1, 'One', H1, '== Two ===', '-- Three ---' }, vim.list_slice(vim.api.nvim_buf_get_lines(0, 0, -1, false), 1, 6))
  end)

  it('d]] keeps the top rule of the H1 it stops at', function()
    buffer(8)
    vim.cmd('normal d]]')
    assert.same({ '-- Three ---', H1, 'Four' }, vim.api.nvim_buf_get_lines(0, 6, 9, false))
  end)

  it('d[[ deletes back to and including the previous heading', function()
    buffer(8)
    vim.cmd('normal d[[')
    assert.same({ '== Two ===', 'text', 'text', H1 }, vim.api.nvim_buf_get_lines(0, 4, 8, false))
  end)
end)

describe('fold', function()
  it('starts a fold at each heading, at its level', function()
    buffer(1)
    local levels = {}
    for lnum = 1, #lines do
      levels[lnum] = fold.expr(lnum)
    end
    assert.same({ '=', '>1', '=', '=', '>2', '=', '>3', '=', '>1', '=', '=', '=' }, levels)
  end)

  it('shows the heading title as fold text', function()
    buffer(1)
    vim.opt_local.foldmethod = 'expr'
    vim.opt_local.foldexpr = "v:lua.require'rowan.fold'.expr(v:lnum)"
    vim.opt_local.foldtext = "v:lua.require'rowan.fold'.text()"
    vim.cmd('normal! zM')
    assert.same('=== One  ... 7 lines', vim.fn.foldtextresult(2))
    assert.same('=== Four  ... 4 lines', vim.fn.foldtextresult(9))
  end)
end)

describe(':Rowan off', function()
  it('restores the buffer without touching its text', function()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buf)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'Title line' })
    vim.bo.filetype = 'rowan'
    assert.is_not.same('', vim.fn.maparg('<space>1', 'n'))
    vim.bo.filetype = 'text'
    assert.same({ 'Title line' }, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
    assert.same('', vim.fn.maparg('<space>1', 'n'))
  end)
end)

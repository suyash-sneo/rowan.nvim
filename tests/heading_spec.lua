local config = require('rowan.config')
local heading = require('rowan.heading')

local H1 = ('='):rep(20)
local H2 = '== Title ' .. ('='):rep(11)
local H3 = '-- Title ' .. ('-'):rep(11)

local function buffer(lines, cursor_lnum)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_win_set_cursor(0, { cursor_lnum, 0 })
end

local function lines()
  return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end

local function cursor()
  return vim.api.nvim_win_get_cursor(0)
end

describe('heading', function()
  before_each(function()
    config.setup({ width = 20 })
  end)

  it('turns a plain line into each level', function()
    buffer({ 'a', 'Title', 'b' }, 2)
    heading.set(1)
    assert.same({ 'a', H1, 'Title', H1, 'b' }, lines())
    assert.same({ 3, 0 }, cursor())

    heading.set(2)
    assert.same({ 'a', H2, 'b' }, lines())
    assert.same({ 2, 3 }, cursor())

    heading.set(3)
    assert.same({ 'a', H3, 'b' }, lines())

    heading.set(0)
    assert.same({ 'a', 'Title', 'b' }, lines())
  end)

  it('works from either H1 rule', function()
    buffer({ H1, 'Title', H1 }, 3)
    heading.set(2)
    assert.same({ H2 }, lines())
  end)

  it('re-renders a heading to the configured width', function()
    buffer({ '== Short ===' }, 1)
    heading.set(2)
    assert.same({ '== Short ' .. ('='):rep(11) }, lines())
  end)

  it('trims whitespace and ignores blank lines', function()
    buffer({ '   Title  ' }, 1)
    heading.set(3)
    assert.same({ H3 }, lines())

    buffer({ '' }, 1)
    heading.set(1)
    assert.same({ '' }, lines())
  end)

  it('cycles in both directions and wraps around', function()
    buffer({ 'Title' }, 1)
    heading.cycle(1)
    assert.same({ H1, 'Title', H1 }, lines())
    heading.cycle(-1)
    assert.same({ 'Title' }, lines())
    heading.cycle(-1)
    assert.same({ H3 }, lines())
  end)

  it('shift demotes and promotes, clamped to H1..H3', function()
    buffer({ H1, 'Title', H1 }, 2)
    heading.shift(-1)
    assert.same({ H1, 'Title', H1 }, lines())
    heading.shift(1)
    assert.same({ H2 }, lines())
    heading.shift(1)
    heading.shift(1)
    assert.same({ H3 }, lines())
  end)

  it('shift indents plain lines like >> does', function()
    buffer({ 'text' }, 1)
    vim.bo.shiftwidth = 2
    vim.bo.expandtab = true
    heading.shift(1)
    assert.same({ '  text' }, lines())
    heading.shift(-1)
    assert.same({ 'text' }, lines())
  end)

  it('leaves neighbouring H1s alone', function()
    buffer({ H1, 'Alpha', H1, 'loose', H1, 'Beta', H1 }, 4)
    heading.set(2)
    assert.same({ H1, 'Alpha', H1, '== loose ' .. ('='):rep(11), H1, 'Beta', H1 }, lines())
  end)

  it('ignores lone rules and dividers', function()
    buffer({ ('-'):rep(20) }, 1)
    heading.set(2)
    assert.same({ ('-'):rep(20) }, lines())
  end)

  it('does not touch the buffer when nothing changes', function()
    buffer({ H2 }, 1)
    vim.bo.modified = false
    heading.set(2)
    heading.shift(1)
    heading.shift(-1)
    assert.is_false(vim.bo.modified)
  end)

  it('changes a heading in one undo step', function()
    buffer({ 'Title' }, 1)
    vim.bo.undolevels = 100
    heading.set(1)
    vim.cmd('undo')
    assert.same({ 'Title' }, lines())
  end)
end)

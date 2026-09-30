local config = require('rowan.config')
local link = require('rowan.link')
local notes = require('rowan.notes')
local parse = require('rowan.parse')

local function write(path, lines)
  vim.fn.mkdir(vim.fs.dirname(path), 'p')
  vim.fn.writefile(lines, path)
end

local function cursor()
  return vim.api.nvim_win_get_cursor(0)
end

describe('parse.link_at', function()
  local line = 'see [[Auth|Rollout plan]] and [2] or https://go/auth. [[Log]]'

  it('finds the link under a column', function()
    assert.same({ note = 'Auth', heading = 'Rollout plan' }, parse.link_at(line, 7))
    assert.same({ ref = 2 }, parse.link_at(line, 32))
    assert.same({ url = 'https://go/auth' }, parse.link_at(line, 40))
    assert.same({ note = 'Log' }, parse.link_at(line, #line))
  end)

  it('returns nil between links', function()
    assert.is_nil(parse.link_at(line, 1))
    assert.is_nil(parse.link_at(line, 28))
  end)
end)

describe('links', function()
  local root

  before_each(function()
    root = vim.fn.tempname()
    write(root .. '/today.txt', { 'see [[Auth|Rollout]] and [[missing]]', 'uses [1]', '', '[1] https://x' })
    write(root .. '/projects/auth.txt', { 'intro', '== Rollout =====', 'text' })
    config.setup({})
    vim.cmd.edit(root .. '/today.txt')
  end)

  after_each(function()
    vim.cmd('silent! %bwipeout!')
    vim.fn.delete(root, 'rf')
  end)

  it('resolves notes by name anywhere under the roots, ignoring case', function()
    assert.same(vim.fn.resolve(root .. '/projects/auth.txt'), vim.fn.resolve(notes.resolve('AUTH')))
    assert.same(root .. '/nope.txt', notes.resolve('nope'))
  end)

  it('opens a linked note at its heading', function()
    vim.api.nvim_win_set_cursor(0, { 1, 7 })
    link.follow()
    assert.same('auth.txt', vim.fn.expand('%:t'))
    assert.same({ 2, 3 }, cursor())
  end)

  it('opens a new buffer for a missing note', function()
    vim.api.nvim_win_set_cursor(0, { 1, 28 })
    link.follow()
    assert.same('missing.txt', vim.fn.expand('%:t'))
  end)

  it('jumps from a reference to its definition and back', function()
    vim.api.nvim_win_set_cursor(0, { 2, 6 })
    link.follow()
    assert.same({ 4, 0 }, cursor())
    link.follow()
    assert.same({ 2, 0 }, cursor())
  end)

  it('does a normal Enter anywhere else', function()
    vim.api.nvim_win_set_cursor(0, { 2, 0 })
    link.follow()
    vim.api.nvim_feedkeys('', 'x', false)
    assert.same(3, cursor()[1])
  end)
end)

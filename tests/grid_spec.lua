local grid = require('rowan.grid')
local grid_edit = require('rowan.grid_edit')
local keymaps = require('rowan.keymaps')
local kv = require('rowan.kv')
local parse = require('rowan.parse')

local function buffer(lines, lnum, col)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_win_set_cursor(0, { lnum or 1, col or 0 })
  vim.b.rowan_live_align = true
end

local function lines()
  return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end

local function cursor()
  return vim.api.nvim_win_get_cursor(0)
end

local aligned = {
  '+----------+-------+',
  '| Ticket   | Owner |',
  '+----------+-------+',
  '| AUTH-112 | sneo  |',
  '+----------+-------+',
}

describe('parse tables', function()
  it('finds the range around a line', function()
    local text = { 'intro', '+--+', '| a |', '+--+', 'after' }
    assert.same({ 2, 4 }, { parse.table_range(text, 3) })
    assert.is_nil(parse.table_range(text, 1))
  end)

  it('reads cells with or without a closing pipe', function()
    assert.same({ ' a ', ' b ' }, parse.table_cells('| a | b |'))
    assert.same({ ' a ', ' b' }, parse.table_cells('| a | b'))
    assert.same({ ' a ', ' ' }, parse.table_cells('| a | |'))
  end)

  it('renders rows padded to the widest cell', function()
    local rows = parse.parse_table({ '+-+', '|Ticket|Owner', '+', '| AUTH-112 |sneo|', '+-' })
    assert.same(aligned, parse.render_table(rows, ''))
  end)

  it('adds cells missing from short rows', function()
    assert.same({ '| a |   |', '| b | c |' }, parse.render_table(parse.parse_table({ '|a|', '|b|c|' }), ''))
  end)

  it('treats + bullets as text, not table rules', function()
    assert.is_false(parse.is_table_line('+ item'))
  end)
end)

describe('grid.align', function()
  it('aligns the table under the cursor and keeps the cursor in its cell', function()
    buffer({ 'intro', '+-+', '|Ticket|Owner', '+', '| AUTH-112 |sneo|', '+-', 'end' }, 5, 13)
    assert.is_true(grid.align())
    assert.same(vim.list_extend(vim.list_extend({ 'intro' }, aligned), { 'end' }), lines())
    assert.same({ 5, 14 }, cursor())
  end)

  it('does nothing outside tables or inside code blocks', function()
    buffer({ '~~~', '|a|', '~~~', 'text' }, 2)
    assert.is_false(grid.align())
    assert.same({ '~~~', '|a|', '~~~', 'text' }, lines())
  end)

  it('keeps an indented table indented', function()
    buffer({ '  |a|bb|', '  |ccc|d|' })
    grid.align()
    assert.same({ '  | a   | bb |', '  | ccc | d  |' }, lines())
  end)

  it('keeps a space just typed when aligning live', function()
    buffer({ '| foo  |', '| x |' }, 1, 6)
    grid.on_text_changed()
    assert.same({ '| foo  |', '| x    |' }, lines())
    assert.same({ 1, 6 }, cursor())
    grid.on_insert_leave()
    assert.same({ '| foo |', '| x   |' }, lines())
  end)

  it('shows only the typed cells of a row being typed, so | starts the next cell', function()
    buffer({ '| Ticket | Owner |', '| AUTH-9 |' }, 2, 8)
    grid.on_text_changed()
    assert.same({ '| Ticket | Owner |', '| AUTH-9 |' }, lines())
    grid.on_insert_leave()
    assert.same({ '| Ticket | Owner |', '| AUTH-9 |       |' }, lines())
  end)

  it('only aligns live when enabled', function()
    buffer({ '|a|bb|' }, 1, 1)
    vim.b.rowan_live_align = false
    grid.on_text_changed()
    assert.same({ '|a|bb|' }, lines())
  end)
end)

local abc = {
  '+---+---+',
  '| a | b |',
  '+---+---+',
  '| c | d |',
  '| e | f |',
  '+---+---+',
}

describe('grid.move', function()
  it('moves between cells, skipping rules, and stops at the edges', function()
    buffer(abc, 2, 2)
    grid.move('right')
    assert.same({ 2, 7 }, cursor())
    grid.move('right')
    assert.same({ 2, 7 }, cursor())
    grid.move('down')
    assert.same({ 4, 7 }, cursor())
    grid.move('left')
    assert.same({ 4, 3 }, cursor())
    grid.move('up')
    assert.same({ 2, 3 }, cursor())
    grid.move('up')
    assert.same({ 2, 3 }, cursor())
  end)

  it('opens the next cell of a row still being typed', function()
    buffer({ '| a | b |', '| x |' }, 2, 2)
    grid.move('right')
    assert.same({ '| a | b |', '| x | ' }, lines())
  end)

  it('lands at the start of an empty cell', function()
    buffer({ '| abc |     |' }, 1, 3)
    grid.move('right')
    assert.same({ 1, 8 }, cursor())
  end)

  it('backs the insert-mode keys, which work as usual outside tables', function()
    buffer({ '| a | b |', 'text' }, 1, 2)
    keymaps.apply(0)
    vim.api.nvim_feedkeys(vim.keycode('i<C-l>!<Esc>jA<C-j>x<Esc>'), 'xt', false)
    assert.same({ '| a | b! |', 'text', 'x' }, lines())
  end)

  it('returns false outside a table', function()
    buffer({ 'text' })
    assert.is_false(grid.move('down'))
  end)
end)

describe('grid_edit', function()
  it('inserts, moves and deletes columns', function()
    buffer(abc, 4, 2)
    grid_edit.insert_column()
    assert.same('| c |   | d |', lines()[4])
    assert.same({ 4, 6 }, cursor())
    grid_edit.move_column(-1)
    assert.same('|   | a | b |', lines()[2])
    assert.same('|   | c | d |', lines()[4])
    grid_edit.delete_column()
    assert.same(abc, lines())
  end)

  it('adds rows after the header rule and before the bottom rule', function()
    buffer(abc, 2, 2)
    grid_edit.add_row()
    assert.same('|   |   |', lines()[4])
    assert.same({ 4, 2 }, cursor())
    vim.api.nvim_win_set_cursor(0, { 6, 2 })
    grid_edit.add_row()
    assert.same({ '|   |   |', '+---+---+' }, { lines()[7], lines()[8] })
  end)

  it('deletes rows without leaving two rules in a row', function()
    buffer({ '+---+', '| a |', '+---+', '| b |', '+---+' }, 4, 2)
    grid_edit.delete_row()
    assert.same({ '+---+', '| a |', '+---+' }, lines())
    grid_edit.delete_row()
    assert.same({ '+---+', '| a |', '+---+' }, lines())
  end)
end)

describe('kv.align', function()
  it('aligns the :: of the block at the top only', function()
    buffer({ 'ticket :: AUTH-112', 'status::open', 'x :: ', '', 'later :: not kv' })
    kv.align()
    assert.same({ 'ticket :: AUTH-112', 'status :: open', 'x      ::', '', 'later :: not kv' }, lines())
  end)

  it('does nothing without a block', function()
    buffer({ 'text', 'a :: b' })
    assert.is_false(kv.align())
    assert.same({ 'text', 'a :: b' }, lines())
  end)
end)

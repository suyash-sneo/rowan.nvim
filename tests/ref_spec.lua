local ref = require('rowan.ref')

local function buffer(lines, lnum, col)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_win_set_cursor(0, { lnum or 1, col or 0 })
end

local function lines()
  return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end

local function messages()
  return vim.tbl_map(function(d)
    return d.lnum + 1 .. ': ' .. d.message
  end, vim.diagnostic.get(0))
end

describe('ref.renumbered', function()
  it('numbers by first use and sorts definition blocks', function()
    local text = { 'b [7] a [3] b [7]', '', '[3] https://a', '[7] https://b', '[9] https://unused' }
    assert.same(
      { 'b [1] a [2] b [1]', '', '[1] https://b', '[2] https://a', '[3] https://unused' },
      ref.renumbered(text)
    )
  end)

  it('refuses while a reference has no definition', function()
    assert.same({ nil, 9 }, { ref.renumbered({ 'a [4] b [9]', '[4] https://a' }) })
  end)

  it('leaves code blocks alone', function()
    local text = { '~~~', 'x[5]', '~~~', 'see [4]', '[4] https://a' }
    assert.same({ '~~~', 'x[5]', '~~~', 'see [1]', '[1] https://a' }, ref.renumbered(text))
  end)
end)

describe('ref.from_url', function()
  it('adds the definition at the end of the H2 section', function()
    buffer({
      '== One =====',
      'timeline https://example.com/very/long here',
      '',
      '== Two =====',
    }, 2, 12)
    ref.from_url()
    assert.same({
      '== One =====',
      'timeline [1] here',
      '',
      '[1] https://example.com/very/long',
      '',
      '== Two =====',
    }, lines())
    assert.same({ 2, 9 }, vim.api.nvim_win_get_cursor(0))
  end)

  it('joins existing definitions and renumbers by first use', function()
    buffer({ 'new https://b.io first, then [1]', '', '[1] https://a.io' }, 1, 6)
    ref.from_url()
    assert.same({ 'new [1] first, then [2]', '', '[1] https://b.io', '[2] https://a.io' }, lines())
  end)

  it('reuses the number of a URL already defined', function()
    buffer({ 'a [1] b https://a.io', '', '[1] https://a.io' }, 1, 10)
    ref.from_url()
    assert.same({ 'a [1] b [1]', '', '[1] https://a.io' }, lines())
  end)
end)

describe('ref.check', function()
  it('warns about missing, unused and duplicate definitions', function()
    buffer({ 'see [1] and [2]', '[1] https://a', '[1] https://b', '[3] https://c' })
    ref.check()
    local found = messages()
    table.sort(found)
    assert.same({
      '1: [2] has no definition',
      '3: [1] is defined twice',
      '4: [3] is never used',
    }, found)
  end)
end)

local parse = require('rowan.parse')

local H1 = ('='):rep(10)

describe('parse.heading', function()
  it('finds an H1 from its title and from either rule', function()
    local lines = { 'intro', H1, 'Title', H1, 'body' }
    local want = { level = 1, text = 'Title', first = 2, last = 4 }
    assert.same(want, parse.heading(lines, 2))
    assert.same(want, parse.heading(lines, 3))
    assert.same(want, parse.heading(lines, 4))
  end)

  it('accepts rules of any length of three or more', function()
    assert.same(1, parse.heading({ '===', 'T', '=====' }, 2).level)
    assert.is_nil(parse.heading({ '==', 'T', '==' }, 2))
  end)

  it('does not treat a lone rule or a blank title as an H1', function()
    assert.is_nil(parse.heading({ H1, 'text' }, 1))
    assert.is_nil(parse.heading({ H1, '', H1 }, 2))
  end)

  it('does not treat text between two H1s as a title', function()
    local lines = { H1, 'Alpha', H1, 'loose', H1, 'Beta', H1 }
    assert.is_nil(parse.heading(lines, 4))
    assert.same({ level = 1, text = 'Beta', first = 5, last = 7 }, parse.heading(lines, 5))
    assert.same({ level = 1, text = 'Alpha', first = 1, last = 3 }, parse.heading(lines, 3))
  end)

  it('finds stacked H1s with no gap', function()
    local lines = { H1, 'A', H1, H1, 'B', H1 }
    assert.same('A', parse.heading(lines, 3).text)
    assert.same('B', parse.heading(lines, 4).text)
  end)

  it('parses H2 and H3', function()
    assert.same({ level = 2, text = 'Backlog review', first = 1, last = 1 },
      parse.heading({ '== Backlog review ====' }, 1))
    assert.same({ level = 3, text = 'Auth tickets', first = 1, last = 1 },
      parse.heading({ '-- Auth tickets ----' }, 1))
  end)

  it('keeps = and - inside titles', function()
    assert.same('a = b', parse.heading({ '== a = b =====' }, 1).text)
    assert.same('x - y', parse.heading({ '-- x - y -----' }, 1).text)
  end)

  it('ignores look-alikes', function()
    assert.is_nil(parse.heading({ '==soft== text' }, 1))
    assert.is_nil(parse.heading({ '- bullet' }, 1))
    assert.is_nil(parse.heading({ ('-'):rep(20) }, 1))
    assert.is_nil(parse.heading({ '== short ==' }, 1))
  end)
end)

describe('parse.headings', function()
  it('lists every heading in order', function()
    local lines = { 'intro', H1, 'One', H1, '== Two ===', 'text', '-- Three ---', H1, 'Four', H1 }
    local found = vim.tbl_map(function(h)
      return { h.level, h.text, h.first }
    end, parse.headings(lines))
    assert.same({ { 1, 'One', 2 }, { 2, 'Two', 5 }, { 3, 'Three', 7 }, { 1, 'Four', 8 } }, found)
  end)

  it('skips headings inside code blocks', function()
    local lines = { '~~~ sh', '== Not a heading ===', '~~~', '== Real ===' }
    assert.same({ 'Real' }, vim.tbl_map(function(h)
      return h.text
    end, parse.headings(lines)))
  end)

  it('agrees with heading() on text between two H1s', function()
    local lines = { H1, 'Alpha', H1, 'loose', H1, 'Beta', H1 }
    assert.same({ 'Alpha', 'Beta' }, vim.tbl_map(function(h)
      return h.text
    end, parse.headings(lines)))
  end)
end)

describe('parse.title_pos', function()
  it('points at the title text', function()
    assert.same({ 5, 0 }, { parse.title_pos({ level = 1, first = 4 }) })
    assert.same({ 4, 3 }, { parse.title_pos({ level = 2, first = 4 }) })
  end)
end)

describe('parse.render_heading', function()
  it('renders each level to the given width', function()
    assert.same({ H1, 'Title', H1 }, parse.render_heading(1, 'Title', 10))
    assert.same({ '== Ab ====' }, parse.render_heading(2, 'Ab', 10))
    assert.same({ '-- Ab ----' }, parse.render_heading(3, 'Ab', 10))
    assert.same({ 'Ab' }, parse.render_heading(0, 'Ab', 10))
  end)

  it('keeps at least three fill characters for long titles', function()
    assert.same('== A long title ===', parse.render_heading(2, 'A long title', 10)[1])
  end)

  it('round-trips through heading()', function()
    for level = 1, 3 do
      local lines = parse.render_heading(level, 'Round trip', 40)
      local h = parse.heading(lines, level == 1 and 2 or 1)
      assert.same({ level, 'Round trip' }, { h.level, h.text })
    end
  end)
end)

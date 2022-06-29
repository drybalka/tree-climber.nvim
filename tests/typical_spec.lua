local tc = require('tree-climber')
local function assert_cursor_at(pos)
  assert.are.same(pos, vim.api.nvim_win_get_cursor(0))
end
local function set_cursor_to(pos)
  vim.api.nvim_win_set_cursor(0, pos)
end

vim.cmd[[edit tests/samples/typical.html]]

describe("typical-tree-climber", function()
  before_each(function()
    set_cursor_to({1, 0})
    tc._node_level = 0
  end)

  it('has loaded treesitter', function()
    local parser = vim.treesitter.get_parser()
    assert.is_not.falsy(parser)
  end)

  it('handles normal next/prev movements', function()
    tc.goto_next()
    assert_cursor_at({3, 0})
    tc.goto_prev()
    assert_cursor_at({1, 0})
  end)

  it('handles goto_child', function()
    set_cursor_to({3, 0})
    tc.goto_child()
    tc.goto_next()
    assert_cursor_at({4, 4})
  end)

  it('handles goto_parent', function()
    set_cursor_to({4, 4})
    tc.goto_parent()
    assert_cursor_at({3, 0})
  end)

  it('handles normal next/prev movements in a sub-tree', function()
    set_cursor_to({12, 12})
    tc.goto_prev()
    assert_cursor_at({11, 12})
    tc.goto_next()
    assert_cursor_at({12, 12})
  end)

  it('handles goto_child in a sub-tree', function()
    set_cursor_to({12, 12})
    tc.goto_child()
    tc.goto_next()
    assert_cursor_at({12, 17})
  end)

  it('handles goto_parent in a sub-tree', function()
    set_cursor_to({12, 20})
    tc.goto_parent()
    assert_cursor_at({12, 12})
  end)

  it('handles goto_child into a sub-tree', function()
    set_cursor_to({11, 12})
    tc.goto_child()
    tc.goto_next()
    assert_cursor_at({12, 12})
  end)

  it('handles goto_parent from a sub-tree', function()
    set_cursor_to({12, 12})
    tc.goto_parent()
    assert_cursor_at({11, 12})
    tc.goto_parent()
    assert_cursor_at({10, 8})
  end)

  it('handles comments', function()
    set_cursor_to({4, 4})
    tc.goto_next()
    assert_cursor_at({7, 4})
    tc.goto_next()
    assert_cursor_at({8, 4})
  end)


  it('takes the innermost node when inside the range', function()
    set_cursor_to({3, 2})
    tc.goto_next()
    assert_cursor_at({4, 4})
  end)

  it('jumps over nodes with no siblings', function()
    set_cursor_to({9, 8})
    tc.goto_child()
    assert_cursor_at({9, 9})
  end)

  it('chooses outmost node for small node_level', function()
    set_cursor_to({4, 4})
    tc._node_level = 0
    tc.goto_next()
    assert_cursor_at({7, 4})
  end)

  it('chooses innermost node for large node_level', function()
    set_cursor_to({4, 4})
    tc._node_level = 100
    tc.goto_next()
    assert_cursor_at({5, 8})
  end)


  it('does not throw error on first line', function()
    tc.goto_parent()
    assert_cursor_at({1, 0})
    tc.goto_prev()
    assert_cursor_at({1, 0})
  end)

  it('does not throw error when goto_next called on root', function()
    set_cursor_to({2, 0})
    tc.goto_next()
    assert_cursor_at({2, 0})
  end)

  it('does not throw error when goto_prev called on root', function()
    set_cursor_to({2, 0})
    tc.goto_prev()
    assert_cursor_at({2, 0})
  end)

  it('does not throw error when goto_parent called on root', function()
    set_cursor_to({2, 0})
    tc.goto_parent()
    assert_cursor_at({1, 0})
  end)

  it('does not throw error when goto_child called on root', function()
    set_cursor_to({2, 0})
    tc.goto_child()
    assert_cursor_at({1, 0})
  end)

  it('does not go out of bounds on last sibling on top level', function()
    set_cursor_to({3, 0})
    tc.goto_next()
    assert_cursor_at({3, 0})
  end)

  it('does not go out of bounds on last sibling on bottom level', function()
    set_cursor_to({12, 12})
    tc.goto_next()
    assert_cursor_at({12, 12})
  end)

  it('does not go out of bounds on first sibling', function()
    set_cursor_to({5, 8})
    tc._node_level = 2
    tc.goto_prev()
    assert_cursor_at({5, 8})
  end)

end)

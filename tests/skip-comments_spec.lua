local tc = require 'tree-climber'
local function assert_cursor_at(pos)
  assert.are.same(pos, vim.api.nvim_win_get_cursor(0))
end
local function set_cursor_to(pos)
  vim.api.nvim_win_set_cursor(0, pos)
end

local options = { skip_comments = true }

describe('tree-climber with enabled skip_comments', function()
  it('jumps over comments for next/prev movements', function()
    vim.cmd [[view tests/samples/typical.html]]
    set_cursor_to { 4, 4 }
    tc.goto_next(options)
    assert_cursor_at { 8, 4 }
    tc.goto_prev(options)
    assert_cursor_at { 4, 4 }
  end)

  it('jumps over comments when goto_child', function()
    vim.cmd [[view tests/samples/typical.html]]
    set_cursor_to { 11, 12 }
    tc.goto_child(options)
    assert_cursor_at { 12, 12 }
  end)

  it('ignores comments when counting children', function()
    vim.cmd [[view tests/samples/comments.java]]
    set_cursor_to { 1, 17 }
    tc.goto_child(options)
    tc.goto_next(options)
    assert_cursor_at { 5, 18 }
  end)

  it('does not enter nodes with only comments', function()
    vim.cmd [[view tests/samples/comments.java]]
    set_cursor_to { 5, 43 }
    tc.goto_child(options)
    assert_cursor_at { 5, 43 }
  end)
end)

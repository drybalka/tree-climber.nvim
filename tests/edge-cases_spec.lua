local tc = require 'tree-climber'
local function assert_cursor_at(pos)
  assert.are.same(pos, vim.api.nvim_win_get_cursor(0))
end
local function set_cursor_to(pos)
  vim.api.nvim_win_set_cursor(0, pos)
end

describe('tree-climber', function()
  it('does not count root in node_level', function()
    vim.cmd [[view tests/samples/root_node_level.html]]
    tc._node_level = 0

    set_cursor_to { 4, 0 }
    tc.goto_prev()
    assert_cursor_at { 1, 0 }
    tc.goto_next()
    assert_cursor_at { 4, 0 }
  end)
end)

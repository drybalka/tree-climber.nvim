describe('tree-climber', function()
  it('can be required', function()
    require 'tree-climber'
  end)

  it('handles empty files', function()
    vim.cmd [[view ./samples/empty]]
    require('tree-climber').goto_parent()
    require('tree-climber').goto_child()
    require('tree-climber').goto_next()
    require('tree-climber').goto_prev()
    require('tree-climber').swap_prev()
    require('tree-climber').swap_next()
  end)
end)

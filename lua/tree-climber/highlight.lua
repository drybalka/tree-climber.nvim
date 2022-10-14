-- Credit: This file has largely been adapted from `vim.highlight.on_yank`,
-- defined in neovim/runtime/lua/vim/highlight.lua.

local M = {}

local ts_utils = require 'nvim-treesitter.ts_utils'

local node_ns = vim.api.nvim_create_namespace 'tree_climber_hlnode'
local node_timer

function M.highlight_node(node, opts)
  vim.validate {
    node = { node, 'userdata', true },
    opts = { opts, 'table', true },
  }
  if node == nil then
    return
  end

  opts = opts or {}
  local on_macro = opts.on_macro or false
  local higroup = opts.higroup or 'IncSearch'
  local timeout = opts.timeout or 150

  if not on_macro and vim.fn.reg_executing() ~= '' then
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(bufnr, node_ns, 0, -1)
  if node_timer then
    node_timer:close()
  end

  ts_utils.highlight_node(node, bufnr, node_ns, higroup)
  node_timer = vim.defer_fn(function()
    node_timer = nil
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.api.nvim_buf_clear_namespace(bufnr, node_ns, 0, -1)
    end
  end, timeout)
end

return M

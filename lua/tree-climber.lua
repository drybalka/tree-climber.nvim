local M = {}

M._node_level = 0


local function same_start(node1, node2)
  local start_row1, start_col1 = node1:start()
  local start_row2, start_col2 = node2:start()

  return start_row1 == start_row2 and start_col1 == start_col2
end

local function contains(outer, inner)
  local start_row1, start_col1, end_row1, end_col1 = outer:range()
  local start_row2, start_col2, end_row2, end_col2 = inner:range()

  local start_fits = start_row1 < start_row2 or (start_row1 == start_row2 and start_col1 <= start_col2)
  local end_fits = end_row1 > end_row2 or (end_row1 == end_row2 and end_col1 >= end_col2)

  return start_fits and end_fits
end

local function is_comment(node)
  local type = node:type()
  return type == "comment" or type == "line_comment" or type == "block_comment"
end

local function set_node_level(path)
  M._node_level = 0

  local last_node = path[#path]
  for i = #path - 1, 2, -1 do
    local node = path[i]
    if same_start(node, last_node) then
      M._node_level = M._node_level + 1
    end
  end
end

local function move_cursor_to_node(node)
  local start_row, start_col = node:start()
  vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
end

local function get_cursor()
  local cursor = vim.api.nvim_win_get_cursor(0)
  cursor.start = function() return cursor[1] - 1, cursor[2] end
  cursor.range = function() return cursor[1] - 1, cursor[2], cursor[1] - 1, cursor[2] + 1 end
  return cursor
end

local function get_node_selection_range(node)
  local start_row, start_col, end_row, end_col = node:range()
  if end_col == 0 then
    -- Use the value of the last col of the previous row instead.
    end_col = #vim.api.nvim_buf_get_lines(0, end_row - 1, end_row, false)[1]
    end_row = end_row - 1
  end

  start_row = start_row + 1
  end_row = end_row + 1
  end_col = end_col - 1

  return start_row, start_col, end_row, end_col
end

local function get_root(parser, cursor)
  for _, tree in ipairs(parser:trees()) do
    local root = tree:root()
    if root and contains(root, cursor) then
      return root
    end
  end
end

local function get_connector(node, parser)
  for _, subparser in pairs(parser:children()) do
    for _, tree in ipairs(subparser:trees()) do
      local subroot = tree:root()
      if subroot and contains(node, subroot) then
        return subroot, subparser
      end
    end
  end
end

local function valid_children(node, options)
  local children = {}
  for child, _ in node:iter_children() do
    if child:named() and not (options and options.skip_comments and is_comment(child)) then
      table.insert(children, child)
    end
  end
  return children
end

local function find_next_nontrivial_parent(node, parser, options)
  local children = valid_children(node, options)

  if #children == 0 then
    local subroot, subparser = get_connector(node, parser)
    if not subroot or not subparser then
      return
    end
    return find_next_nontrivial_parent(subroot, subparser, options)
  end

  if #children == 1 then
    return find_next_nontrivial_parent(children[1], parser, options)
  end

  return node, parser
end


local function locate_node(path, parser, cursor, level, options)
  local next_parent, next_parser = find_next_nontrivial_parent(path[#path], parser, options)
  if not next_parent or not next_parser then
    return path, parser
  end

  for node, _ in next_parent:iter_children() do
    if node:named() and contains(node, cursor) and
        not (options and options.skip_comments and is_comment(node)) then
      table.insert(path, node)

      if same_start(node, cursor) then
        if level == 0 then
          return path, parser
        else
          return locate_node(path, parser, cursor, level - 1, options)
        end
      end

      return locate_node(path, parser, cursor, level, options)
    end
  end

  return path, parser
end

local function get_current_node_path(options)
  local cursor = get_cursor()
  local main_parser = require("nvim-treesitter.parsers").get_parser()
  if not main_parser then
    return
  end

  local root = get_root(main_parser, cursor)
  if not root then
    return
  end

  return locate_node({root}, main_parser, cursor, M._node_level, options)
end


local function get_next_sibling_path(path, parser, options)
  local node = path[#path]
  local next_sibling = node:next_named_sibling()

  if options and options.skip_comments then
    while next_sibling and is_comment(next_sibling) do
      next_sibling = next_sibling:next_named_sibling()
    end
  end

  if next_sibling then
      path[#path] = next_sibling
      return path
  end
end

local function get_prev_sibling_path(path, parser, options)
  local node = path[#path]
  local prev_sibling = node:prev_named_sibling()

  if options and options.skip_comments then
    while prev_sibling and is_comment(prev_sibling) do
      prev_sibling = prev_sibling:prev_named_sibling()
    end
  end

  if prev_sibling then
    path[#path] = prev_sibling
    return path
  end
end

local function get_parent_path(path, parser, options)
  if (#path > 1) then
    path[#path] = nil
  end
  return path
end

local function get_child_path(path, parser, options)
  local next_parent, next_parser = find_next_nontrivial_parent(path[#path], parser, options)
  if not next_parent or not next_parser then
    return
  end

  path[#path + 1] = valid_children(next_parent, options)[1]
  return path
end

local function goto_with(new_path_getter, options)
  local path, parser = get_current_node_path(options)
  if not path or not parser then
    return
  end

  local new_path = new_path_getter(path, parser, options)
  if not new_path then
    return
  end

  set_node_level(new_path)
  move_cursor_to_node(new_path[#new_path])
end

local function swap_with(new_path_getter, options)
  local path, parser = get_current_node_path(options)
  if not path or not parser then
    return
  end
  local node = path[#path]

  local new_path = new_path_getter(path, parser, options)
  if not new_path then
    return
  end
  local new_node = new_path[#new_path]

  set_node_level(new_path)
  require('nvim-treesitter.ts_utils').swap_nodes(node, new_node, 0, true)
end


M.goto_next = function(options)
  goto_with(get_next_sibling_path, options)
end

M.goto_prev = function(options)
  goto_with(get_prev_sibling_path, options)
end

M.goto_parent = function(options)
  goto_with(get_parent_path, options)
end

M.goto_child = function(options)
  goto_with(get_child_path, options)
end

M.swap_next = function(options)
  swap_with(get_next_sibling_path, options)
end

M.swap_prev = function(options)
  swap_with(get_prev_sibling_path, options)
end

M.select_node = function(options)
  local path, parser = get_current_node_path(options)
  if not path or not parser then
    return
  end
  local node = path[#path]

  local start_row, start_col, end_row, end_col = get_node_selection_range(node)
  vim.api.nvim_win_set_cursor(0, { start_row, start_col })

  local mode = vim.api.nvim_get_mode().mode
  if (mode == 'v' or mode == 'V' or mode == '') then
    vim.cmd("normal! o")
  else
    vim.cmd("normal! v")
  end

  vim.api.nvim_win_set_cursor(0, { end_row, end_col })
end

return M

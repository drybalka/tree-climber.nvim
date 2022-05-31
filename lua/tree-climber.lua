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

local function set_node_level(path)
  M._node_level = 0

  local last_node = path[#path]
  for i = #path - 1, 1, -1 do
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
  cursor.start = function(cursor) return cursor[1] - 1, cursor[2] end
  cursor.range = function(cursor) return cursor[1] - 1, cursor[2], cursor[1] - 1, cursor[2] + 1 end
  return cursor
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

local function find_next_nontrivial_parent(node, parser)
  while node:named_child_count() <= 1 do
    if node:named_child_count() == 1 then
      node = node:named_child(0)
    else
      local subroot, subparser = get_connector(node, parser)
      if not subroot or not subparser then
        return
      end
      node = subroot
      parser = subparser
    end
  end
  return node, parser
end


local function locate_node(path, parser, cursor, level)
  local node = path[#path] or get_root(parser, cursor)
  if not node then
    return
  end
  local next_parent, next_parser = find_next_nontrivial_parent(node, parser)
  if not next_parent or not next_parser then
    return path, parser
  end

  for node, _ in next_parent:iter_children() do
    if node:named() and contains(node, cursor) then
      table.insert(path, node)

      if same_start(node, cursor) then
        if level == 0 then
          return path, parser
        else
          return locate_node(path, parser, cursor, level - 1)
        end
      end

      return locate_node(path, parser, cursor, level)
    end
  end

  return path, parser
end

function get_current_node_path()
  local cursor = get_cursor()
  local main_parser = require("nvim-treesitter.parsers").get_parser()
  if not main_parser then
    return
  end

  local root = get_root(main_parser, cursor)
  if not root then
    return
  end

  return locate_node({}, main_parser, cursor, M._node_level)
end


local function get_next_sibling_path(path)
  local node = path[#path]
  local parent = node:parent()
  if not parent then
    return
  end
  local iterator = parent:iter_children()

  for prev_sibling, _ in iterator do
    if prev_sibling == node then
      break
    end
  end

  for next_sibling, _ in iterator do
    if next_sibling:named() then
      path[#path] = next_sibling
      return path
    end
  end
end

function get_prev_sibling_path(path)
  local node = path[#path]
  local parent = node:parent()
  if not parent then
    return
  end
  local prev_sibling

  for sibling, _ in parent:iter_children() do
    if sibling == node and prev_sibling then
      path[#path] = prev_sibling
      return path
    elseif sibling:named() then
      prev_sibling = sibling
    end
  end
end

local function get_parent_path(path)
  if (#path > 1) then
    path[#path] = nil
  end
  return path
end

function get_child_path(path, parser)
  local next_parent, next_parser = find_next_nontrivial_parent(path[#path], parser)
  if not next_parent or not next_parser then
    return
  end

  path[#path + 1] = next_parent:named_child(0)
  return path
end

local function goto_with(new_path_getter)
  local path, parser = get_current_node_path()
  if not path or not parser then
    return
  end

  local new_path = new_path_getter(path, parser)
  if not new_path then
    return
  end

  set_node_level(new_path)
  move_cursor_to_node(new_path[#new_path])
end

local function swap_with(new_path_getter)
  local path, parser = get_current_node_path()
  if not path or not parser then
    return
  end
  local node = path[#path]

  local new_path = new_path_getter(path, parser)
  if not new_path then
    return
  end
  local new_node = new_path[#new_path]

  set_node_level(new_path)
  require('nvim-treesitter.ts_utils').swap_nodes(node, new_node, 0, true)
end


M.goto_next = function()
  goto_with(get_next_sibling_path)
end

M.goto_prev = function()
  goto_with(get_prev_sibling_path)
end

M.goto_parent = function()
  goto_with(get_parent_path)
end

M.goto_child = function()
  goto_with(get_child_path)
end

M.swap_next = function()
  swap_with(get_next_sibling_path)
end

M.swap_prev = function()
  swap_with(get_prev_sibling_path)
end

return M

local node_level = 0

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
  node_level = 0

  local last_node = path[#path]
  for i = #path - 1, 1, -1 do
    local node = path[i]
    if same_start(node, last_node) then
      node_level = node_level + 1
    end
  end
end

local function goto_node(node)
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
  local next_parent, next_parser = find_next_nontrivial_parent(path[#path], parser)
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

function get_node_path()
  local cursor = get_cursor()
  local main_parser = require("nvim-treesitter.parsers").get_parser()
  if not main_parser then
    return
  end

  local root = get_root(main_parser, cursor)
  if not root then
    return
  end

  return locate_node({root}, main_parser, cursor, node_level)
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
  path[#path] = nil
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


function goto_next()
  local path = get_node_path()
  if not path then
    return
  end

  local next_path = get_next_sibling_path(path)
  if not next_path then
    return
  end

  set_node_level(next_path)
  goto_node(next_path[#next_path])
end

function goto_prev()
  local path = get_node_path()
  if not path then
    return
  end

  local prev_path = get_prev_sibling_path(path)
  if not prev_path then
    return
  end

  set_node_level(prev_path)
  goto_node(prev_path[#prev_path])
end

function goto_parent()
  local path = get_node_path()
  if not path then
    return
  end

  local parent_path = get_parent_path(path)
  if not parent_path then
    return
  end

  set_node_level(parent_path)
  goto_node(parent_path[#parent_path])
end

function goto_child()
  local path, parser = get_node_path()
  if not path or not parser then
    return
  end

  local child_path = get_child_path(path, parser)
  if not child_path then
    return
  end

  set_node_level(child_path)
  goto_node(child_path[#child_path])
end

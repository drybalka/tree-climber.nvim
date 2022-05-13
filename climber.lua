local node_level = 0

local function same_start(node1, node2)
  local start_row1, start_col1 = node1:start()
  local start_row2, start_col2 = node2:start()

  return start_row1 == start_row2 and start_col1 == start_col2
end

local function contains(parent, child)
  local start_row1, start_col1, end_row1, end_col1 = parent:range()
  local start_row2, start_col2, end_row2, end_col2 = child:range()

  local start_fits = start_row1 < start_row2 or (start_row1 == start_row2 and start_col1 <= start_col2)
  local end_fits = end_row1 > end_row2 or (end_row1 == end_row2 and end_col1 >= end_col2)

  return start_fits and end_fits
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

local function locate_node(root, cursor, level)
  local nontrivial_parent = root
  while nontrivial_parent:named_child_count() == 1 do
    nontrivial_parent = nontrivial_parent:named_child(0)
  end

  for node, _ in nontrivial_parent:iter_children() do
    if node:named() and contains(node, cursor) then
      if same_start(node, cursor) then
        if level == 0 then
          return node
        else
          return locate_node(node, cursor, level - 1)
        end
      end

      return locate_node(node, cursor, level)
    end
  end

  return root
end

local function get_node()
  local parsers = require "nvim-treesitter.parsers"
  local main_parser = parsers.get_parser()
  local cursor = get_cursor()

  local root = get_root(main_parser, cursor)
  local node = locate_node(root, cursor, node_level)

  return node
end

local function is_lone_child(node)
  local parent = node:parent()
  if parent == nil then
    return true
  end
  return parent:named_child_count() == 1
end

local function set_node_level(node)
  node_level = 0

  if node == nil then
    return
  end

  local parent = node:parent()
  while parent ~= nil and same_start(node, parent) do
    node_level = node_level + 1
    parent = parent:parent()
  end
end

local function goto_node(node)
  if node == nil then
    return
  end

  local start_row, start_col = node:start()
  vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
end


local function get_next_node(node)
  local parent = node:parent()
  if parent == nil then
    return
  end
  local iterator = parent:iter_children()

  for sibling_before, _ in iterator do
    if sibling_before == node then
      break
    end
  end

  for sibling_after, _ in iterator do
    if sibling_after:named() then
      return sibling_after
    end
  end
end

local function get_prev_node(node)
  local parent = node:parent()
  if parent == nil then
    return
  end
  local prev

  for sibling, _ in parent:iter_children() do
    if sibling:named() then
      if sibling == node then
        return prev
      end
      prev = sibling
    end
  end
end

local function get_parent_node(node)
  local parent = node:parent()
  if parent == nil then
    return
  end

  while parent ~= nil do
    if parent:named() and not is_lone_child(parent) then
      return parent
    end
    parent = parent:parent()
  end
end

local function get_child_node(node)
  local child = node:named_child(0)

  while child ~= nil do
    if not is_lone_child(child) then
      return child
    end
    child = child:named_child(0)
  end
end


function goto_next()
  local node = get_node()
  local next = get_next_node(node)

  if next == nil then
    return
  end

  set_node_level(next)
  goto_node(next)
end

function goto_prev()
  local node = get_node()
  local prev = get_prev_node(node)

  if prev == nil then
    return
  end

  set_node_level(prev)
  goto_node(prev)
end

function goto_parent()
  local node = get_node()
  local parent = get_parent_node(node)

  if parent == nil then
    return
  end

  set_node_level(parent)
  goto_node(parent)
end

function goto_child()
  local node = get_node()
  local child = get_child_node(node)

  if child == nil then
    return
  end

  set_node_level(child)
  goto_node(child)
end

local ts_utils = require("nvim-treesitter.ts_utils")
local function is_root(node)
  return node:parent() == nil
end
function get_node()
  local function same_pos(pos1, pos2)
    return pos1[1] == pos2[1] and pos1[2] == pos2[2]
  end

  local node = ts_utils.get_node_at_cursor()
  if is_root(node) then
    return node
  end

  local cursor = vim.api.nvim_win_get_cursor(0)
  if same_pos({cursor[1] - 1, cursor[2]}, {node:start()}) then
    while same_pos({node:start()}, {node:parent():start()}) do
      local parent = node:parent()
      if is_root(parent) then
        return node
      end
      node = parent
    end
  end

  return node
end

function goto_parent()
  local node = get_node()
  local parent = node:parent()
  if not is_root(parent) then
    ts_utils.goto_node(parent)
  end
end
function goto_next()
  local node = get_node()
  local next = ts_utils.get_next_node(node)
  ts_utils.goto_node(next)
end
function goto_prev()
  local node = get_node()
  local prev = ts_utils.get_previous_node(node)
  ts_utils.goto_node(prev)
end

function get_root_lang_tree()
  local parsers = require "nvim-treesitter.parsers"
    if not parsers.has_parser() then
      return
    end

  return parsers.get_parser()
end
function get_root_at_cursor()
  local parsers = require "nvim-treesitter.parsers"
  if not parsers.has_parser() then
    return
  end

  local root_lang_tree = parsers.get_parser()

  local lang_tree = root_lang_tree:language_for_range { line, col, line, col }

  for _, tree in ipairs(lang_tree:trees()) do
    local root = tree:root()

    if root and ts_utils.is_in_node_range(root, line, col) then
      return root, tree, lang_tree
    end
  end

  -- This isn't a likely scenario, since the position must belong to a tree somewhere.
  return nil, nil, lang_tree
end
function goto_child()
  local cursor = vim.api.nvim_win_get_cursor(winnr or 0)
  local cursor_range = { cursor[1] - 1, cursor[2] }
  local root = get_root_for_position(unpack(cursor_range))
  -- print(root)
  -- local node = ts_utils.get_node_at_cursor()
  -- local child = ts_utils.get_named_children(node)
  -- ts_utils.goto_node(child)
end

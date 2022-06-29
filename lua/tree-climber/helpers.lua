local M = {}

function M.print_tree(root)
  local function pt(node, level)
    local tab = '|   '
    if not level then
      level = 0
    end
    local shift = string.rep(tab, level)
    local res = shift .. node:type() .. ' : ' .. vim.inspect{node:range()} .. '\n'
    local count = 0
    while node:named_child(count) do
      local next = node:named_child(count)
      res = res .. pt(next, level + 1)
      count = count + 1
    end
    return res
  end

  print(pt(root))
  return pt(root)
end

return M

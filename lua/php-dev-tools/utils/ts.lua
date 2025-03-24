local M = {}

M.get_target_node = function(node_name)
  local node = vim.treesitter.get_node()

  while node ~= nil do
    if node:type() == node_name then
      return node
    end

    node = node:parent()
  end
end

M.get_node_text = vim.treesitter.get_node_text

return M

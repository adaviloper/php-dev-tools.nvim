local M = {}

-- local p = function (message)
--   vim.notify(message, 3)
-- end

local ts = vim.treesitter
local parsers = require('nvim-treesitter.parsers')



---@return boolean, TSNode?, TSNode?
M.validate_touple = function()
  local node = ts.get_node()
  if node == nil then
    return false
  end
  local parser = parsers.get_parser()
  local tree = parser:parse()[1]
  local root = tree:root()
  local qs = [[
(array_creation_expression
  (array_element_initializer (class_constant_access_expression)) @class
  (array_element_initializer (string)) @method
  ) @array
]]
  local language = parser:lang()

  ts.query.parse(language, qs)
  if node:type() == 'string' then
    node = node:named_child()
  end
  if node:parent():parent():parent():type() == 'array_creation_expression' then
    local class_node = node:parent():parent():parent():named_children()[1]:child():child()
    local class_name = ts.get_node_text(class_node, 0)
    if string.sub(class_name, 1, 1) == '\\' then
      class_name = string.sub(class_name, 2)
    end
    if class_node ~= nil then
      local query = ts.query.parse(language, '(namespace_use_clause) @namespace_use_clause')
      for _, namespace_node, _ in query:iter_captures(root, 0) do
        if namespace_node ~= nil then
          local namespace_name = ts.get_node_text(namespace_node, 0)
          if string.find(namespace_name, class_name) then
            return true, namespace_node, node
          end
        end
      end
    end
  end
  return false
end

---@return boolean
M.go_to_definition = function()
  local isValidTouple, class_node, method_node = M.validate_touple()
  if isValidTouple and class_node ~= nil then
    local method_name = ts.get_node_text(method_node, 0)
    local class_name = ts.get_node_text(class_node, 0):gsub('\\', '/')
    vim.cmd('find +/' .. method_name .. ' ' ..class_name)
    vim.cmd('norm zzwww')
    return true
  end
  return false
end


M.setup = function() end

return M


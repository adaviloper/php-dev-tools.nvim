local ts = vim.treesitter
local parsers = require('nvim-treesitter.parsers')
local parser = parsers.get_parser()
local targetClass = nil
local targetMethod = nil

local imported_name_qs = [[
(array_creation_expression
  (array_element_initializer
    (class_constant_access_expression
      (name)? @class (#not-eq? @class "class")
    )
  )
  (array_element_initializer
    (string (string_value) @method)
  )
)
]]
local qualified_name_qs = [[
(array_creation_expression
  (array_element_initializer
    (class_constant_access_expression
      (qualified_name
        (name) @class
      )
    )
  )
  (array_element_initializer
    (string (string_value) @method)
  )
)
  ]]

local M = {}

local p = function(message)
  vim.notify(message, 3)
end

local function get_namespace(class_name)
  local language = parser:lang()
  local tree = parser:parse()[1]
  local node = tree:root()
  local namespace_qs = '\
(namespace_use_declaration\
  (namespace_use_clause\
    (qualified_name) @class\
    ) @clause (#match? @clause ".*' .. class_name .. '")\
  )'
  local query = ts.query.parse(language, namespace_qs)
  for i, match, _ in query:iter_captures(node, 0) do
    local name = query.captures[i]
    if name == 'class' then
      return ts.get_node_text(match, 0)
    end
  end
end

local function parse_groups(query, current_node, declaration_type)
  for i, match, _ in query:iter_captures(current_node:parent():parent(), 0) do
    local name = query.captures[i]
    if name == 'method' then
      targetMethod = ts.get_node_text(match, 0)
    end
    if name == 'class' then
      targetClass = ts.get_node_text(match, 0)
    end
  end
end

---@return boolean, string?, string?, string?
M.validate_touple = function()
  local language = parser:lang()
  if language ~= 'php' then
    return false
  end
  local node = ts.get_node()
  if node == nil or (node:type() ~= 'string' and node:type() ~= 'string_value') then
    return false
  end
  if node:type() == 'string_value' then
    node = node:parent()
  end
  local sibling_type = node:parent():prev_sibling():prev_sibling():child(0):child(0):type()
  if sibling_type ~= 'name' and sibling_type ~= 'qualified_name' then
    return false
  end

  if sibling_type == 'name' then
    local imported_query = ts.query.parse(language, imported_name_qs)
    parse_groups(imported_query, node, 'imported')
    if targetClass ~= nil and targetMethod ~= nil then
      return true, targetClass, targetMethod, 'imported'
    end
  else
    local qualified_name_query = ts.query.parse(language, qualified_name_qs)
    parse_groups(qualified_name_query, node, 'inline')
    if targetClass ~= nil and targetMethod ~= nil then
      return true, targetClass, targetMethod, 'inline'
    end
  end


  return false
end

---@return boolean
M.go_to_definition = function()
  local isValidTouple, className, methodName, type = M.validate_touple()
  targetClass = nil
  targetMethod = nil
  if isValidTouple and className and methodName then
    className = get_namespace(className)
    if className:sub(1, 1) == '\\' then
      className = className:sub(2)
    end
    className = className:gsub('\\', '/')
    vim.cmd('find +/' .. methodName .. ' ' .. className)
    vim.cmd('norm zzwww')
    return true
  end
  return false
end


M.setup = function() end

return M

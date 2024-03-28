local ts = vim.treesitter
local get_node_text = ts.get_node_text

local TestUtils = {
  last_test = nil,
}

---@param config table
TestUtils.setup = function (config)
  TestUtils.config = config
end

local get_target_node = function(node_name)
  local node = vim.treesitter.get_node()

  while node ~= nil do
    if node:type() == node_name then
      return node
    end

    node = node:parent()
  end
end

local function run_test(test)
  TestUtils.last_test = test
  vim.cmd('TermExec cmd="' .. TestUtils.config[vim.loop.cwd()].cmd .. ' ' .. test .. '"')
end

local function test_symbol(node, lang, schema)
  if not node then
    vim.notify('No target node found.')
    return
  end

  local query = assert(vim.treesitter.query.get(lang, schema), 'No query')
  for _, capture in query:iter_captures(node, 0) do
    if TestUtils.config[vim.loop.cwd()] ~= nil then
      run_test(get_node_text(capture, 0))
    end
  end
end

TestUtils.test_last_test = function()
  run_test(TestUtils.last_test)
end

TestUtils.test_nearest_method = function()
  local node = get_target_node('method_declaration')
  if node == nil then
    node = get_target_node('function_call_expression')
    test_symbol(node, 'php', 'pest-test-name')
  else
    test_symbol(node, 'php', 'method-name')
  end
end

TestUtils.test_current_file = function()
  local node = get_target_node('class_declaration')
  test_symbol(node, 'php', 'class-name')
end

return TestUtils

local ts = vim.treesitter
local get_node_text = ts.get_node_text

---@class PerDirectoryConfig
---@field dir string
---@field command string
---@field group_cmd string
---@field groups string[]

---@class Config
---@field last_test string|nil
---@field config {[table]:PerDirectoryConfig}|nil

---@type Config
local TestUtils = {
  last_test = nil,
  config = nil,
}

local function get_phpunit_groups()
  local cwd = vim.loop.cwd()

  -- If cached, return immediately
  if TestUtils.config[cwd]._groups ~= nil then
    return TestUtils.config[cwd]._groups
  end

  -- Initialize with an empty table to avoid nil issues
  TestUtils.config[cwd]._groups = {}

  local cmd = TestUtils.config[cwd].group_cmd
  if cmd == nil then return {} end

  local stdout = vim.loop.new_pipe(false)
  local handle

  handle = vim.loop.spawn("sh", {
    args = { "-c", cmd }, -- Execute the command in the shell
    stdio = { nil, stdout, nil }
  }, function(code, _)
    stdout:close()
    handle:close()

    if code ~= 0 then
      vim.notify("Failed to fetch test groups", vim.log.levels.ERROR)
      return
    end
  end)

  local output = {}

  stdout:read_start(function(err, data)
    if err then
      vim.notify("Error reading output: " .. err, vim.log.levels.ERROR)
      return
    end
    if data then
      for line in data:gmatch("[^\r\n]+") do
        local group = line:match("%s*%- ([a-zA-Z%-_]+) .+")
        if group then
          table.insert(output, group)
        end
      end
    else
      -- Cache the result once reading is done
      TestUtils.config[cwd]._groups = output
    end
  end)

  return TestUtils.config[cwd].groups
end

---@param config table
TestUtils.setup = function (config)
  TestUtils.config = config
  get_phpunit_groups()
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
      run_test('--filter ' .. get_node_text(capture, 0))
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

TestUtils.test_group = function()
  if TestUtils.config[vim.loop.cwd()] ~= nil then
    vim.ui.select(
      get_phpunit_groups(),
      {
        prompt = 'Select a test group:'
      },
      function (choice)
        if choice ~= nil then
          run_test('--group ' .. choice)
        end
      end
    )
  end
end

return TestUtils

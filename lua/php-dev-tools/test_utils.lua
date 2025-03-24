local ts = require("php-dev-tools.utils.ts")

---@class PerDirectoryConfig
---@field dir string
---@field command string
---@field group_cmd string
---@field _groups string[]

---@class Config
---@field last_test string|nil
---@field config {[table]:PerDirectoryConfig}

---@type Config
local TestUtils = {
  last_test = nil,
  config = {},
}

local function update_phpunit_groups()
  local cwd = vim.uv.cwd()

  local cmd = TestUtils.config[cwd].group_cmd
  if cmd == nil then
    return {}
  end

  local stdout = vim.uv.new_pipe(false)
  local handle

  handle = vim.uv.spawn("sh", {
    args = { "-c", cmd }, -- Execute the command in the shell
    stdio = { nil, stdout, nil },
  }, function(code, _)
    if stdout then stdout:close() end
    if handle then handle:close() end

    if code ~= 0 then
      vim.schedule(function() -- Schedule the API call safely
        vim.notify("Failed to fetch test groups", vim.log.levels.ERROR)
      end)
      return
    end
  end)

  local output = {}

  if stdout then
    stdout:read_start(function(err, data)
      if err then
        vim.schedule(function ()
          vim.notify("Error reading output: " .. err, vim.log.levels.ERROR)
        end)
        return
      end
      if data then
        for line in data:gmatch("[^\r\n]+") do
          local group = line:match("%s*- ([a-zA-Z%-_]+)")
          if group then
            table.insert(output, group)
          end
        end
      end
    end)
  end

  vim.schedule(function()
    TestUtils.config[cwd]._groups = output
  end)

  return TestUtils.config[cwd]._groups
end

local function get_phpunit_groups()
  local cwd = vim.uv.cwd()

  -- Initialize with an empty table to avoid nil issues
  if TestUtils.config[cwd]._groups == nil then
    TestUtils.config[cwd]._groups = {}
  end

  -- If cached, return immediately
  if #TestUtils.config[cwd]._groups > 0 then
    update_phpunit_groups()
    return TestUtils.config[cwd]._groups
  else
    return update_phpunit_groups()
  end
end

---@param config table
TestUtils.setup = function(config)
  TestUtils.config = config
  if vim.fs.root(0, 'phpunit.xml') then
    get_phpunit_groups()
  end
end

local function run_test(test)
  TestUtils.last_test = test
  vim.cmd('TermExec cmd="' .. TestUtils.config[vim.uv.cwd()].cmd .. " " .. test .. '"')
end

local function test_symbol(node, lang, schema)
  if not node then
    vim.notify("No target node found.")
    return
  end

  local query = assert(vim.treesitter.query.get(lang, schema), "No query")
  for _, capture in query:iter_captures(node, 0) do
    if TestUtils.config[vim.uv.cwd()] ~= nil then
      run_test("--filter " .. ts.get_node_text(capture, 0))
    end
  end
end

TestUtils.test_last_test = function()
  run_test(TestUtils.last_test)
end

TestUtils.test_nearest_method = function()
  local node = ts.get_target_node("method_declaration")
  if node == nil then
    node = ts.get_target_node("function_call_expression")
    test_symbol(node, "php", "pest-test-name")
  else
    test_symbol(node, "php", "method-name")
  end
end

TestUtils.test_current_file = function()
  local node = ts.get_target_node("class_declaration")
  test_symbol(node, "php", "class-name")
end

TestUtils.test_group = function()
  if TestUtils.config[vim.uv.cwd()] ~= nil then
    vim.ui.select(get_phpunit_groups(), {
      prompt = "Select a test group:",
    }, function(choice)
      if choice ~= nil then
        run_test("--group " .. choice)
      end
    end)
  end
end

return TestUtils

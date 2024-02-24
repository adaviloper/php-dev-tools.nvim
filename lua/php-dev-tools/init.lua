local test_utils = require "php-dev-tools.test_utils"
local go_to      = require "php-dev-tools.go_to"
local config     = require "php-dev-tools.config"
local M = {}

M.test_utils = {
  test_current_file = test_utils.test_current_file,
  test_nearest_method = test_utils.test_nearest_method
}

M.go_to = {
  go_to_definition = go_to.go_to_definition
}


M.setup = function(opts)
  config.set(opts)
  vim.notify(vim.inspect(config))
end

return M

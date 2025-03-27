# PHP Dev Tools

## Setup
Lazy
```lua
return {
  'adaviloper/php-dev-tools.nvim',
  ft = 'php',
  dependencies = {
    'akinsho/toggleterm.nvim',
  },
  config = function ()
    require('php-dev-tools').setup({
        test_utils = {
          {
            dir = '~/path/to/project',
            cmd = '<test command to run>',
            group_cmd = '<command to fetch test groups',
          },
        }
    })
  end,
}
```

## Functionality
Bind these to whatever keys you'd like.
```lua
--- Test the method your cursor is in
require('php-dev-tools').test_nearest_method()

--- Test the current file
require('php-dev-tools').test_current_file()

--- Pull up a window to display the different tests groups
require('php-dev-tools').test_group()

--- Re-run the previous test call
require('php-dev-tools').test_last_test()
```

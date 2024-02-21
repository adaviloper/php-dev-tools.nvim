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
    require('php-dev-tools').setup()
  end,
}
```

## Functionality
Bind these to whatever keys you'd like.
```lua
require('php-dev-tools').test_nearest_method()
require('php-dev-tools').test_current_file()
```

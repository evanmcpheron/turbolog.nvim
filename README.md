# rocketlog.nvim

A small Neovim plugin for inserting `console.log` statements with a rocket label, file name, and line number.

## Features

- **Operator-pending logging** via `<leader>cl` + motion/textobject
- **Word-under-cursor logging** via `<leader>cL`
- Heuristic insertion **after the current statement** (helps with multiline calls/objects)
- JS/TS filetype guard (JavaScript / TypeScript + React variants)

## Default Keymaps

- `<leader>cliw` → log inner word
- `<leader>cli"` → log inside quotes
- `<leader>cla"` → log around quotes
- `<leader>cli(` → log inside parens
- `<leader>cla{` → log around braces
- `<leader>cL` → log word under cursor

## Installation (lazy.nvim)

```lua
{
  "evanmcpheron/rocketlog.nvim",
  config = function()
    require("rocketlog").setup()
  end,
}
```

## Configuration

```lua
require("rocketlog").setup({
  keymaps = {
    operator = "<leader>cl",
    word = "<leader>cL",
  },
  enabled = true,
  allowed_filetypes = {
    javascript = true,
    javascriptreact = true,
    typescript = true,
    typescriptreact = true,
  },
})
```

### Disable auto-setup

If you prefer explicit setup only, set this before the plugin loads:

```lua
vim.g.rocketlog_disable_auto_setup = true
```

## Command

- `:RocketLogWord` → Inserts a log for the word under the cursor

## Inspiration

- The inspiration for this plugin cam from [TurboLog](https://www.turboconsolelog.io/)
# turbolog.nvim

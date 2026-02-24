# rocketlog.nvim

A Neovim plugin for inserting `console.log` / `console.error` statements with a rocket label, file name, and line number.

This MVP uses **Tree-sitter first** for syntax-aware placement and falls back to line-based heuristics when Tree-sitter is unavailable.

## Features

- Operator-pending logging via `<leader>cl` + motion/textobject
- Word-under-cursor logging via `<leader>cL`
- Error logging variants via `<leader>ce` and `<leader>cE`
- Tree-sitter insertion (JS/TS/React) with heuristic fallback
- Refreshes RocketLog labels on save and optionally after insert
- Guards against unsafe insertion in implicit arrow returns

## Default Keymaps

- `<leader>cliw` → log inner word (operator + textobject)
- `<leader>cL` → log word under cursor
- `<leader>ceiw` → error-log inner word (operator + textobject)
- `<leader>cE` → error-log word under cursor

## Installation (lazy.nvim)

```lua
{
  "yourname/rocketlog.nvim",
  dependencies = {
    -- Recommended for syntax-aware insertion:
    "nvim-treesitter/nvim-treesitter",
  },
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
    error_operator = "<leader>ce",
    error_word = "<leader>cE",
  },
  enabled = true,
  refresh_on_save = true,
  refresh_on_insert = true,
  prefer_treesitter = true,
  fallback_to_heuristics = true,
  allowed_filetypes = {
    javascript = true,
    javascriptreact = true,
    typescript = true,
    typescriptreact = true,
  },
})
```

## Notes

- Tree-sitter placement is much safer than line heuristics, especially for multiline chains and object literals.
- If you try to log inside an **implicit arrow return** (e.g. `x => x.id`), the plugin warns instead of inserting invalid or misleading code.
- If Tree-sitter cannot parse the buffer, the plugin falls back to the older line-based insertion logic (unless disabled).

## Disable auto-setup

If you prefer explicit setup only, set this before the plugin loads:

```lua
vim.g.rocketlog_disable_auto_setup = true
```

# Rocketlog.nvim

A lightweight Neovim plugin for inserting structured `console.*` statements in JavaScript and TypeScript files.

`rocketlog.nvim` adds labeled logs with a consistent format that includes the file name and line number, and it can keep those labels updated as your code moves.

For details on how to help improve this tool, see [CONTRIBUTING.md](./CONTRIBUTING.md).
For submitting an issue or feature request, see [issues](https://github.com/evanmcpheron/rocketlog.nvim/issues).

```typescript
console.log(`🚀[ROCKETLOG] ~ file.ts:123 ~ variableName:`, variableName);
console.warn(`🚀[ROCKETLOG] ~ file.ts:123 ~ variableName:`, variableName);
console.error(`🚀[ROCKETLOG] ~ file.ts:123 ~ variableName:`, variableName);
console.info(`🚀[ROCKETLOG] ~ file.ts:123 ~ variableName:`, variableName);
```

## Features

- Operator-pending logging (works with motions/text objects)
- Word-under-cursor logging
- Visual selection logging
- Tree-sitter-first insertion for safer placement in real code structures
- Heuristic fallback when Tree-sitter is unavailable
- Automatic label refresh on save and after insertion
- Guardrails to prevent invalid insertion in unsafe contexts
- Log cleanup helpers for next/previous/current-buffer removal
- Project-wide RocketLog search via `snacks.nvim`
- **RocketLog Dashboard** for grouped inspection, preview, jump, delete, and refresh workflows

## Default Keymaps

### Insert logs
- `<leader>rl` → `console.log` with operator-pending motions
- `<leader>rL` → `console.log` for the word under cursor
- `<leader>re` / `<leader>rE` → `console.error`
- `<leader>rw` / `<leader>rW` → `console.warn`
- `<leader>ri` / `<leader>rI` → `console.info`

### Log management
- `<leader>rf` → open the RocketLog picker
- `<leader>rr` → toggle the RocketLog dashboard
- `<leader>rd` → delete next RocketLog below the cursor
- `<leader>rD` → delete nearest RocketLog above the cursor
- `<leader>ra` → delete all RocketLogs in the current buffer

## Commands

- `:RocketLogFind`
- `:RocketLogDashboard`

## Dashboard

The dashboard is a centered floating inspector designed to feel more like a debugging command center than a picker. It now ships with a stacked left column (overview, log list, and an always-visible cheatsheet), a preview pane on the right, foldable file groups, a live filter prompt, and richer multiline summaries in the log list.

Inside the dashboard:
- `<CR>` / `o` close the dashboard and open the selected log in the current window
- `v` open the selected log in a vertical split
- `d` delete the selected log
- `D` delete every RocketLog in the selected file
- `r` refresh labels in the selected file
- `R` rescan the dashboard
- `/` open a live filter prompt
- `c` clear the current filter
- `<Tab>` / `za` fold or unfold the selected file
- `zo` / `zc` open or close a selected file fold
- `zR` / `zM` expand or collapse every file group
- `t` toggle between project and current-file scope
- `q` close the dashboard

## Installation (lazy.nvim)

```lua
{
  "evanmcpheron/rocketlog.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "folke/snacks.nvim",
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
    motions = "<leader>rl",
    word = "<leader>rL",
    error_motions = "<leader>re",
    error_word = "<leader>rE",
    warn_motions = "<leader>rw",
    warn_word = "<leader>rW",
    info_motions = "<leader>ri",
    info_word = "<leader>rI",
    delete_below = "<leader>rd",
    delete_above = "<leader>rD",
    delete_all_buffer = "<leader>ra",
    find = "<leader>rf",
    dashboard = "<leader>rr",
  },

  label = "ROCKETLOG",
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

  dashboard = {
    width = 0.9,
    height = 0.85,
    preview_context = 4,
  },
})
```

## Notes

- Tree-sitter is strongly recommended for safer insertion.
- The dashboard prefers live buffer contents for open files and falls back to project file scans for everything else.
- If `rg` is available, the dashboard uses it to narrow project scans before parsing files.

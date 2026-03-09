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

- **Operator-pending logging** (works with motions/text objects)
- **Word-under-cursor logging**
- **Visual-mode logging**
- Supports:
  - `console.log`
  - `console.error`
  - `console.warn`
  - `console.info`
- **Tree-sitter-first insertion** for safer placement in real code structures
- **Heuristic fallback** when Tree-sitter is unavailable
- **Automatic label refresh**
  - On save (configurable)
  - Immediately after insertion (configurable)
- **Guardrails** to prevent invalid insertion in unsafe contexts (such as implicit arrow returns)
- Log cleanup helpers:
  - Delete next RocketLog
  - Delete previous RocketLog
  - Clear all RocketLogs in the current buffer
- Project-wide RocketLog search via `snacks.nvim` picker integration

![RocketLog demo](https://github.com/user-attachments/assets/4e6cf464-e8c2-4b1f-bd52-105f84e0cbc5)

---

## Default Keymaps

### Insert logs (operator-pending)

Use the motions mapping followed by a motion or text object.

- `<leader>rl` → `console.log`
- `<leader>re` → `console.error`
- `<leader>rw` → `console.warn`
- `<leader>ri` → `console.info`

### Insert logs (visual mode)

Use the same mappings while in visual mode to log the highlighted text.

- `<leader>rl` → `console.log`
- `<leader>re` → `console.error`
- `<leader>rw` → `console.warn`
- `<leader>ri` → `console.info`

### Insert logs (word under cursor)

- `<leader>rL` → `console.log`
- `<leader>rE` → `console.error`
- `<leader>rW` → `console.warn`
- `<leader>rI` → `console.info`

### Delete logs

- `<leader>rd` → delete next RocketLog below the cursor
- `<leader>rD` → delete nearest RocketLog above the cursor
- `<leader>ra` → delete **ALL** RocketLogs in the current buffer

### Find logs

- `<leader>rf` → open the RocketLog picker

---

## Installation (lazy.nvim)

```lua
{
  "evanmcpheron/rocketlog.nvim",
  dependencies = {
    -- Recommended for syntax-aware insertion
    "nvim-treesitter/nvim-treesitter",
    -- Optional picker used by :RocketLogFind and <leader>rf
    "folke/snacks.nvim",
  },
  config = function()
    require("rocketlog").setup()
  end,
}
```

---

## Configuration

```lua
require("rocketlog").setup({
  keymaps = {
    motions = "<leader>rl",
    word = "<leader>rL",
    visual = "<leader>rl",

    error_motions = "<leader>re",
    error_word = "<leader>rE",
    error_visual = "<leader>re",

    warn_motions = "<leader>rw",
    warn_word = "<leader>rW",
    warn_visual = "<leader>rw",

    info_motions = "<leader>ri",
    info_word = "<leader>rI",
    info_visual = "<leader>ri",

    delete_below = "<leader>rd",
    delete_above = "<leader>rD",
    delete_all_buffer = "<leader>ra",
    find = "<leader>rf",
  },

  enabled = true,

  label = "ROCKETLOG", -- customize the marker label inside []

  -- Refresh RocketLog file:line labels automatically
  refresh_on_save = true, -- updates line numbers on file save when true
  refresh_on_insert = true, -- updates line numbers for entire file when adding a new log

  -- Insertion strategy
  prefer_treesitter = true, -- strongly recommended
  fallback_to_heuristics = true, -- best-effort fallback when Tree-sitter is unavailable

  -- Filetypes allowed for insertion and refresh
  allowed_filetypes = {
    javascript = true,
    javascriptreact = true,
    typescript = true,
    typescriptreact = true,
  },
})
```

---

## Usage Examples

### Log a text object

Press the motions mapping, then a motion/text object:

- `<leader>rliw` → log inner word
- `<leader>rla"` → log around quotes
- `<leader>rli(` → log inside parentheses

### Log the current visual selection

Select text in visual mode, then press the matching log mapping:

- `v` + highlight + `<leader>rl`
- `v` + highlight + `<leader>re`

### Log the word under the cursor

- `<leader>rL`

### Insert an error log instead

- `<leader>rE` (word under cursor)
- `<leader>reiw` (operator-pending + text object)

---

## How It Works

RocketLog inserts logs in a consistent format that includes:

- A RocketLog marker
- The current file name
- The line number where the log lives
- The selected expression label

When code shifts and line numbers change, RocketLog can refresh the labels automatically so they stay accurate.

---

## Notes

- **Tree-sitter is strongly recommended** for safer insertion, especially around multiline chains, object literals, and nested expressions.
- If Tree-sitter is unavailable or cannot parse the current buffer, RocketLog can fall back to line-based insertion when `fallback_to_heuristics = true`.
- RocketLog will warn and skip insertion in contexts where adding a statement would break syntax (for example, inside an implicit arrow function return).
- The fallback insertion path is best-effort logic, not a full parser.

---

## Disable Auto Setup

By default, the plugin can auto-initialize with default settings.

To disable that and call `setup()` manually, set this before the plugin loads:

```lua
vim.g.rocketlog_disable_auto_setup = true
```

---

## Help

The repo includes vimdoc at `doc/rocketlog.txt`, so users can install helptags and use `:help rocketlog`.

---

## License

MIT License

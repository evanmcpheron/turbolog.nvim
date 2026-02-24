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



![202602240806-ezgif com-video-to-gif-converter (1)](https://github.com/user-attachments/assets/4e6cf464-e8c2-4b1f-bd52-105f84e0cbc5)
ea57bb
<img width="2904" height="1640" alt="image" src="https://github.com/user-attachments/assets/eaedcc6b-ccdd-4e72-b035-2618678aafed" />

---

## Default Keymaps

### Insert logs (VIM-motions-pending)

Use the operator mapping followed by a motion or text object.

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

---

## Installation (lazy.nvim)

```lua
{
  "evanmcpheron/rocketlog.nvim",
  dependencies = {
    -- Recommended for syntax-aware insertion
    "nvim-treesitter/nvim-treesitter",
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
    operator = "<leader>rl",
    word = "<leader>rL",

    error_operator = "<leader>re",
    error_word = "<leader>rE",

    warn_operator = "<leader>rw",
    warn_word = "<leader>rW",

    info_operator = "<leader>ri",
    info_word = "<leader>rI",

    delete_below = "<leader>rd",
    delete_above = "<leader>rD",
    delete_all_buffer = "<leader>ra",
  },

  enabled = true,

  label = "ROCKETLOG", -- customize your label that goes in the []

  -- Refresh RocketLog file:line labels automatically
  refresh_on_save = true, -- updates line numbers on file save when true
  refresh_on_insert = true, -- updates line numbers for entire file when adding a new log

  -- Insertion strategy
  prefer_treesitter = true, -- Highly recommended to keep true... It may not work if it's false.
  fallback_to_heuristics = true, -- this is a "fail-safe" (recommended to keep true)

  -- Filetypes allowed for insertion
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

Press the operator mapping, then a motion/text object:

- `<leader>rliw` → log inner word
- `<leader>rla"` → log around quotes
- `<leader>rli(` → log inside parentheses

### Log the word under the cursor

- `<leader>rL`

### Insert an error log instead

- `<leader>rE` (word under cursor)
- `<leader>reiw` (operator + text object)

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
- If Tree-sitter is unavailable or cannot parse the current buffer, RocketLog can fall back to line-based insertion (if enabled).
- RocketLog will warn and skip insertion in contexts where adding a statement would break syntax (for example, inside an implicit arrow function return).

---

## Disable Auto Setup

By default, the plugin can auto-initialize with default settings.

To disable that and call `setup()` manually, set this before the plugin loads:

```lua
vim.g.rocketlog_disable_auto_setup = true
```

---

## License

MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

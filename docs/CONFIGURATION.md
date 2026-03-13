# Configuration reference

`rocketlog.nvim` exposes a single setup entrypoint:

```lua
require("rocketlog").setup({...})
```

This page documents every supported option and shows practical examples.

---

## Full default config

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
    width = 0.96,
    height = 0.92,
    preview_context = 4,
    max_files = 2000,
    excluded_dirs = {
      ".git",
      "node_modules",
      "dist",
      "build",
      "coverage",
      ".next",
      ".turbo",
    },
  },
})
```

---

## Top-level options

| Option | Type | Default | Description |
|---|---|---|---|
| `label` | `string` | `"ROCKETLOG"` | Label used in inserted log markers |
| `enabled` | `boolean` | `true` | Enables setup, user commands, and keymaps |
| `refresh_on_save` | `boolean` | `true` | Refresh labels before buffer write |
| `refresh_on_insert` | `boolean` | `true` | Refresh labels immediately after insertion |
| `prefer_treesitter` | `boolean` | `true` | Prefer Tree-sitter for insertion target resolution |
| `fallback_to_heuristics` | `boolean` | `true` | Fall back to heuristic insertion logic if Tree-sitter cannot resolve a target |
| `allowed_filetypes` | `table<string, boolean> \| nil` | JS/TS defaults | Filetypes RocketLog is allowed to operate on |
| `keymaps` | `table` | see defaults | Built-in keymap configuration |
| `dashboard` | `table` | see defaults | Dashboard UI and scan settings |

---

## `label`

```lua
require("rocketlog").setup({
  label = "DEBUG"
})
```

Result:

```ts
console.log(`🚀[DEBUG] ~ file.ts:12 ~ user:`, user);
```

RocketLog normalizes the label by trimming and collapsing whitespace.

---

## `enabled`

Disable the plugin without removing it from your config:

```lua
require("rocketlog").setup({
  enabled = false,
})
```

When disabled, RocketLog does not register its user commands or keymaps.

---

## Refresh behavior

### `refresh_on_save`

```lua
require("rocketlog").setup({
  refresh_on_save = true,
})
```

Keeps labels synchronized when the buffer is written.

### `refresh_on_insert`

```lua
require("rocketlog").setup({
  refresh_on_insert = true,
})
```

Useful if you want labels corrected immediately after insertion.

---

## Insertion strategy

### `prefer_treesitter`

```lua
require("rocketlog").setup({
  prefer_treesitter = true,
})
```

Recommended. Tree-sitter gives RocketLog better odds of placing logs after the correct statement.

### `fallback_to_heuristics`

```lua
require("rocketlog").setup({
  fallback_to_heuristics = true,
})
```

If Tree-sitter is unavailable or cannot resolve the context, RocketLog can fall back to heuristic logic.

If you turn this off, RocketLog becomes stricter and may refuse insertions that it otherwise would attempt.

---

## `allowed_filetypes`

Default:

```lua
allowed_filetypes = {
  javascript = true,
  javascriptreact = true,
  typescript = true,
  typescriptreact = true,
}
```

You can override entries:

```lua
require("rocketlog").setup({
  allowed_filetypes = {
    javascript = true,
    javascriptreact = true,
    typescript = true,
    typescriptreact = true,
    lua = false,
  },
})
```

You can also allow everything by setting `allowed_filetypes = nil`:

```lua
require("rocketlog").setup({
  allowed_filetypes = nil,
})
```

That said, the default documented path is JavaScript and TypeScript. If you expand beyond that, test carefully in your own setup instead of assuming magic.

---

## `keymaps`

### Default keymaps

| Key | Option |
|---|---|
| `<leader>rl` | `motions` |
| `<leader>rL` | `word` |
| `<leader>re` | `error_motions` |
| `<leader>rE` | `error_word` |
| `<leader>rw` | `warn_motions` |
| `<leader>rW` | `warn_word` |
| `<leader>ri` | `info_motions` |
| `<leader>rI` | `info_word` |
| `<leader>rd` | `delete_below` |
| `<leader>rD` | `delete_above` |
| `<leader>ra` | `delete_all_buffer` |
| `<leader>rf` | `find` |
| `<leader>rr` | `dashboard` |

### Example: customize leader keys

```lua
require("rocketlog").setup({
  keymaps = {
    motions = "<leader>dl",
    word = "<leader>dL",
    dashboard = "<leader>dd",
  },
})
```

### Example: disable selected keymaps

Set a key to `false` or `nil` if you do not want RocketLog to register it.

```lua
require("rocketlog").setup({
  keymaps = {
    find = false,
    delete_all_buffer = false,
  },
})
```

---

## `dashboard`

### Default values

| Option | Type | Default | Description |
|---|---|---|---|
| `width` | `number` | `0.96` | Width of the root dashboard window, relative to editor size |
| `height` | `number` | `0.92` | Height of the root dashboard window, relative to editor size |
| `preview_context` | `integer` | `4` | Number of surrounding source lines shown in preview |
| `max_files` | `integer` | `2000` | Max number of project files to scan |
| `excluded_dirs` | `string[]` | default list | Directories skipped during scans |

### Example: smaller dashboard

```lua
require("rocketlog").setup({
  dashboard = {
    width = 0.85,
    height = 0.80,
    preview_context = 6,
  },
})
```

### Example: customize excluded directories

```lua
require("rocketlog").setup({
  dashboard = {
    excluded_dirs = {
      ".git",
      "node_modules",
      "dist",
      "coverage",
      ".next",
      "storybook-static",
    },
  },
})
```

---

## Practical setup examples

### Minimal and safe

```lua
require("rocketlog").setup({
  prefer_treesitter = true,
  fallback_to_heuristics = true,
  refresh_on_save = true,
  refresh_on_insert = true,
})
```

### More conservative

```lua
require("rocketlog").setup({
  fallback_to_heuristics = false,
})
```

### Custom label for team-wide consistency

```lua
require("rocketlog").setup({
  label = "TEMPDEBUG",
})
```

### Dashboard-focused workflow

```lua
require("rocketlog").setup({
  dashboard = {
    width = 0.92,
    height = 0.90,
    preview_context = 8,
  },
})
```

---

## Setup behavior

`plugin/rocketlog.lua` automatically calls:

```lua
require("rocketlog").setup()
```

If you want to disable that and call setup yourself:

```lua
vim.g.rocketlog_disable_auto_setup = true
require("rocketlog").setup({
  label = "DEBUG",
})
```

---

## Related docs

- [Getting started](./GETTING_STARTED.md)
- [Usage guide](./USAGE.md)
- [Dashboard guide](./DASHBOARD.md)

# rocketlog.nvim

A Neovim plugin for **fast, structured debug logging** in JavaScript and TypeScript.

`rocketlog.nvim` helps you insert consistent `console.*` statements, keep embedded file/line labels fresh as code moves, and manage existing logs from a purpose-built dashboard instead of hunting through files like a raccoon in a cable drawer.

---

## What you get

- **Operator-pending log insertion** for motions and text objects
- **Word-under-cursor logging** when you just need a quick probe
- **Consistent `console.log` / `warn` / `error` / `info` output**
- **Automatic label refresh** on insert and save
- **Safety guardrails** for unsafe insertion contexts
- **Delete helpers** for next, previous, or all logs in a buffer
- **Project log picker** via `snacks.nvim`
- **RocketLog Dashboard** for previewing, filtering, folding, toggling, refreshing, and opening logs
- **Built-in dashboard footer cheatsheet** plus a dedicated **help modal** on `?`

---

## Documentation map

| Doc | What it covers |
|---|---|
| [Docs index](./docs/README.md) | Start here for the full documentation set |
| [Getting started](./docs/GETTING_STARTED.md) | Install, configure, and use RocketLog in a few minutes |
| [Usage guide](./docs/USAGE.md) | Motions, word logging, deletion, refresh behavior, workflows |
| [Dashboard guide](./docs/DASHBOARD.md) | Dashboard layout, keybindings, filters, folds, toggles |
| [Configuration reference](./docs/CONFIGURATION.md) | Every setup option and practical examples |
| [Troubleshooting](./docs/TROUBLESHOOTING.md) | Common issues, warnings, and fixes |
| [Media guide](./docs/assets/README.md) | Screenshot and GIF placeholders to replace before release |
| [Contributing](./CONTRIBUTING.md) | Dev setup, tests, and contribution expectations |

---

## Quick look

```ts
console.log(`🚀[ROCKETLOG] ~ user.ts:42 ~ account:`, account);
console.warn(`🚀[ROCKETLOG] ~ user.ts:42 ~ account:`, account);
console.error(`🚀[ROCKETLOG] ~ user.ts:42 ~ account:`, account);
console.info(`🚀[ROCKETLOG] ~ user.ts:42 ~ account:`, account);
```

### Before

```ts
const fullName = user.profile.name;
```

### After pressing `<leader>rL` on `fullName`

```ts
const fullName = user.profile.name;
console.log(`🚀[ROCKETLOG] ~ user.ts:2 ~ fullName:`, fullName);
```

> **Media placeholder — hero GIF**
>
> Add a short GIF here showing:
> 1. opening a TypeScript file,
> 2. inserting a log with `<leader>rL`,
> 3. saving the file,
> 4. opening the dashboard with `<leader>rr`,
> 5. pressing `?` to open the help modal.
>
> Suggested filename: `docs/assets/hero-overview.gif`

---

## Installation

### Full setup (recommended)

This gives you the full experience, including the picker command.

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

### Minimal setup

If you do not care about the picker, `snacks.nvim` is not required. The plugin will still work, and `:RocketLogFind` will simply warn if `snacks.nvim` is unavailable.

```lua
{
  "evanmcpheron/rocketlog.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
  },
  config = function()
    require("rocketlog").setup()
  end,
}
```

### Disable automatic setup

By default, `plugin/rocketlog.lua` calls `require("rocketlog").setup()` automatically.

If you want full control over when setup runs:

```lua
vim.g.rocketlog_disable_auto_setup = true
require("rocketlog").setup()
```

---

## Quick start

1. Install the plugin.
2. Open a JavaScript or TypeScript file.
3. Put your cursor on a variable and press `<leader>rL`.
4. Or use `<leader>rl` followed by a motion or text object, like `iw`.
5. Open the dashboard with `<leader>rr`.
6. Use `c` to toggle a selected log on or off, `d` to delete it, or `<CR>` to jump to it.
7. Press `?` inside the dashboard any time you want the full help modal.

For the full walkthrough, see [Getting started](./docs/GETTING_STARTED.md).

---

## Default keymaps

### Insert logs

| Keymap | Action |
|---|---|
| `<leader>rl` | `console.log` using a motion or text object |
| `<leader>rL` | `console.log` for the word under cursor |
| `<leader>re` | `console.error` using a motion or text object |
| `<leader>rE` | `console.error` for the word under cursor |
| `<leader>rw` | `console.warn` using a motion or text object |
| `<leader>rW` | `console.warn` for the word under cursor |
| `<leader>ri` | `console.info` using a motion or text object |
| `<leader>rI` | `console.info` for the word under cursor |

### Manage logs

| Keymap | Action |
|---|---|
| `<leader>rf` | Open the RocketLog picker |
| `<leader>rr` | Toggle the RocketLog dashboard |
| `<leader>rd` | Delete the next RocketLog below the cursor |
| `<leader>rD` | Delete the nearest RocketLog above the cursor |
| `<leader>ra` | Delete all RocketLogs in the current buffer |

For examples using motions like `iw`, `a{`, and more, see [Usage](./docs/USAGE.md).

---

## Commands

| Command | Action |
|---|---|
| `:RocketLogFind` | Open the RocketLog picker |
| `:RocketLogDashboard` | Open the dashboard |

---

## Dashboard at a glance

The dashboard is the plugin’s command center. It groups logs by file, shows a preview pane, keeps an always-visible footer cheatsheet on screen, and opens a dedicated help modal on `?` when you want the full keybinding reference without leaving the UI.

### Dashboard keybindings

| Key | Action |
|---|---|
| `<CR>` / `o` | Open selected log in the current window and close the dashboard |
| `v` | Open selected log in a vertical split and close the dashboard |
| `c` | Toggle the selected log’s comment state |
| `C` | Toggle all logs in the selected file |
| `d` | Delete the selected log |
| `D` | Delete all logs in the selected file |
| `r` | Refresh labels in the selected file |
| `R` | Rescan the dashboard |
| `/` | Open the live filter prompt |
| `x` | Clear the current filter |
| `<Tab>` / `za` | Toggle the selected file fold |
| `zo` / `zc` | Open or close the selected file fold |
| `zR` / `zM` | Expand or collapse all file groups |
| `t` | Toggle project scope / current-file scope |
| `?` | Open the dashboard help modal |
| `q` / `<Esc>` | Close the dashboard, or close the help modal if it is open |

See [Dashboard guide](./docs/DASHBOARD.md) for the full walkthrough.

> **Media placeholder — dashboard screenshot**
>
> Add a screenshot here showing:
> - header pane,
> - grouped file list,
> - preview pane,
> - bottom cheatsheet pane,
> - at least one commented log and one stale log.
>
> Suggested filename: `docs/assets/dashboard-overview.png`

> **Media placeholder — help modal screenshot**
>
> Add a screenshot here showing the dashboard help modal opened with `?`.
>
> Suggested filename: `docs/assets/dashboard-help-modal.png`

---

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

For a full option-by-option breakdown, see [Configuration reference](./docs/CONFIGURATION.md).

---

## Notes and expectations

- **JavaScript and TypeScript are the default supported target filetypes.**
- **Tree-sitter is strongly recommended** for safer insertion behavior.
- The plugin can fall back to heuristics when Tree-sitter is unavailable.
- The dashboard prefers **live buffer contents** for open files and scans project files for everything else.
- If `rg` is installed, the dashboard uses it to narrow project scans before parsing files.
- `:RocketLogFind` depends on `snacks.nvim`.

---

## Need help?

- Start with [Troubleshooting](./docs/TROUBLESHOOTING.md)
- Open an [issue](https://github.com/evanmcpheron/rocketlog.nvim/issues)
- Read [Contributing](./CONTRIBUTING.md) before opening a PR

---

## License

[MIT](./LICENSE)

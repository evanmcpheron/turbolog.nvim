# Contributing to rocketlog.nvim

Thanks for contributing. Keep changes focused, test what you touched, and do not sneak in behavior changes behind “small cleanup” language. That trick is older than the hills.

## Development setup

Point your Neovim config at your local clone:

```lua
{
  dir = "~/path/to/rocketlog.nvim",
  name = "rocketlog.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "folke/snacks.nvim",
  },
  config = function()
    require("rocketlog").setup()
  end,
}
```

Restart Neovim and run `:Lazy sync` if needed.

---

## Repository docs you should care about

- [README.md](./README.md)
- [docs/README.md](./docs/README.md)
- [docs/GETTING_STARTED.md](./docs/GETTING_STARTED.md)
- [docs/USAGE.md](./docs/USAGE.md)
- [docs/DASHBOARD.md](./docs/DASHBOARD.md)
- [docs/CONFIGURATION.md](./docs/CONFIGURATION.md)
- [docs/TROUBLESHOOTING.md](./docs/TROUBLESHOOTING.md)
- [docs/assets/README.md](./docs/assets/README.md)

If you change user-facing behavior, update the relevant docs in the same PR.

---

## Running tests

### Preferred command

```bash
./scripts/test.sh
```

### What it does

This runs the plugin test suite in headless Neovim using the repository’s minimal test init.

### Manual notes

- `plenary.nvim` must be installed in your normal Neovim data directory
- see `tests/minimal_init.lua` for the isolated test setup

---

## Manual testing checklist

Open a real JS/TS file and verify the following:

### Insertion

- `<leader>rl` + motion inserts `console.log`
- `<leader>re` + motion inserts `console.error`
- `<leader>rw` + motion inserts `console.warn`
- `<leader>ri` + motion inserts `console.info`

### Word-under-cursor

- `<leader>rL`
- `<leader>rE`
- `<leader>rW`
- `<leader>rI`

### Deletion helpers

- `<leader>rd` deletes the next RocketLog below cursor
- `<leader>rD` deletes the nearest RocketLog above cursor
- `<leader>ra` clears all RocketLogs in the buffer

### Dashboard

- `<leader>rr` opens and closes cleanly
- `<CR>` opens the selected entry and closes the dashboard
- `v` opens the selected entry in a vertical split
- `c` toggles the selected log
- `C` toggles all logs in the selected file
- `d` and `D` delete entries as expected
- `/` opens the live filter
- `x` clears the filter
- `t` switches scope
- `?` opens the help modal
- `q` and `<Esc>` close the dashboard or help modal appropriately
- folds work with `<Tab>`, `za`, `zo`, `zc`, `zR`, `zM`

### Refresh

- with `refresh_on_save = true`, labels update on save
- with `refresh_on_insert = true`, labels update after insertion

### Guardrails

Verify RocketLog refuses unsafe insertions, including:

- implicit arrow returns
- selections in function headers or params

---

## Coding guidelines

### Lua style

- prefer descriptive names over clever names
- keep functions focused and boring
- avoid hidden global state unless Neovim requires it

### Comments

- comment intent and edge cases
- do not comment obvious syntax
- if behavior looks weird, explain why it exists

### Formatting

Run `stylua` before opening a PR.

### Optional dependencies

Do not require optional integrations at module load time unless they are actually mandatory.

Use `pcall(require, ...)` where appropriate.

---

## Documentation guidelines

When docs change, aim for:

- accurate keymaps,
- accurate command names,
- examples that match real plugin behavior,
- clear placeholders for missing media instead of pretending screenshots exist.

If you add a new workflow or UI behavior, update:

1. `README.md`
2. the relevant file under `docs/`
3. `docs/assets/README.md` if new screenshots or GIFs are needed

If you change dashboard controls, check the docs for the easy-to-miss stuff too:

- footer cheatsheet text,
- help modal references,
- filter keys,
- file-wide actions like `C` and `D`.

---

## Submitting issues

Include:

- Neovim version (`nvim --version`)
- OS
- exact repro steps
- expected behavior
- actual behavior
- RocketLog config
- whether Tree-sitter is installed
- whether `snacks.nvim` is installed
- full error text and stack trace if applicable

Open issues here:
[github.com/evanmcpheron/rocketlog.nvim/issues](https://github.com/evanmcpheron/rocketlog.nvim/issues)

---

## PR expectations

### Before opening a PR

- keep the PR focused
- update docs for user-facing changes
- add or update tests when behavior changes
- avoid mixing refactors with logic changes unless there is a good reason

### Especially important for insertion logic

If you touch insertion behavior, verify it still works with:

- multiline chains
- object literals
- nested expressions
- unsafe contexts that should still be blocked

### Not wanted without discussion first

- large rewrites
- new required dependencies
- broad scope changes unrelated to current plugin goals
- formatting-only PRs across the whole repo

# Contributing to rocketlog.nvim

Thanks for helping improve rocketlog.nvim. This doc is intentionally short: do the basics, keep changes focused, and avoid surprise behavior changes.

## Local install (for development)

Point your Neovim config at your local clone:

````lua
{
  dir = "~/path/to/rocketlog.nvim",
  name = "rocketlog.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  config = function()
    require("rocketlog").setup()
  end,
}```

Restart neovim and run `:Lazy sync` if needed.

---

## How to run / test

This plugin is easiest to test by using it in a real JS/TS file and verifying insertion and deletion behavior.

### Manual test checklist
Create a JS/TS file and validate:

- Operator insertions:
  - `<leader>rl` + motion inserts console.log
  - `<leader>re` + motion inserts console.error
  - `<leader>rw` + motion inserts console.warn
  - `<leader>ri` + motion inserts console.info

- Word-under-cursor insertions:
  - `<leader>rL,` `<leader>rE,` `<leader>rW,` `<leader>rI`

- Deletion helpers:
  - `<leader>rd` deletes next RocketLog below cursor
  - `<leader>rD` deletes nearest RocketLog above cursor
  - `<leader>ra` clears all RocketLogs in the buffer

- Refresh behavior:
  - If `refresh_on_save` = true, line numbers update on save
  - If `refresh_on_insert` = true, line numbers update after inserting a log

Guardrails:
Verify RocketLog refuses to insert where it would break syntax (example: implicit arrow returns)

## Coding style

Keep diffs boring.

### Lua style

- Use `local` unless you truly need `_G`.
- Prefer descriptive names over clever names.
- Keep functions small and single-purpose.

### Comments

- Comment intent and edge cases, not obvious Lua syntax.
- If behavior is non-obvious, add a short comment explaining why.

### Formatting

- Run `stylua`

### Compatibility

- Avoid requiring optional dependencies at module load time.
- Use `pcall(require, ...)` for optional integrations.

## Submitting issues

Open an issue with:

- Neovim version (`nvim --version`)
- OS
- Minimal repro steps (exact file contents if possible)
- Expected vs actual behavior
- Whether Tree-sitter is installed/enabled
- Your RocketLog config (especially `prefer_treesitter`, `fallback_to_heuristics`, refresh flags, and keymaps)
- If it’s a crash, include the full error and stack trace

## Submitting PRs

### Before you open a PR

- Keep PRs focused: one behavior change or one fix per PR.
- Update docs if you change user-facing behavior or config.
- Prefer adding a small repro snippet in the PR description.

### PR expectations

- To create a PR visit [here](https://github.com/evanmcpheron/rocketlog.nvim/compare).
- No breaking changes without discussion in an issue first.
- No stylistic refactors mixed with logic changes.
- If you touch insertion logic:
  - Verify it works with multiline chains, objects, and nested expressions.
  - Verify it does not break implicit returns and other unsafe contexts.

## What kinds of PRs are wanted

### Wanted

- Bug fixes in insertion/deletion/refresh behavior
- Better guardrails that prevent broken code
- Performance improvements that keep behavior identical
- Documentation improvements that reduce confusion

### Not wanted (unless discussed first)

- Large rewrites or major architecture changes
- Adding new required dependencies
- Expanding scope beyond JS/TS console logging
- Formatting-only PRs across the whole repo:> [!WARNING]

````

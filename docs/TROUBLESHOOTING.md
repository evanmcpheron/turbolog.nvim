# Troubleshooting

This page covers the most common issues and warnings you may run into with `rocketlog.nvim`.

## I get `unsupported filetype`

### Why it happens

The current buffer filetype is not enabled in `allowed_filetypes`.

### Fix

Check your filetype:

```vim
:set filetype?
```

Then update config if needed:

```lua
require("rocketlog").setup({
  allowed_filetypes = {
    javascript = true,
    javascriptreact = true,
    typescript = true,
    typescriptreact = true,
  },
})
```

If you intentionally want to allow everything:

```lua
require("rocketlog").setup({
  allowed_filetypes = nil,
})
```

---

## RocketLog says it cannot insert inside an implicit arrow return

### Why it happens

This is a deliberate safety guard. RocketLog is trying not to break your code.

### Example that can fail

```ts
const getUser = () => api.currentUser();
```

### Fix

Convert the arrow to a block body:

```ts
const getUser = () => {
  return api.currentUser();
};
```

---

## RocketLog says the selection is in a function header or params

### Why it happens

You selected text from the signature area, not the executable body.

### Fix

Move the cursor or selection into the body and try again.

---

## Labels are not refreshing on save

### Check these things

1. `refresh_on_save = true`
2. The buffer is a normal file buffer, not a special buffer
3. The filetype is supported
4. Setup actually ran

### Minimal known-good setup

```lua
require("rocketlog").setup({
  refresh_on_save = true,
})
```

---

## `:RocketLogFind` warns that `snacks.nvim` is not available

### Why it happens

The picker depends on `snacks.nvim`.

### Fix

Install `folke/snacks.nvim`, or ignore the picker feature if you do not need it.

The rest of the plugin still works.

---

## The dashboard is missing project logs

### Check these things

- the files are inside the current working directory,
- they are not in excluded directories,
- they match the current allowed filetypes,
- `max_files` is not too low.

### Performance note

If `rg` is installed, the dashboard can narrow project scans more efficiently.

---

## The dashboard shows stale entries

### What that means

A log’s embedded filename or line number no longer matches its current source location.

### Fix

Use:

- `r` to refresh the selected file in the dashboard
- save the file if `refresh_on_save` is enabled
- rescan with `R` if needed

---

## I forgot the dashboard keybindings

### Fast answer

Open the dashboard and press:

```text
?
```

That opens the full help modal.

You can close it with:

```text
q
```

or

```text
<Esc>
```

The footer pane also keeps the most common keys visible at all times.

---

## Keymaps are not appearing

### Check these things

- `enabled` is not `false`
- you did not disable the key in `keymaps`
- setup actually ran
- `vim.g.rocketlog_disable_auto_setup` is not interfering with your config unintentionally

### Example

```lua
vim.g.rocketlog_disable_auto_setup = true
require("rocketlog").setup()
```

If you set the global and forget to call setup manually, you basically unplugged the toaster and then blamed breakfast.

---

## I changed config but behavior did not update

RocketLog registers commands and keymaps during setup.

If you change config, reload Neovim or re-run your config so setup runs again cleanly.

---

## A log did not delete exactly how I expected

RocketLog prefers Tree-sitter for statement-aware deletion. Without Tree-sitter, it falls back to simpler logic.

### Fixes

- install and enable Tree-sitter for your filetype
- make sure the buffer parses cleanly
- retry deletion

---

## I want to file a bug

Please include:

- Neovim version
- OS
- plugin manager
- RocketLog config
- exact file contents or a minimal repro
- whether Tree-sitter is installed
- whether `snacks.nvim` is installed
- actual behavior vs expected behavior

For contribution details, see [Contributing](../CONTRIBUTING.md).

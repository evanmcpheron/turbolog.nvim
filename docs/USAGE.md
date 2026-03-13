# Usage guide

This guide covers the day-to-day workflow for `rocketlog.nvim`.

## Core idea

RocketLog gives you two main insertion styles:

1. **Word under cursor** for speed
2. **Operator-pending motions** for precision

Then it gives you cleanup and review tools so your codebase does not turn into a landfill of forgotten `console.log`s.

---

## Insert logs

### Word under cursor

Use these when your cursor is on a single token you want to inspect.

| Keymap | Output |
|---|---|
| `<leader>rL` | `console.log(...)` |
| `<leader>rE` | `console.error(...)` |
| `<leader>rW` | `console.warn(...)` |
| `<leader>rI` | `console.info(...)` |

### Operator-pending motions

Use these when you want to log a motion or text object.

| Keymap | Output |
|---|---|
| `<leader>rl` | `console.log(...)` |
| `<leader>re` | `console.error(...)` |
| `<leader>rw` | `console.warn(...)` |
| `<leader>ri` | `console.info(...)` |

After triggering one of those mappings, provide a motion or text object.

### Common examples

| Input | Meaning |
|---|---|
| `<leader>rliw` | Log the inner word |
| `<leader>rla(` | Log around parentheses |
| `<leader>rla{` | Log around braces |
| `<leader>rli[` | Log inside brackets |

Exact behavior depends on what text object or motion you use. RocketLog just uses the selected text and inserts a structured log after the resolved statement.

---

## Log output format

Single-line selections become a single console statement.

```ts
console.log(`🚀[ROCKETLOG] ~ file.ts:12 ~ account:`, account);
```

Multi-line selections become a multi-line console call that preserves the shape of the selected expression.

That makes larger objects and nested expressions much easier to read than one giant spaghetti string.

---

## Supported log types

RocketLog supports these console methods directly:

- `log`
- `warn`
- `error`
- `info`

---

## Refresh behavior

### Refresh on insert

If `refresh_on_insert = true`, RocketLog refreshes labels after inserting a new log.

### Refresh on save

If `refresh_on_save = true`, RocketLog refreshes labels before writing the buffer.

That means file and line references stay accurate as code moves around.

---

## Deleting logs

### Delete next log below cursor

```text
<leader>rd
```

### Delete nearest log above cursor

```text
<leader>rD
```

### Delete all logs in current buffer

```text
<leader>ra
```

RocketLog tries to delete the full statement, not just a random line fragment. When Tree-sitter is unavailable, it falls back to a more limited line-based strategy.

---

## Picker

### Command

```vim
:RocketLogFind
```

### Keymap

```text
<leader>rf
```

The picker uses `snacks.nvim`. If `snacks.nvim` is missing, RocketLog will warn instead of exploding dramatically.

---

## Safety guardrails

RocketLog avoids unsafe insertions where it is likely to break syntax.

### Warnings you may see

| Warning | What it means |
|---|---|
| `unsupported filetype` | The current buffer filetype is not enabled |
| `cannot insert inside an implicit arrow return` | Convert the arrow function to a block body first |
| `selection is in a function header/params` | Move the selection into the function body |

These warnings are good. Broken code is bad.

---

## Label management

RocketLog embeds the filename and line number into each inserted log:

```ts
🚀[ROCKETLOG] ~ file.ts:12 ~ ...
```

As code shifts, the plugin can refresh those labels automatically.

The dashboard also marks **stale** entries so you can spot logs that no longer match their current source location.

---

## A practical workflow

### During implementation

- use `<leader>rL` for quick probes,
- use motion logs for larger expressions,
- leave `refresh_on_save` enabled.

### During cleanup

- open dashboard with `<leader>rr`,
- filter down to the file or keyword,
- toggle logs off with `c`,
- clear stale filters with `x`,
- open help with `?` if you blank on a key,
- delete the ones you are done with.

### Before merging

- run the dashboard,
- rescan with `R`,
- make sure no old instrumentation is hanging around where it should not be.

---

## Related docs

- [Getting started](./GETTING_STARTED.md)
- [Dashboard guide](./DASHBOARD.md)
- [Configuration reference](./CONFIGURATION.md)

> **Media placeholder — motion logging GIF**
>
> Add a GIF showing:
> - `<leader>rliw`,
> - `<leader>rla{`,
> - the resulting inserted logs.
>
> Suggested filename: `docs/assets/motion-logging.gif`

> **Media placeholder — stale label screenshot**
>
> Add a screenshot showing at least one stale dashboard entry with the stale marker visible.
>
> Suggested filename: `docs/assets/stale-entry.png`

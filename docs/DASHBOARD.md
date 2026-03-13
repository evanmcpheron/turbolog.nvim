# Dashboard guide

The RocketLog dashboard is the management UI for existing logs.

It is built for the “okay, now show me all the instrumentation I left lying around” phase of development.

## Open the dashboard

### Keymap

```text
<leader>rr
```

### Command

```vim
:RocketLogDashboard
```

---

## What the dashboard shows

The dashboard opens as a floating UI with multiple panes:

- **Header pane** with scope and summary information
- **List pane** with file groups and log entries
- **Help pane** with the always-visible quick cheatsheet
- **Preview pane** showing surrounding source lines
- **Help modal** on `?` for the full keybinding reference

> **Media placeholder — dashboard anatomy screenshot**
>
> Add a screenshot with callouts or annotations for:
> - header,
> - list,
> - help,
> - preview,
> - folded file group,
> - commented log marker,
> - stale log marker.
>
> Suggested filename: `docs/assets/dashboard-anatomy.png`

---

## List semantics

Logs are grouped by file.

Within each file group, entries include useful metadata such as:

- line numbers,
- log type,
- summary label,
- whether the log is commented,
- whether the embedded label looks stale.

---

## Dashboard keybindings

| Key | Action |
|---|---|
| `<CR>` / `o` | Open selected log in the current window and close the dashboard |
| `v` | Open selected log in a vertical split and close the dashboard |
| `c` | Toggle comment state for the selected log |
| `C` | Toggle comment state for all logs in the selected file |
| `d` | Delete selected log |
| `D` | Delete all logs in selected file |
| `r` | Refresh labels in the selected file |
| `R` | Rescan dashboard contents |
| `/` | Open the live filter prompt |
| `x` | Clear the current filter |
| `<Tab>` / `za` | Toggle selected file fold |
| `zo` | Open selected file fold |
| `zc` | Close selected file fold |
| `zR` | Expand all file groups |
| `zM` | Collapse all file groups |
| `t` | Toggle project scope / current-file scope |
| `?` | Open the help modal |
| `q` / `<Esc>` | Close the dashboard, or close the help modal if it is open |

---

## Scope modes

### Project scope

Shows RocketLogs across the project.

### Current-file scope

Shows RocketLogs only for the current file.

Toggle with:

```text
t
```

This is useful when you want a focused cleanup pass without the whole repo yelling at you.

---

## Filtering

Press:

```text
/
```

A small floating prompt opens. As you type, the list updates live.

Press:

- `<CR>` to accept and return to the list
- `<Esc>` to close the prompt
- `x` from the dashboard list to clear the filter entirely

---

## Folding

File groups can be folded to reduce noise.

| Key | Action |
|---|---|
| `<Tab>` / `za` | Toggle selected group |
| `zo` | Open selected group |
| `zc` | Close selected group |
| `zR` | Expand all groups |
| `zM` | Collapse all groups |

---

## Toggling comments

### Toggle one log

```text
c
```

### Toggle all logs in selected file

```text
C
```

File-wide toggle follows this rule:

- if **any** log in the file is active, `C` comments them all out
- if **all** logs are already commented, `C` uncomments them all

This is handy when you want to temporarily quiet a file without deleting the instrumentation.

> **Media placeholder — comment toggle GIF**
>
> Add a GIF showing:
> - selecting a log,
> - pressing `c`,
> - pressing `c` again,
> - then pressing `C` on a file group.
>
> Suggested filename: `docs/assets/dashboard-comment-toggle.gif`

---

## Deleting logs

### Delete one log

```text
d
```

### Delete all logs in selected file

```text
D
```

File-wide deletion asks for confirmation before removing everything in the file.

---

## Refreshing and rescanning

### Refresh selected file labels

```text
r
```

This updates embedded file/line labels for the selected file.

### Rescan dashboard data

```text
R
```

Use this after larger code changes or when you want the dashboard to re-read project state.

---

## Opening source

### Open in current window

```text
<CR>
```

or

```text
o
```

### Open in vertical split

```text
v
```

When you open an entry, the dashboard closes and moves the cursor to the log location.

---

## Help modal

Press:

```text
?
```

The help modal opens as a centered floating window on top of the dashboard and groups commands by category:

- open,
- comment and delete,
- refresh and scope,
- filter,
- folds,
- close.

Close it with:

```text
q
```

or

```text
<Esc>
```

When it closes, focus returns to the dashboard list.

> **Media placeholder — help modal screenshot**
>
> Add a screenshot showing the help modal open over the dashboard.
>
> Suggested filename: `docs/assets/dashboard-help-modal.png`

---

## Reading the preview pane

The preview pane shows:

- the file path,
- the line range,
- the log type,
- whether the log is commented,
- whether the entry looks stale,
- nearby source lines around the log.

This gives you enough context to decide whether to jump, toggle, refresh, or delete.

---

## Recommended dashboard workflows

### Daily cleanup

1. Open dashboard
2. Filter with `/`
3. Toggle temporary logs off with `c`
4. Delete dead logs with `d`

### Pre-PR sweep

1. Open dashboard
2. Switch to project scope
3. Expand all groups with `zR`
4. Look for stale or leftover logs
5. Delete or refresh as needed

### File-focused debugging

1. Open dashboard
2. Press `t` to switch to current-file scope
3. Toggle groups and work through logs one file at a time

---

## Related docs

- [Usage guide](./USAGE.md)
- [Troubleshooting](./TROUBLESHOOTING.md)

# Getting started

This guide gets you from zero to useful in a few minutes.

## What RocketLog is good at

RocketLog is built for the boring-but-important debug work you do all day:

- inspect a variable fast,
- log a selected expression,
- keep labels consistent,
- clean up logs later without grep gymnastics.

It is not trying to be a full debugger. It is trying to make instrumentation dead simple.

---

## Prerequisites

### Required

- Neovim
- JavaScript or TypeScript files

### Strongly recommended

- [`nvim-treesitter`](https://github.com/nvim-treesitter/nvim-treesitter) for safer insertion targets

### Optional

- [`folke/snacks.nvim`](https://github.com/folke/snacks.nvim) for `:RocketLogFind`
- `rg` for faster dashboard project scans

---

## Install with lazy.nvim

### Recommended install

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

### Minimal install

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

---

## First five minutes

### 1. Open a JS or TS file

Example:

```ts
const fullName = user.profile.name;
const isAdmin = user.roles.includes("admin");
```

### 2. Log the word under the cursor

Put your cursor on `fullName` and press:

```text
<leader>rL
```

RocketLog inserts:

```ts
const fullName = user.profile.name;
console.log(`🚀[ROCKETLOG] ~ user.ts:2 ~ fullName:`, fullName);
const isAdmin = user.roles.includes("admin");
```

### 3. Log a motion or text object

Put your cursor inside an expression and press:

```text
<leader>rliw
```

That means:

- `<leader>rl` → start a `console.log` operator
- `iw` → apply it to the inner word

You can use many normal Vim motions and text objects after `<leader>rl`.

### 4. Open the dashboard

```text
<leader>rr
```

From there you can:

- preview logs,
- filter them,
- toggle them on and off,
- delete them,
- jump straight to the source.

### 5. Use help when you forget keys

Inside the dashboard:

- glance at the footer cheatsheet for the most common actions,
- press `?` for the full help modal,
- press `q` or `<Esc>` to close the modal.

### 6. Save the file

If `refresh_on_save = true`, RocketLog updates embedded file/line labels automatically before write.

---

## Recommended first workflow

| Task | Fastest way |
|---|---|
| Log one variable | `<leader>rL` |
| Log a selected expression via motion | `<leader>rl` + motion |
| Add a warning log | `<leader>rW` or `<leader>rw` + motion |
| Open the dashboard | `<leader>rr` |
| Open dashboard help | `?` |
| Delete the next log below cursor | `<leader>rd` |
| Clear all logs in the file | `<leader>ra` |

---

## Example workflows

### Quick probe

1. Cursor on variable
2. Press `<leader>rL`
3. Re-run code
4. Delete with `<leader>rd` or clean up in the dashboard

### Inspect something larger

1. Move cursor into the target expression
2. Press `<leader>rl` plus a motion or text object
3. Review output
4. Open dashboard and toggle the log off with `c` if you want to keep it around temporarily

### Review all instrumentation in a project

1. Press `<leader>rr`
2. Filter with `/`
3. Open matching entries with `<CR>`
4. Press `?` any time you want the full key reference

---

## What can block insertion

RocketLog intentionally refuses some unsafe insertion cases.

### Implicit arrow return

Example:

```ts
const getName = () => user.profile.name;
```

RocketLog may warn that it cannot insert safely inside an implicit arrow return. The fix is simple:

```ts
const getName = () => {
  return user.profile.name;
};
```

### Function header or params

If the selected range is in a function signature instead of the body, RocketLog will warn instead of inserting garbage into your code. Very considerate of it, honestly.

---

## Next steps

- Read [Usage guide](./USAGE.md)
- Read [Dashboard guide](./DASHBOARD.md)
- Read [Configuration reference](./CONFIGURATION.md)

> **Media placeholder — first run screenshot**
>
> Add a screenshot showing a simple TypeScript file with one inserted RocketLog and the cursor positioned on the logged variable.
>
> Suggested filename: `docs/assets/first-log.png`

> **Media placeholder — getting started GIF**
>
> Add a GIF showing:
> - `<leader>rL` on a variable,
> - `<leader>rliw` on another token,
> - `<leader>rr` to open the dashboard,
> - `?` to open the help modal.
>
> Suggested filename: `docs/assets/getting-started.gif`

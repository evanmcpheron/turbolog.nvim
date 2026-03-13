# Media guide

This file tracks the screenshots and GIFs that should be added to make the documentation feel complete and trustworthy.

Use the placeholders in `README.md` and `docs/*.md` as insertion points.

## Recommended media checklist

| Suggested file | Type | Where it belongs | What it should show |
|---|---|---|---|
| `hero-overview.gif` | GIF | `README.md` | Open a file, insert a log, save, open dashboard, open help modal |
| `dashboard-overview.png` | Screenshot | `README.md` | Entire dashboard with header, list, footer, preview |
| `dashboard-help-modal.png` | Screenshot | `README.md`, `docs/DASHBOARD.md` | The help modal open over the dashboard |
| `first-log.png` | Screenshot | `docs/GETTING_STARTED.md` | Simple TS file with one inserted RocketLog |
| `getting-started.gif` | GIF | `docs/GETTING_STARTED.md` | First-run workflow from insert to dashboard help |
| `motion-logging.gif` | GIF | `docs/USAGE.md` | Motion-based insertion examples |
| `stale-entry.png` | Screenshot | `docs/USAGE.md` | Dashboard entry marked stale |
| `dashboard-anatomy.png` | Screenshot | `docs/DASHBOARD.md` | Annotated or clearly framed dashboard panes |
| `dashboard-comment-toggle.gif` | GIF | `docs/DASHBOARD.md` | Toggle one log with `c`, then whole file with `C` |

---

## Capture tips

### General

- use a clean colorscheme with strong contrast
- keep the font readable
- crop tightly around the relevant UI
- avoid giant empty margins
- hide unrelated plugins if they clutter the shot

### GIFs

- keep them short, around 6–12 seconds
- do one workflow per GIF
- avoid mouse movement if the plugin is keyboard-first
- make sure key presses are clear from the resulting UI changes

### Screenshots

- prefer real plugin output over mockups
- include enough surrounding code to give context
- for dashboard shots, include at least:
  - one file group,
  - one selected log,
  - preview pane content,
  - footer cheatsheet content.

---

## Suggested order to capture

1. `hero-overview.gif`
2. `dashboard-overview.png`
3. `dashboard-help-modal.png`
4. `getting-started.gif`
5. `dashboard-comment-toggle.gif`
6. everything else

That order gives the README enough credibility fast, which is usually what matters most when someone is deciding whether to install the plugin.

---

## After adding media

Replace the visible placeholder callouts in:

- `README.md`
- `docs/GETTING_STARTED.md`
- `docs/USAGE.md`
- `docs/DASHBOARD.md`

Use relative paths like:

```md
![RocketLog dashboard overview](./docs/assets/dashboard-overview.png)
```

or from inside docs:

```md
![RocketLog getting started](./assets/getting-started.gif)
```

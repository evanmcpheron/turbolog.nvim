#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

NVIM_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nvim"
PLENARY_PATH="$NVIM_DATA_DIR/lazy/plenary.nvim"

if [ ! -f "$REPO_ROOT/tests/minimal_init.lua" ]; then
  echo "Missing: $REPO_ROOT/tests/minimal_init.lua"
  exit 1
fi

if [ ! -d "$PLENARY_PATH" ]; then
  echo "Plenary not found at: $PLENARY_PATH"
  echo "Install it in your normal Neovim config with Lazy, then run :Lazy sync"
  exit 1
fi

cd "$REPO_ROOT"

nvim --headless -u "$REPO_ROOT/tests/minimal_init.lua" \
  -c "PlenaryBustedDirectory $REPO_ROOT/tests { minimal_init = '$REPO_ROOT/tests/minimal_init.lua' }" \
  -c "qa"

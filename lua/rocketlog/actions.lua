local M = {}

local build = require("rocketlog.build")
local guards = require("rocketlog.guards")
local insert = require("rocketlog.insert")
local selection = require("rocketlog.selection")

-- Global anchor is shared with operatorfunc flow in `init.lua`.
_G.__rocket_log_anchor_line = _G.__rocket_log_anchor_line

---Refresh RocketLog labels after insertion when the feature is enabled.
---This keeps file names and line numbers in generated logs synchronized.
---@return nil
local function refresh_after_insert_if_enabled()
  local ok_rocketlog, rocketlog = pcall(require, "rocketlog")
  if not ok_rocketlog or not rocketlog or not rocketlog.config then
    return
  end

  if rocketlog.config.enabled == false or rocketlog.config.refresh_on_insert == false then
    return
  end

  local ok_refresh, refresh = pcall(require, "rocketlog.refresh")
  if not ok_refresh then
    return
  end

  refresh.refresh_buffer()
end

---Display a user-facing warning for insertion contexts that are intentionally blocked.
---@param reason string
---@return nil
local function notify_insert_scope_error(reason)
  if reason == "implicit_arrow_body" then
    vim.notify(
      "RocketLog: cannot insert inside an implicit arrow return. Convert it to a block body first.",
      vim.log.levels.WARN
    )
    return
  end

  if reason == "selection_in_function_header" then
    vim.notify(
      "RocketLog: selection is in a function header/params. Move the cursor into the function body.",
      vim.log.levels.WARN
    )
  end
end

---Operator entrypoint used by `g@` motions/textobjects.
---Reads the operator selection, builds the log statement, and inserts it at a safe location.
---@param optype string
---@param log_type string|nil
---@return nil
function M.operator(optype, log_type)
  if not guards.is_supported_filetype() then
    vim.notify("RocketLog: unsupported filetype '" .. vim.bo.filetype .. "'", vim.log.levels.WARN)
    _G.__rocket_log_anchor_line = nil
    return
  end

  -- Operator selections are stored in `[` and `]` marks by Neovim.
  local selected_expression, selection_start_line, selection_end_line, start_col, end_col, start_row0, end_row0 =
    selection.get_text_from_marks(optype)

  if not selected_expression or selected_expression == "" then
    _G.__rocket_log_anchor_line = nil
    return
  end

  local filename = vim.fn.expand("%:t")
  local normalized_anchor_line = insert.normalize_anchor_line(_G.__rocket_log_anchor_line, selection_start_line)
  local log_line_number = insert.find_log_line_number(normalized_anchor_line)
  local generated_log_lines = build.build_rocket_log_lines(filename, log_line_number, selected_expression, log_type)

  -- Tree-sitter receives the exact 0-based range when available.
  local _, insert_err = insert.insert_after_statement(generated_log_lines, normalized_anchor_line, {
    start_row0 = start_row0,
    start_col0 = start_col or 0,
    end_row0 = end_row0,
    end_col0 = end_col or 0,
    selection_start_line = selection_start_line,
    selection_end_line = selection_end_line,
  })

  if insert_err == "implicit_arrow_body" or insert_err == "selection_in_function_header" then
    notify_insert_scope_error(insert_err)
    _G.__rocket_log_anchor_line = nil
    return
  end

  refresh_after_insert_if_enabled()
  _G.__rocket_log_anchor_line = nil
end

---Insert a log for the word under the cursor (no motion required).
---@param log_type string|nil
---@return nil
function M.log_word_under_cursor(log_type)
  if not guards.is_supported_filetype() then
    vim.notify("RocketLog: unsupported filetype '" .. vim.bo.filetype .. "'", vim.log.levels.WARN)
    return
  end

  local current_word = vim.fn.expand("<cword>")
  local current_line_number = vim.fn.line(".")
  local current_col0 = vim.fn.col(".") - 1
  local filename = vim.fn.expand("%:t")
  local log_line_number = insert.find_log_line_number(current_line_number)
  local method = log_type or "log"

  local log_statement = string.format(
    "console.%s(`🚀 ~ %s:%d ~ %s:`, %s);",
    method,
    filename,
    log_line_number,
    current_word,
    current_word
  )

  local _, insert_err = insert.insert_after_statement(log_statement, current_line_number, {
    start_row0 = current_line_number - 1,
    start_col0 = current_col0,
    end_row0 = current_line_number - 1,
    end_col0 = current_col0,
  })

  if insert_err == "implicit_arrow_body" or insert_err == "selection_in_function_header" then
    notify_insert_scope_error(insert_err)
    return
  end

  refresh_after_insert_if_enabled()
end

return M

local M = {}

---Escape text used inside a JavaScript template literal label.
---This only escapes the label text, not the expression payload.
---@param text string
---@return string
local function escape_template_text(text)
  local escaped = text:gsub("\\", "\\\\")
  escaped = escaped:gsub("`", "\\`")
  escaped = escaped:gsub("%${", "\\${")
  return escaped
end

---Collapse whitespace for a single-line label so the label stays readable.
---@param expr string
---@return string
local function normalize_label_text_single_line(expr)
  return expr:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
end

---Build the console statement line(s) for the selected expression.
---If the expression spans multiple lines, emits a multiline console call that preserves expression formatting.
---@param file string Filename only (not full path)
---@param line_num integer Source line number used in the rocket label
---@param expr string Expression text captured from operator selection
---@param log_type string|nil Optional console method (log, error, warn, info, etc.)
---@return string[]
function M.build_rocket_log_lines(file, line_num, expr, log_type)
  local method = log_type or "log"
  local expression_lines = vim.split(expr, "\n", { plain = true })

  -- Single-line output is the compact/common case.
  if #expression_lines == 1 then
    local label_text = escape_template_text(normalize_label_text_single_line(expr))
    return {
      string.format("console.%s(`🚀 ~ %s:%d ~ %s:`, %s);", method, file, line_num, label_text, expr),
    }
  end

  -- Multiline output keeps the selected expression readable and syntactically intact.
  local output_lines = {
    string.format("console.%s(`🚀 ~ %s:%d ~", method, file, line_num),
  }

  for _, expression_line in ipairs(expression_lines) do
    table.insert(output_lines, escape_template_text(expression_line))
  end

  table.insert(output_lines, "`,")

  for index, expression_line in ipairs(expression_lines) do
    if index == 1 then
      table.insert(output_lines, "  " .. expression_line)
    else
      table.insert(output_lines, expression_line)
    end
  end

  table.insert(output_lines, ");")

  return output_lines
end

return M

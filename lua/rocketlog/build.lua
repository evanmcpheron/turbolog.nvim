local M = {}

local config = require("rocketlog.config")

-- Stable marker used for Telescope search and future cleanup tools.
local ROCKETLOG_MARKER = "🚀[ROCKETLOG]"

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

---Resolve which console method should be used for this insertion.
---The explicit `log_type` argument wins; otherwise the configured default is used.
---@param log_type string|nil
---@return string
local function resolve_console_method(log_type)
	if log_type and log_type ~= "" then
		return log_type
	end

	local configured = config.config and config.config.default_console_method or nil
	if type(configured) == "string" and configured ~= "" then
		return configured
	end

	return "log"
end

---Build the RocketLog label prefix according to the active display settings.
---@param file string
---@param line_num integer
---@param label_text string|nil
---@return string
local function build_label_prefix(file, line_num, label_text)
	local parts = { ROCKETLOG_MARKER }
	local cfg = config.config or {}

	if cfg.show_file_line ~= false then
		table.insert(parts, string.format("%s:%d", file, line_num))
	end

	if cfg.show_variable_name ~= false and label_text and label_text ~= "" then
		table.insert(parts, label_text .. ":")
	end

	return table.concat(parts, " ~ ")
end

---Expose the stable marker for Telescope and refresh logic.
---@return string
function M.get_marker()
	return ROCKETLOG_MARKER
end

---Build the console statement line(s) for the selected expression.
---If the expression spans multiple lines, emits a multiline console call that preserves expression formatting.
---@param file string Filename only (not full path)
---@param line_num integer Source line number used in the rocket label
---@param expr string Expression text captured from operator selection
---@param log_type string|nil Optional console method (log, error, warn, info, etc.)
---@return string[]
function M.build_rocket_log_lines(file, line_num, expr, log_type)
	local method = resolve_console_method(log_type)
	local expression_lines = vim.split(expr, "\n", { plain = true })
	local label_text = normalize_label_text_single_line(expr)
	local label_prefix = escape_template_text(build_label_prefix(file, line_num, label_text))

	-- Single-line output is the compact/common case.
	if #expression_lines == 1 then
		return {
			string.format("console.%s(`%s`, %s);", method, label_prefix, expr),
		}
	end

	-- Multiline output keeps the selected expression readable and syntactically intact.
	local output_lines = {
		string.format("console.%s(`%s`,", method, label_prefix),
	}

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

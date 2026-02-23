local M = {}

local build = require("rocketlog.build")
local guards = require("rocketlog.guards")
local insert = require("rocketlog.insert")
local selection = require("rocketlog.selection")

-- Stores the cursor line where the operator mapping started (before g@ runs).
-- This is used later to decide where to insert the generated log statement.
_G.__rocket_log_anchor_line = _G.__rocket_log_anchor_line

---Operator entrypoint (used by g@ via operatorfunc).
---@param optype string
function M.operator(optype)
	if not guards.is_supported_filetype() then
		vim.notify("RocketLog: unsupported filetype '" .. vim.bo.filetype .. "'", vim.log.levels.WARN)
		_G.__rocket_log_anchor_line = nil
		return
	end

	local selected_expression, selection_start_line, _ = selection.get_text_from_marks(optype)
	if not selected_expression or selected_expression == "" then
		_G.__rocket_log_anchor_line = nil
		return
	end

	local filename = vim.fn.expand("%:t")
	local generated_log_lines = build.build_rocket_log_lines(filename, selection_start_line, selected_expression)
	local normalized_anchor_line = insert.normalize_anchor_line(_G.__rocket_log_anchor_line, selection_start_line)

	insert.insert_after_statement(generated_log_lines, normalized_anchor_line)
	_G.__rocket_log_anchor_line = nil
end

---Insert a rocket log for the word currently under the cursor.
function M.log_word_under_cursor()
	if not guards.is_supported_filetype() then
		vim.notify("RocketLog: unsupported filetype '" .. vim.bo.filetype .. "'", vim.log.levels.WARN)
		return
	end

	local current_word = vim.fn.expand("<cword>")
	local current_line_number = vim.fn.line(".")
	local filename = vim.fn.expand("%:t")

	local log_statement = string.format(
		"console.log(`🚀 ~ %s:%d ~ %s:`, %s);",
		filename,
		current_line_number,
		current_word,
		current_word
	)

	insert.insert_after_statement(log_statement, current_line_number)
end

return M

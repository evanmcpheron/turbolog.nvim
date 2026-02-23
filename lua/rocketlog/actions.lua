local M = {}

local build = require("rocketlog.build")
local guards = require("rocketlog.guards")
local insert = require("rocketlog.insert")
local selection = require("rocketlog.selection")

_G.__rocket_log_anchor_line = _G.__rocket_log_anchor_line

local function refresh_after_insert_if_enabled()
	local ok_rocketlog, rocketlog = pcall(require, "rocketlog")
	if not ok_rocketlog or not rocketlog or not rocketlog.config then
		return
	end

	if rocketlog.config.enabled == false then
		return
	end

	if rocketlog.config.refresh_on_insert == false then
		return
	end

	local ok_refresh, refresh = pcall(require, "rocketlog.refresh")
	if not ok_refresh then
		return
	end

	refresh.refresh_buffer()
end

---@param optype string
---@param log_type string|nil
function M.operator(optype, log_type)
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
	local normalized_anchor_line = insert.normalize_anchor_line(_G.__rocket_log_anchor_line, selection_start_line)
	local log_line_number = insert.find_log_line_number(normalized_anchor_line)

	local generated_log_lines = build.build_rocket_log_lines(filename, log_line_number, selected_expression, log_type)
	insert.insert_after_statement(generated_log_lines, normalized_anchor_line)

	refresh_after_insert_if_enabled()

	_G.__rocket_log_anchor_line = nil
end

--- @param log_type string|nil
function M.log_word_under_cursor(log_type)
	if not guards.is_supported_filetype() then
		vim.notify("RocketLog: unsupported filetype '" .. vim.bo.filetype .. "'", vim.log.levels.WARN)
		return
	end

	local current_word = vim.fn.expand("<cword>")
	local current_line_number = vim.fn.line(".")
	local filename = vim.fn.expand("%:t")
	local log_line_number = insert.find_log_line_number(current_line_number)

	local log_statement = string.format(
		"console.%s(`🚀 ~ %s:%d ~ %s:`, %s);",
		log_type,
		filename,
		log_line_number,
		current_word,
		current_word
	)

	insert.insert_after_statement(log_statement, current_line_number)

	refresh_after_insert_if_enabled()
end

return M

local build = require("rocketlog.build")
local guards = require("rocketlog.guards")
local insert = require("rocketlog.insert")
local selection = require("rocketlog.selection")

local M = {}

_G.__rocket_log_anchor_line = _G.__rocket_log_anchor_line

local INSERT_SCOPE_MESSAGES = {
	implicit_arrow_body = "RocketLog: cannot insert inside an implicit arrow return. Convert it to a block body first.",
	selection_in_function_header = "RocketLog: selection is in a function header/params. Move the cursor into the function body.",
}

---@return boolean
local function current_filetype_supported()
	return guards.is_supported_filetype()
end

---@param filetype string
local function notify_unsupported_filetype(filetype)
	vim.notify("RocketLog: unsupported filetype '" .. filetype .. "'", vim.log.levels.WARN)
end

---@param reason string|nil
---@return boolean
local function handle_insert_scope_error(reason)
	local message = INSERT_SCOPE_MESSAGES[reason]
	if not message then
		return false
	end

	vim.notify(message, vim.log.levels.WARN)
	return true
end

local function refresh_after_insert_if_enabled()
	local ok_rocketlog, rocketlog = pcall(require, "rocketlog")
	if not ok_rocketlog or not rocketlog or not rocketlog.config then
		return
	end

	if rocketlog.config.enabled == false or rocketlog.config.refresh_on_insert == false then
		return
	end

	local ok_refresh, refresh = pcall(require, "rocketlog.refresh")
	if ok_refresh and refresh then
		refresh.refresh_buffer()
	end
end

---@param filename string
---@param line_number integer
---@param expression string
---@param log_type string|nil
---@return string[]
local function build_log_lines(filename, line_number, expression, log_type)
	return build.build_rocket_log_lines(filename, line_number, expression, log_type)
end

---@param generated_lines string[]
---@param anchor_line integer
---@param context table
---@return integer|nil, string|nil
local function insert_generated_log(generated_lines, anchor_line, context)
	return insert.insert_after_statement(generated_lines, anchor_line, context)
end

---@param optype string
---@param log_type string|nil
function M.motions(optype, log_type)
	if not current_filetype_supported() then
		notify_unsupported_filetype(vim.bo.filetype)
		_G.__rocket_log_anchor_line = nil
		return
	end

	local selected_expression, selection_start_line, selection_end_line, start_col, end_col, start_row0, end_row0 =
		selection.get_text_from_marks(optype)

	if not selected_expression or selected_expression == "" then
		_G.__rocket_log_anchor_line = nil
		return
	end

	local normalized_anchor_line = insert.normalize_anchor_line(_G.__rocket_log_anchor_line, selection_start_line)
	local log_line_number = insert.find_log_line_number(normalized_anchor_line)
	local generated_log_lines = build_log_lines(
		vim.fn.expand("%:t"),
		log_line_number,
		selected_expression,
		log_type
	)

	local _, insert_error = insert_generated_log(generated_log_lines, normalized_anchor_line, {
		start_row0 = start_row0,
		start_col0 = start_col or 0,
		end_row0 = end_row0,
		end_col0 = end_col or 0,
		selection_start_line = selection_start_line,
		selection_end_line = selection_end_line,
	})

	if handle_insert_scope_error(insert_error) then
		_G.__rocket_log_anchor_line = nil
		return
	end

	refresh_after_insert_if_enabled()
	_G.__rocket_log_anchor_line = nil
end

---@param log_type string|nil
function M.log_word_under_cursor(log_type)
	if not current_filetype_supported() then
		notify_unsupported_filetype(vim.bo.filetype)
		return
	end

	local current_line = vim.fn.line(".")
	local current_column0 = vim.fn.col(".") - 1
	local generated_log_lines = build_log_lines(
		vim.fn.expand("%:t"),
		insert.find_log_line_number(current_line),
		vim.fn.expand("<cword>"),
		log_type
	)

	local _, insert_error = insert_generated_log(generated_log_lines, current_line, {
		start_row0 = current_line - 1,
		start_col0 = current_column0,
		end_row0 = current_line - 1,
		end_col0 = current_column0,
	})

	if handle_insert_scope_error(insert_error) then
		return
	end

	refresh_after_insert_if_enabled()
end

return M

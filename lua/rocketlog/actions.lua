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

	if rocketlog.config.enabled == false or rocketlog.config.refresh_on_insert == false then
		return
	end

	local ok_refresh, refresh = pcall(require, "rocketlog.refresh")
	if not ok_refresh then
		return
	end

	refresh.refresh_buffer()
end

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

---@param selected_expression string
---@param anchor_line integer
---@param filename string
---@param log_type string|nil
---@param context table
---@return boolean
local function insert_selection_log(selected_expression, anchor_line, filename, log_type, context)
	local log_line_number = insert.find_log_line_number(anchor_line)
	local generated_log_lines =
		build.build_rocket_log_lines(filename, log_line_number, selected_expression, log_type)

	local _, insert_err = insert.insert_after_statement(generated_log_lines, anchor_line, context)

	if insert_err == "implicit_arrow_body" or insert_err == "selection_in_function_header" then
		notify_insert_scope_error(insert_err)
		return false
	end

	refresh_after_insert_if_enabled()
	return true
end

---@param optype string
---@param log_type string|nil
function M.motions(optype, log_type)
	if not guards.is_supported_filetype() then
		vim.notify(
			"RocketLog: unsupported filetype '" .. vim.bo.filetype .. "'",
			vim.log.levels.WARN
		)
		_G.__rocket_log_anchor_line = nil
		return
	end

	local selected_expression, selection_start_line, selection_end_line, start_col, end_col, start_row0, end_row0 =
		selection.get_text_from_marks(optype)

	if not selected_expression or selected_expression == "" then
		_G.__rocket_log_anchor_line = nil
		return
	end

	local filename = vim.fn.expand("%:t")
	local normalized_anchor_line =
		insert.normalize_anchor_line(_G.__rocket_log_anchor_line, selection_start_line)

	insert_selection_log(selected_expression, normalized_anchor_line, filename, log_type, {
		start_row0 = start_row0,
		start_col0 = start_col or 0,
		end_row0 = end_row0,
		end_col0 = end_col or 0,
		selection_start_line = selection_start_line,
		selection_end_line = selection_end_line,
	})

	_G.__rocket_log_anchor_line = nil
end

---@param log_type string|nil
function M.visual_selection(log_type)
	if not guards.is_supported_filetype() then
		vim.notify(
			"RocketLog: unsupported filetype '" .. vim.bo.filetype .. "'",
			vim.log.levels.WARN
		)
		return
	end

	local selected_expression, selection_start_line, selection_end_line, start_col, end_col, start_row0, end_row0 =
		selection.get_visual_selection_text()

	if not selected_expression or selected_expression == "" then
		return
	end

	local filename = vim.fn.expand("%:t")
	local anchor_line = selection_start_line

	insert_selection_log(selected_expression, anchor_line, filename, log_type, {
		start_row0 = start_row0,
		start_col0 = start_col or 0,
		end_row0 = end_row0,
		end_col0 = end_col or 0,
		selection_start_line = selection_start_line,
		selection_end_line = selection_end_line,
	})

	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
end

---@param log_type string|nil
function M.log_word_under_cursor(log_type)
	if not guards.is_supported_filetype() then
		vim.notify(
			"RocketLog: unsupported filetype '" .. vim.bo.filetype .. "'",
			vim.log.levels.WARN
		)
		return
	end

	local current_word = vim.fn.expand("<cword>")
	local current_line_number = vim.fn.line(".")
	local current_col0 = vim.fn.col(".") - 1
	local filename = vim.fn.expand("%:t")

	insert_selection_log(current_word, current_line_number, filename, log_type, {
		start_row0 = current_line_number - 1,
		start_col0 = current_col0,
		end_row0 = current_line_number - 1,
		end_col0 = current_col0,
	})
end

return M

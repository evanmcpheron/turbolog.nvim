local config = require("rocketlog.config")

local M = {
	current = nil,
}

local DASHBOARD_FILETYPES = {
	rocketlogdashboard = true,
	rocketlogfilter = true,
	rocketloghelp = true,
}

local SIDEBAR_FILETYPES = {
	NvimTree = true,
	["neo-tree"] = true,
	nerdtree = true,
	CHADTree = true,
	fern = true,
	dirvish = true,
	oil = true,
	Outline = true,
	undotree = true,
	aerial = true,
	Trouble = true,
	sagaoutline = true,
	["dap-repl"] = true,
	dapui_scopes = true,
	dapui_breakpoints = true,
	dapui_stacks = true,
	dapui_watches = true,
	dapui_console = true,
}

local UI_WINDOW_KEYS = { "filter_win", "help_modal_win", "list_win", "preview_win", "header_win", "help_win", "root_win" }
local UI_BUFFER_KEYS = { "filter_buf", "help_modal_buf", "list_buf", "preview_buf", "header_buf", "help_buf", "root_buf" }

local function get_marked_flag(getter, id)
	local ok, marked = pcall(getter, id, "rocketlog_dashboard")
	return ok and marked or false
end

local function add_unique(items, seen, value, validator)
	if value and validator(value) and not seen[value] then
		seen[value] = true
		table.insert(items, value)
	end
end

local function is_dashboard_buffer(bufnr)
	if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
		return false
	end

	if get_marked_flag(vim.api.nvim_buf_get_var, bufnr) then
		return true
	end

	return DASHBOARD_FILETYPES[vim.bo[bufnr].filetype] == true
end

local function is_dashboard_window(win, root_win)
	if not win or not vim.api.nvim_win_is_valid(win) then
		return false
	end

	if get_marked_flag(vim.api.nvim_win_get_var, win) then
		return true
	end

	if is_dashboard_buffer(vim.api.nvim_win_get_buf(win)) then
		return true
	end

	local ok_config, window_config = pcall(vim.api.nvim_win_get_config, win)
	if ok_config and window_config then
		if root_win and window_config.win == root_win then
			return true
		end
		if root_win and win == root_win then
			return true
		end
	end

	return false
end

---@param source_bufnr integer
---@return table
function M.new(source_bufnr)
	local dashboard_config = config.config.dashboard or {}
	return {
		source_bufnr = source_bufnr,
		source_win = vim.api.nvim_get_current_win(),
		source_path = vim.api.nvim_buf_get_name(source_bufnr),
		cwd = vim.fn.getcwd(),
		scope = "project",
		filter = "",
		groups = {},
		line_map = {},
		selected_path = nil,
		selection = nil,
		collapsed_paths = {},
		ui = {},
		preview_context = dashboard_config.preview_context or 4,
		closing = false,
	}
end

---@param state table
function M.set_current(state)
	M.current = state
end

---@return table|nil
function M.get_current()
	return M.current
end

---@return boolean
function M.is_open()
	local state = M.current
	return state ~= nil and state.ui ~= nil and state.ui.root_win ~= nil and vim.api.nvim_win_is_valid(state.ui.root_win)
end

---@param state table
---@return table|nil
function M.get_selected_item(state)
	if not state.ui.list_win or not vim.api.nvim_win_is_valid(state.ui.list_win) then
		return nil
	end

	local cursor = vim.api.nvim_win_get_cursor(state.ui.list_win)
	return state.line_map[cursor[1]]
end

---@param state table
---@return table|nil
function M.get_selected_entry(state)
	local item = M.get_selected_item(state)
	if not item then
		return nil
	end

	if item.kind == "entry" then
		return item.entry
	end

	if item.kind == "group" and item.group and item.group.entries[1] then
		return item.group.entries[1]
	end

	return nil
end

local function entry_matches_selection(entry, selection)
	if not entry or not selection then
		return false
	end

	if selection.id and entry.id == selection.id then
		return true
	end

	if not selection.path or entry.path ~= selection.path then
		return false
	end

	if selection.lnum and entry.lnum ~= selection.lnum then
		return false
	end

	if selection.end_lnum and entry.end_lnum ~= selection.end_lnum then
		return false
	end

	if selection.label and entry.label ~= selection.label then
		return false
	end

	return selection.lnum ~= nil or selection.end_lnum ~= nil or selection.label ~= nil
end

---@param state table
function M.capture_selection(state)
	local item = M.get_selected_item(state)
	if not item then
		return
	end

	if item.kind == "entry" then
		state.selection = {
			kind = "entry",
			id = item.entry.id,
			path = item.entry.path,
			lnum = item.entry.lnum,
			end_lnum = item.entry.end_lnum,
			label = item.entry.label,
		}
		return
	end

	if item.kind == "group" and item.group then
		state.selection = {
			kind = "group",
			path = item.group.path,
		}
	end
end

---@param state table
---@return integer
function M.find_preferred_cursor_row(state)
	local selection = state.selection
	local first_group_row
	local first_entry_row
	local matching_group_row

	for row = 1, (state.list_line_count or 0) do
		local item = state.line_map[row]
		if item then
			first_group_row = first_group_row or row
			if item.kind == "entry" and not first_entry_row then
				first_entry_row = row
			end
		end
	end

	if selection then
		for row = 1, (state.list_line_count or 0) do
			local item = state.line_map[row]
			if item then
				if selection.kind == "entry" and item.kind == "entry" and entry_matches_selection(item.entry, selection) then
					return row
				end
				if not matching_group_row and selection.path and item.group and item.group.path == selection.path then
					matching_group_row = row
				end
			end
		end

		if matching_group_row then
			return matching_group_row
		end
	end

	return first_entry_row or first_group_row or 1
end

---@param state table
---@param opts table|nil
function M.focus_list(state, opts)
	if state and state.ui and state.ui.list_win and vim.api.nvim_win_is_valid(state.ui.list_win) then
		if opts and opts.normal_mode then
			pcall(vim.cmd, "stopinsert")
		end
		vim.api.nvim_set_current_win(state.ui.list_win)
	end
end

local function is_sidebar_window(win)
	if not vim.api.nvim_win_is_valid(win) then
		return false
	end

	local bufnr = vim.api.nvim_win_get_buf(win)
	if SIDEBAR_FILETYPES[vim.bo[bufnr].filetype or ""] then
		return true
	end

	local ok_config, window_config = pcall(vim.api.nvim_win_get_config, win)
	return ok_config and window_config and window_config.relative and window_config.relative ~= "" or false
end

---@param state table
---@return integer|nil
function M.get_target_win(state)
	if state and state.source_win and vim.api.nvim_win_is_valid(state.source_win) and not is_sidebar_window(state.source_win) then
		return state.source_win
	end

	local skip_wins = {}
	if state and state.ui then
		for _, key in ipairs(UI_WINDOW_KEYS) do
			local win = state.ui[key]
			if win then
				skip_wins[win] = true
			end
		end
	end

	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if vim.api.nvim_win_is_valid(win) and not skip_wins[win] and not is_sidebar_window(win) then
			return win
		end
	end

	if state and state.source_win and vim.api.nvim_win_is_valid(state.source_win) then
		return state.source_win
	end

	return nil
end

---@param state table|nil
---@return integer[]
local function collect_dashboard_windows(state)
	local windows = {}
	local seen = {}

	if state and state.ui then
		for _, key in ipairs(UI_WINDOW_KEYS) do
			add_unique(windows, seen, state.ui[key], vim.api.nvim_win_is_valid)
		end
	end

	local root_win = state and state.ui and state.ui.root_win or nil
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if is_dashboard_window(win, root_win) then
			add_unique(windows, seen, win, vim.api.nvim_win_is_valid)
		end
	end

	return windows
end

---@param state table|nil
---@return integer[]
local function collect_dashboard_buffers(state)
	local buffers = {}
	local seen = {}

	if state and state.ui then
		for _, key in ipairs(UI_BUFFER_KEYS) do
			add_unique(buffers, seen, state.ui[key], vim.api.nvim_buf_is_valid)
		end
	end

	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if is_dashboard_buffer(buf) then
			add_unique(buffers, seen, buf, vim.api.nvim_buf_is_valid)
		end
	end

	return buffers
end

---@param state table|nil
---@param opts table|nil
function M.close(state, opts)
	state = state or M.current
	if not state or state.closing then
		return
	end

	state.closing = true
	local restore_source = opts == nil or opts.restore_source ~= false
	local target_win = restore_source and M.get_target_win(state) or nil

	if M.current == state then
		M.current = nil
	end

	pcall(vim.cmd, "stopinsert")
	if target_win and vim.api.nvim_win_is_valid(target_win) then
		pcall(vim.api.nvim_set_current_win, target_win)
	end

	for _, win in ipairs(collect_dashboard_windows(state)) do
		pcall(vim.api.nvim_win_close, win, true)
	end
	for _, buf in ipairs(collect_dashboard_buffers(state)) do
		pcall(vim.api.nvim_buf_delete, buf, { force = true })
	end
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if is_dashboard_window(win, nil) then
			pcall(vim.api.nvim_win_close, win, true)
		end
	end

	for _, key in ipairs(UI_WINDOW_KEYS) do
		state.ui[key] = nil
	end
	for _, key in ipairs(UI_BUFFER_KEYS) do
		state.ui[key] = nil
	end

	state.closing = false
end

return M

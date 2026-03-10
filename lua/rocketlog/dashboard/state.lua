local config = require("rocketlog.config")

local M = {
	current = nil,
}

local DASHBOARD_FILETYPES = {
	rocketlogdashboard = true,
	rocketlogfilter = true,
}

local function is_dashboard_buffer(bufnr)
	if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
		return false
	end

	local ok_marked, marked = pcall(vim.api.nvim_buf_get_var, bufnr, "rocketlog_dashboard")
	if ok_marked and marked then
		return true
	end

	return DASHBOARD_FILETYPES[vim.bo[bufnr].filetype] == true
end

local function is_dashboard_window(win, root_win)
	if not win or not vim.api.nvim_win_is_valid(win) then
		return false
	end

	local ok_marked, marked = pcall(vim.api.nvim_win_get_var, win, "rocketlog_dashboard")
	if ok_marked and marked then
		return true
	end

	local bufnr = vim.api.nvim_win_get_buf(win)
	if is_dashboard_buffer(bufnr) then
		return true
	end

	local ok_config, config = pcall(vim.api.nvim_win_get_config, win)
	if ok_config and config then
		if root_win and config.win == root_win then
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
	local source_name = vim.api.nvim_buf_get_name(source_bufnr)
	local dashboard_config = config.config.dashboard or {}

	return {
		source_bufnr = source_bufnr,
		source_win = vim.api.nvim_get_current_win(),
		source_path = source_name,
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
	return state ~= nil
		and state.ui ~= nil
		and state.ui.root_win ~= nil
		and vim.api.nvim_win_is_valid(state.ui.root_win)
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
	local first_group_row = nil
	local first_entry_row = nil

	for row = 1, (state.list_line_count or 0) do
		local item = state.line_map[row]
		if item then
			if not first_group_row then
				first_group_row = row
			end
			if item.kind == "entry" and not first_entry_row then
				first_entry_row = row
			end
		end
	end

	if selection then
		for row = 1, (state.list_line_count or 0) do
			local item = state.line_map[row]
			if item then
				if selection.kind == "entry" and item.kind == "entry" and item.entry.id == selection.id then
					return row
				end
				if selection.path and item.group and item.group.path == selection.path then
					return row
				end
			end
		end
	end

	return first_entry_row or first_group_row or 1
end

---@param state table
---@param opts table|nil { normal_mode?: boolean }
function M.focus_list(state, opts)
	if state and state.ui and state.ui.list_win and vim.api.nvim_win_is_valid(state.ui.list_win) then
		if opts and opts.normal_mode then
			pcall(vim.cmd, "stopinsert")
		end
		vim.api.nvim_set_current_win(state.ui.list_win)
	end
end

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

---@param win integer
---@return boolean
local function is_sidebar_window(win)
	if not vim.api.nvim_win_is_valid(win) then
		return false
	end

	local bufnr = vim.api.nvim_win_get_buf(win)
	local ft = vim.bo[bufnr].filetype or ""
	if SIDEBAR_FILETYPES[ft] then
		return true
	end

	local ok, win_config = pcall(vim.api.nvim_win_get_config, win)
	if ok and win_config and win_config.relative and win_config.relative ~= "" then
		return true
	end

	return false
end

---@param state table
---@return integer|nil
function M.get_target_win(state)
	if
		state
		and state.source_win
		and vim.api.nvim_win_is_valid(state.source_win)
		and not is_sidebar_window(state.source_win)
	then
		return state.source_win
	end

	local skip_wins = {}
	if state and state.ui then
		for _, win in ipairs({
			state.ui.root_win,
			state.ui.filter_win,
			state.ui.header_win,
			state.ui.list_win,
			state.ui.help_win,
			state.ui.preview_win,
		}) do
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

	local function add_window(win)
		if win and vim.api.nvim_win_is_valid(win) and not seen[win] then
			seen[win] = true
			table.insert(windows, win)
		end
	end

	if state and state.ui then
		for _, win in ipairs({
			state.ui.filter_win,
			state.ui.list_win,
			state.ui.preview_win,
			state.ui.header_win,
			state.ui.help_win,
			state.ui.root_win,
		}) do
			add_window(win)
		end
	end

	local root_win = state and state.ui and state.ui.root_win or nil
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if is_dashboard_window(win, root_win) then
			add_window(win)
		end
	end

	return windows
end

---@param state table|nil
---@return integer[]
local function collect_dashboard_buffers(state)
	local buffers = {}
	local seen = {}

	local function add_buffer(buf)
		if buf and vim.api.nvim_buf_is_valid(buf) and not seen[buf] then
			seen[buf] = true
			table.insert(buffers, buf)
		end
	end

	if state and state.ui then
		for _, buf in ipairs({
			state.ui.filter_buf,
			state.ui.list_buf,
			state.ui.preview_buf,
			state.ui.header_buf,
			state.ui.help_buf,
			state.ui.root_buf,
		}) do
			add_buffer(buf)
		end
	end

	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if is_dashboard_buffer(buf) then
			add_buffer(buf)
		end
	end

	return buffers
end

---@param state table|nil
---@param opts table|nil { restore_source?: boolean }
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

	state.ui.filter_win = nil
	state.ui.list_win = nil
	state.ui.preview_win = nil
	state.ui.header_win = nil
	state.ui.help_win = nil
	state.ui.root_win = nil
	state.ui.filter_buf = nil
	state.ui.list_buf = nil
	state.ui.preview_buf = nil
	state.ui.header_buf = nil
	state.ui.help_buf = nil
	state.ui.root_buf = nil
	state.closing = false
end

return M

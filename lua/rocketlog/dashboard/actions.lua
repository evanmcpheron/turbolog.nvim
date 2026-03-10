local render = require("rocketlog.dashboard.render")
local scan = require("rocketlog.dashboard.scan")
local state_mod = require("rocketlog.dashboard.state")

local M = {}

local function defer(fn)
	vim.schedule(function()
		pcall(fn)
	end)
end

local function refresh_dashboard(state)
	state_mod.capture_selection(state)
	scan.collect_groups(state)
	render.refresh(state)
end

local function with_target_buffer(entry_or_group)
	local entry = entry_or_group
	if entry_or_group and entry_or_group.entries then
		entry = entry_or_group.entries[1]
	end

	if not entry then
		return nil, nil
	end

	if entry.bufnr and vim.api.nvim_buf_is_valid(entry.bufnr) then
		return entry.bufnr, false
	end

	if not entry.path or entry.path == "[No Name]" or vim.fn.filereadable(entry.path) ~= 1 then
		return nil, nil
	end

	local bufnr = vim.fn.bufadd(entry.path)
	vim.fn.bufload(bufnr)
	return bufnr, true
end

local function delete_entry_range(entry)
	local bufnr = with_target_buffer(entry)
	if not bufnr then
		vim.notify("RocketLog: unable to delete log from an unreadable buffer", vim.log.levels.WARN)
		return false
	end

	vim.api.nvim_buf_set_lines(bufnr, entry.lnum - 1, entry.end_lnum, false, {})
	return true
end

local function current_group(state)
	local item = state_mod.get_selected_item(state)
	if not item then
		return nil
	end
	return item.group or item.entry and { entries = { item.entry }, path = item.entry.path } or nil
end

local function close_filter_prompt(state)
	pcall(vim.cmd, "stopinsert")
	if state.ui.filter_win and vim.api.nvim_win_is_valid(state.ui.filter_win) then
		pcall(vim.api.nvim_win_close, state.ui.filter_win, true)
	end
	if state.ui.filter_buf and vim.api.nvim_buf_is_valid(state.ui.filter_buf) then
		pcall(vim.api.nvim_buf_delete, state.ui.filter_buf, { force = true })
	end
	state.ui.filter_win = nil
	state.ui.filter_buf = nil
	vim.schedule(function()
		if state_mod.is_open() then
			state_mod.focus_list(state, { normal_mode = true })
		end
	end)
end

local function update_live_filter(state)
	if not state.ui.filter_buf or not vim.api.nvim_buf_is_valid(state.ui.filter_buf) then
		return
	end

	local line = vim.api.nvim_buf_get_lines(state.ui.filter_buf, 0, 1, false)[1] or ""
	state.filter = line
	if state_mod.is_open() then
		refresh_dashboard(state)
	end
end

local function open_exact_path(path, command)
	local escaped = vim.fn.fnameescape(path)

	if command == "vsplit" then
		vim.cmd("vertical edit " .. escaped)
	else
		vim.cmd("edit " .. escaped)
	end

	local current_name = vim.api.nvim_buf_get_name(0)
	if current_name ~= path then
		local requested_real = vim.loop.fs_realpath(path)
		local current_real = vim.loop.fs_realpath(current_name)

		if requested_real and current_real and requested_real == current_real then
			vim.cmd("keepalt file " .. escaped)
		end
	end
end

local function open_entry_in_target(entry, command)
	local readable_path = entry.path
		and entry.path ~= ""
		and entry.path ~= "[No Name]"
		and vim.fn.filereadable(entry.path) == 1

	if readable_path then
		open_exact_path(entry.path, command)
		return
	end

	if entry.bufnr and vim.api.nvim_buf_is_valid(entry.bufnr) then
		if command == "vsplit" then
			vim.cmd("vertical sbuffer " .. entry.bufnr)
		else
			vim.cmd("buffer " .. entry.bufnr)
		end
	end
end

function M.open_selected(state, command)
	local entry = state_mod.get_selected_entry(state)
	if not entry then
		return
	end

	local target_win = state_mod.get_target_win(state)
	defer(function()
		pcall(vim.cmd, "stopinsert")
		state_mod.close(state, { restore_source = false })

		if not target_win or not vim.api.nvim_win_is_valid(target_win) then
			target_win = state_mod.get_target_win(state)
		end

		if target_win and vim.api.nvim_win_is_valid(target_win) then
			vim.api.nvim_set_current_win(target_win)
		end
		open_entry_in_target(entry, command)

		vim.api.nvim_win_set_cursor(0, { entry.lnum, 0 })
		vim.cmd("normal! zz")
	end)
end

function M.delete_selected(state)
	local entry = state_mod.get_selected_entry(state)
	if not entry then
		return
	end

	if delete_entry_range(entry) then
		refresh_dashboard(state)
		vim.notify("RocketLog: deleted selected log", vim.log.levels.INFO)
	end
end

function M.delete_selected_file(state)
	local group = current_group(state)
	if not group or not group.entries or #group.entries == 0 then
		return
	end

	local choice = vim.fn.confirm(
		"Delete all RocketLogs in " .. group.entries[1].filename .. "?",
		"&Yes\n&No",
		2
	)
	if choice ~= 1 then
		return
	end

	for index = #group.entries, 1, -1 do
		delete_entry_range(group.entries[index])
	end

	refresh_dashboard(state)
	vim.notify("RocketLog: deleted file entries", vim.log.levels.INFO)
end

function M.refresh_selected(state)
	local group = current_group(state)
	local bufnr = with_target_buffer(group)
	if not bufnr then
		vim.notify("RocketLog: no readable buffer selected", vim.log.levels.WARN)
		return
	end

	local refresh = require("rocketlog.refresh")
	vim.api.nvim_buf_call(bufnr, function()
		refresh.refresh_buffer()
	end)

	refresh_dashboard(state)
	vim.notify("RocketLog: refreshed selected file", vim.log.levels.INFO)
end

function M.rescan(state)
	refresh_dashboard(state)
end

function M.toggle_scope(state)
	state.scope = state.scope == "project" and "current_file" or "project"
	refresh_dashboard(state)
end

function M.clear_filter(state)
	state.filter = ""
	refresh_dashboard(state)
end

function M.open_live_filter(state)
	if state.ui.filter_win and vim.api.nvim_win_is_valid(state.ui.filter_win) then
		vim.api.nvim_set_current_win(state.ui.filter_win)
		pcall(vim.api.nvim_win_set_cursor, state.ui.filter_win, { 1, #state.filter })
		vim.cmd("startinsert!")
		return
	end

	local filter_buf = vim.api.nvim_create_buf(false, true)
	vim.bo[filter_buf].buftype = "nofile"
	vim.bo[filter_buf].bufhidden = "wipe"
	vim.bo[filter_buf].swapfile = false
	vim.bo[filter_buf].modifiable = true
	vim.bo[filter_buf].filetype = "rocketlogfilter"
	pcall(vim.api.nvim_buf_set_var, filter_buf, "rocketlog_dashboard", true)
	pcall(vim.api.nvim_buf_set_var, filter_buf, "rocketlog_dashboard_role", "filter")
	vim.api.nvim_buf_set_lines(filter_buf, 0, -1, false, { state.filter or "" })

	local width = state.ui.filter_width or 48
	local row = math.max(1, math.floor((state.ui.height - 3) / 2))
	local col = math.max(1, math.floor((state.ui.width - width) / 2) - 1)

	local filter_win = vim.api.nvim_open_win(filter_buf, true, {
		relative = "win",
		win = state.ui.root_win,
		row = row,
		col = col,
		width = width,
		height = 1,
		style = "minimal",
		border = "rounded",
		title = " Filter ",
		title_pos = "left",
		zindex = 70,
	})
	pcall(vim.api.nvim_win_set_var, filter_win, "rocketlog_dashboard", true)
	pcall(vim.api.nvim_win_set_var, filter_win, "rocketlog_dashboard_role", "filter")

	vim.wo[filter_win].wrap = false
	vim.wo[filter_win].winhighlight = table.concat({
		"Normal:NormalFloat",
		"FloatBorder:RocketLogDashboardPaneBorder",
		"FloatTitle:RocketLogDashboardPaneTitle",
	}, ",")

	state.ui.filter_buf = filter_buf
	state.ui.filter_win = filter_win

	local augroup = vim.api.nvim_create_augroup("RocketLogDashboardFilter", { clear = false })
	vim.api.nvim_create_autocmd({ "TextChangedI", "TextChanged" }, {
		group = augroup,
		buffer = filter_buf,
		callback = function()
			if state_mod.is_open() then
				update_live_filter(state)
			end
		end,
	})

	vim.api.nvim_create_autocmd("BufLeave", {
		group = augroup,
		buffer = filter_buf,
		callback = function()
			if state.ui.filter_buf == filter_buf then
				close_filter_prompt(state)
			end
		end,
	})

	vim.keymap.set({ "i", "n" }, "<Esc>", function()
		close_filter_prompt(state)
	end, { buffer = filter_buf, silent = true, nowait = true, desc = "Close live filter" })
	vim.keymap.set({ "i", "n" }, "<CR>", function()
		close_filter_prompt(state)
	end, { buffer = filter_buf, silent = true, nowait = true, desc = "Apply live filter" })
	vim.keymap.set({ "i", "n" }, "<C-c>", function()
		close_filter_prompt(state)
	end, { buffer = filter_buf, silent = true, nowait = true, desc = "Close live filter" })

	pcall(vim.api.nvim_win_set_cursor, filter_win, { 1, #(state.filter or "") })
	vim.cmd("startinsert!")
end

function M.toggle_fold(state)
	local item = state_mod.get_selected_item(state)
	if not item or not item.group then
		return
	end

	local path = item.group.path
	state.collapsed_paths[path] = not state.collapsed_paths[path]
	refresh_dashboard(state)
end

function M.open_fold(state)
	local item = state_mod.get_selected_item(state)
	if not item or not item.group then
		return
	end

	state.collapsed_paths[item.group.path] = nil
	refresh_dashboard(state)
end

function M.close_fold(state)
	local item = state_mod.get_selected_item(state)
	if not item or not item.group then
		return
	end

	state.collapsed_paths[item.group.path] = true
	refresh_dashboard(state)
end

function M.expand_all(state)
	state.collapsed_paths = {}
	refresh_dashboard(state)
end

function M.collapse_all(state)
	for _, group in ipairs(state.groups or {}) do
		state.collapsed_paths[group.path] = true
	end
	refresh_dashboard(state)
end

function M.show_help()
	vim.notify(
		table.concat({
			"RocketLog Dashboard",
			"",
			"<CR>/o open current window",
			"v      open in vertical split",
			"d      delete selected log",
			"D      delete all logs in selected file",
			"r      refresh selected file labels",
			"R      rescan dashboard",
			"/      open live filter",
			"c      clear current filter",
			"<Tab>  toggle selected file fold",
			"za     toggle selected file fold",
			"zo     open selected file fold",
			"zc     close selected file fold",
			"zR     expand all files",
			"zM     collapse all files",
			"t      toggle project/current-file scope",
			"q      close dashboard",
		}, "\n"),
		vim.log.levels.INFO
	)
end

function M.attach(state)
	local list_buf = state.ui.list_buf
	local dashboard_buffers = {
		state.ui.root_buf,
		state.ui.header_buf,
		state.ui.list_buf,
		state.ui.help_buf,
		state.ui.preview_buf,
	}
	local augroup = vim.api.nvim_create_augroup("RocketLogDashboardRuntime", { clear = false })

	local function map(buffers, lhs, rhs, desc)
		for _, bufnr in ipairs(buffers) do
			if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
				vim.keymap.set(
					"n",
					lhs,
					rhs,
					{ buffer = bufnr, nowait = true, silent = true, desc = desc }
				)
			end
		end
	end

	map(dashboard_buffers, "q", function()
		defer(function()
			state_mod.close(state)
		end)
	end, "Close RocketLog dashboard")
	map(dashboard_buffers, "<Esc>", function()
		defer(function()
			state_mod.close(state)
		end)
	end, "Close RocketLog dashboard")
	map({ list_buf }, "<CR>", function()
		M.open_selected(state, "edit")
	end, "Open selected RocketLog")
	map({ list_buf }, "o", function()
		M.open_selected(state, "edit")
	end, "Open selected RocketLog")
	map({ list_buf }, "v", function()
		M.open_selected(state, "vsplit")
	end, "Open selected RocketLog in vsplit")
	map({ list_buf }, "d", function()
		M.delete_selected(state)
	end, "Delete selected RocketLog")
	map({ list_buf }, "D", function()
		M.delete_selected_file(state)
	end, "Delete RocketLogs in selected file")
	map({ list_buf }, "r", function()
		M.refresh_selected(state)
	end, "Refresh selected file")
	map({ list_buf }, "R", function()
		M.rescan(state)
	end, "Rescan dashboard")
	map({ list_buf }, "t", function()
		M.toggle_scope(state)
	end, "Toggle dashboard scope")
	map({ list_buf }, "/", function()
		M.open_live_filter(state)
	end, "Open live dashboard filter")
	map({ list_buf }, "c", function()
		M.clear_filter(state)
	end, "Clear dashboard filter")
	map({ list_buf }, "?", function()
		M.show_help()
	end, "Show dashboard help")
	map({ list_buf }, "<Tab>", function()
		M.toggle_fold(state)
	end, "Toggle selected file fold")
	map({ list_buf }, "za", function()
		M.toggle_fold(state)
	end, "Toggle selected file fold")
	map({ list_buf }, "zo", function()
		M.open_fold(state)
	end, "Open selected file fold")
	map({ list_buf }, "zc", function()
		M.close_fold(state)
	end, "Close selected file fold")
	map({ list_buf }, "zR", function()
		M.expand_all(state)
	end, "Expand all dashboard groups")
	map({ list_buf }, "zM", function()
		M.collapse_all(state)
	end, "Collapse all dashboard groups")

	vim.api.nvim_create_autocmd("CursorMoved", {
		group = augroup,
		buffer = list_buf,
		callback = function()
			if state_mod.is_open() then
				render.render_shell(state)
				render.render_preview(state)
			end
		end,
	})
end

return M

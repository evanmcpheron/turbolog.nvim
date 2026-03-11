local config = require("rocketlog.config")

local M = {}

local ROOT_HIGHLIGHT = table.concat({
	"Normal:NormalFloat",
	"FloatBorder:RocketLogDashboardBorder",
	"FloatTitle:RocketLogDashboardTitle",
}, ",")

local READONLY_HIGHLIGHT = table.concat({
	"Normal:NormalFloat",
	"FloatBorder:RocketLogDashboardPaneBorder",
	"FloatTitle:RocketLogDashboardPaneTitle",
}, ",")

local LIST_HIGHLIGHT = table.concat({
	"Normal:NormalFloat",
	"CursorLine:RocketLogDashboardCursorLine",
	"FloatBorder:RocketLogDashboardPaneBorder",
	"FloatTitle:RocketLogDashboardPaneTitle",
}, ",")

local PREVIEW_HIGHLIGHT = table.concat({
	"Normal:RocketLogDashboardPreview",
	"FloatBorder:RocketLogDashboardPaneBorder",
	"FloatTitle:RocketLogDashboardPaneTitle",
}, ",")

local function clamp_ratio(value, fallback)
	if type(value) == "number" and value > 0 and value <= 1 then
		return value
	end

	return fallback
end

local function clamp_dimension(desired, minimum, maximum)
	if maximum <= 0 then
		return maximum
	end

	if maximum < minimum then
		return maximum
	end

	return math.max(minimum, math.min(desired, maximum))
end

local function mark_dashboard_buffer(bufnr, role)
	pcall(vim.api.nvim_buf_set_var, bufnr, "rocketlog_dashboard", true)
	pcall(vim.api.nvim_buf_set_var, bufnr, "rocketlog_dashboard_role", role or "pane")
end

local function mark_dashboard_window(win, role)
	pcall(vim.api.nvim_win_set_var, win, "rocketlog_dashboard", true)
	pcall(vim.api.nvim_win_set_var, win, "rocketlog_dashboard_role", role or "pane")
end

local function create_scratch_buffer(filetype, role)
	local bufnr = vim.api.nvim_create_buf(false, true)
	vim.bo[bufnr].buftype = "nofile"
	vim.bo[bufnr].bufhidden = "wipe"
	vim.bo[bufnr].swapfile = false
	vim.bo[bufnr].modifiable = true
	vim.bo[bufnr].filetype = filetype or ""
	mark_dashboard_buffer(bufnr, role)
	return bufnr
end

local function create_float_window(bufnr, enter, opts, role)
	local win = vim.api.nvim_open_win(bufnr, enter, opts)
	mark_dashboard_window(win, role)
	vim.wo[win].number = false
	vim.wo[win].relativenumber = false
	vim.wo[win].signcolumn = "no"
	vim.wo[win].foldcolumn = "0"
	vim.wo[win].wrap = false
	return win
end

local function fill_buffer_with_spaces(bufnr, width, height)
	local lines = {}
	for _ = 1, height do
		table.insert(lines, string.rep(" ", width))
	end
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
	vim.bo[bufnr].modifiable = false
end

---@param state table
function M.open(state)
	local dashboard_config = config.config.dashboard or {}
	local total_width = clamp_dimension(math.floor(vim.o.columns * clamp_ratio(dashboard_config.width, 0.96)), 100, vim.o.columns - 2)
	local total_height = clamp_dimension(math.floor(vim.o.lines * clamp_ratio(dashboard_config.height, 0.92)), 24, vim.o.lines - 2)
	local row = math.max(0, math.floor((vim.o.lines - total_height) / 2) - 1)
	local col = math.max(0, math.floor((vim.o.columns - total_width) / 2))
	local frame_padding = 0
	local pane_gap = 1
	local stack_gap = 0
	local outer_width = total_width - (frame_padding * 2)
	local outer_height = total_height - (frame_padding * 2)
	local header_outer_height = 5
	local help_outer_height = 5
	local main_outer_height = outer_height - header_outer_height - help_outer_height - (stack_gap * 2)

	if main_outer_height < 10 then
		header_outer_height = 4
		help_outer_height = 4
		main_outer_height = outer_height - header_outer_height - help_outer_height - (stack_gap * 2)
	end

	local left_outer_width = math.max(40, math.floor((outer_width - pane_gap) * 0.36))
	local right_outer_width = outer_width - left_outer_width - pane_gap

	state.ui.width = total_width
	state.ui.height = total_height
	state.ui.frame_padding = frame_padding
	state.ui.pane_gap = pane_gap
	state.ui.left_outer_width = left_outer_width
	state.ui.right_outer_width = right_outer_width
	state.ui.header_height = header_outer_height - 2
	state.ui.help_height = help_outer_height - 2
	state.ui.main_height = main_outer_height - 2
	state.ui.list_height = main_outer_height - 2
	state.ui.preview_height = main_outer_height - 2
	state.ui.header_width = outer_width - 2
	state.ui.help_width = outer_width - 2
	state.ui.list_width = left_outer_width - 2
	state.ui.preview_width = right_outer_width - 2
	state.ui.filter_width = math.min(72, math.max(32, total_width - 20))

	local root_buf = create_scratch_buffer("rocketlogdashboard", "root")
	local root_win = create_float_window(root_buf, true, {
		relative = "editor",
		row = row,
		col = col,
		width = total_width,
		height = total_height,
		style = "minimal",
		border = "rounded",
		title = " RocketLog Dashboard ",
		title_pos = "center",
		zindex = 60,
	}, "root")
	vim.wo[root_win].winhighlight = ROOT_HIGHLIGHT
	fill_buffer_with_spaces(root_buf, total_width, total_height)

	local header_buf = create_scratch_buffer("rocketlogdashboard", "header")
	local list_buf = create_scratch_buffer("rocketlogdashboard", "list")
	local help_buf = create_scratch_buffer("rocketlogdashboard", "help")
	local preview_buf = create_scratch_buffer("rocketlogdashboard", "preview")

	local header_row = frame_padding
	local main_row = header_row + header_outer_height + stack_gap
	local help_row = main_row + main_outer_height + stack_gap
	local left_col = frame_padding
	local right_col = frame_padding + left_outer_width + pane_gap

	local header_win = create_float_window(header_buf, false, {
		relative = "win",
		win = root_win,
		row = header_row,
		col = frame_padding,
		width = outer_width - 2,
		height = header_outer_height - 2,
		style = "minimal",
		focusable = false,
		border = "rounded",
		title = " Overview ",
		title_pos = "left",
		zindex = 61,
	}, "header")

	local list_win = create_float_window(list_buf, true, {
		relative = "win",
		win = root_win,
		row = main_row,
		col = left_col,
		width = left_outer_width - 2,
		height = main_outer_height - 2,
		style = "minimal",
		focusable = true,
		border = "rounded",
		title = " Logs ",
		title_pos = "left",
		zindex = 61,
	}, "list")

	local preview_win = create_float_window(preview_buf, false, {
		relative = "win",
		win = root_win,
		row = main_row,
		col = right_col,
		width = right_outer_width - 2,
		height = main_outer_height - 2,
		style = "minimal",
		focusable = false,
		border = "rounded",
		title = " Preview ",
		title_pos = "left",
		zindex = 61,
	}, "preview")

	local help_win = create_float_window(help_buf, false, {
		relative = "win",
		win = root_win,
		row = help_row,
		col = frame_padding,
		width = outer_width - 2,
		height = help_outer_height - 2,
		style = "minimal",
		focusable = false,
		border = "rounded",
		title = " Keybindings ",
		title_pos = "left",
		zindex = 61,
	}, "help")

	vim.wo[list_win].cursorline = true
	vim.wo[list_win].winhighlight = LIST_HIGHLIGHT
	vim.wo[header_win].winhighlight = READONLY_HIGHLIGHT
	vim.wo[help_win].winhighlight = READONLY_HIGHLIGHT
	vim.wo[preview_win].winhighlight = PREVIEW_HIGHLIGHT

	state.ui.root_buf = root_buf
	state.ui.root_win = root_win
	state.ui.header_buf = header_buf
	state.ui.header_win = header_win
	state.ui.list_buf = list_buf
	state.ui.list_win = list_win
	state.ui.help_buf = help_buf
	state.ui.help_win = help_win
	state.ui.preview_buf = preview_buf
	state.ui.preview_win = preview_win
end

return M

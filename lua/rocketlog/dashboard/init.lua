local actions = require("rocketlog.dashboard.actions")
local highlights = require("rocketlog.dashboard.highlights")
local layout = require("rocketlog.dashboard.layout")
local render = require("rocketlog.dashboard.render")
local scan = require("rocketlog.dashboard.scan")
local state_mod = require("rocketlog.dashboard.state")

local M = {}

---@return table
function M.open()
	if state_mod.is_open() then
		local existing = state_mod.get_current()
		if existing and existing.ui.list_win and vim.api.nvim_win_is_valid(existing.ui.list_win) then
			vim.api.nvim_set_current_win(existing.ui.list_win)
		end
		return state_mod.get_current()
	end

	highlights.setup()

	local source_bufnr = vim.api.nvim_get_current_buf()
	local state = state_mod.new(source_bufnr)
	state_mod.set_current(state)

	layout.open(state)
	scan.collect_groups(state)
	render.refresh(state)
	actions.attach(state)

	if state.ui.list_win and vim.api.nvim_win_is_valid(state.ui.list_win) then
		vim.api.nvim_set_current_win(state.ui.list_win)
	end

	return state
end

function M.close()
	state_mod.close(state_mod.get_current())
end

function M.toggle()
	if state_mod.is_open() then
		M.close()
		return
	end

	M.open()
end

return M

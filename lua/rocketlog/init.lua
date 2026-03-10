local actions = require("rocketlog.actions")
local config = require("rocketlog.config")
local delete = require("rocketlog.delete")
local refresh = require("rocketlog.refresh")

_G.RocketLogs = _G.RocketLogs or {}

local M = _G.RocketLogs

M.config = config.config
M._registered_keymaps = M._registered_keymaps or {}

local USER_COMMANDS = {
	{
		name = "RocketLogFind",
		desc = "Open picker with RocketLog entries",
		callback = function()
			require("rocketlog").find_logs()
		end,
	},
	{
		name = "RocketLogDashboard",
		desc = "Open RocketLog dashboard",
		callback = function()
			require("rocketlog").open_dashboard()
		end,
	},
}

-- Neovim operatorfunc must point to a global function.
_G.__rocket_log_motions = function(optype)
	local log_type = _G.__rocket_log_type or "log"
	require("rocketlog").motions(optype, log_type)
	_G.__rocket_log_type = nil
end

---@param optype string
---@param log_type string|nil
function M.motions(optype, log_type)
	actions.motions(optype, log_type)
end

---@param log_type string|nil
function M.log_word_under_cursor(log_type)
	actions.log_word_under_cursor(log_type)
end

---@param opts table|nil
function M.find_logs(opts)
	require("rocketlog.telescope").find_logs(opts)
end

function M.open_dashboard()
	require("rocketlog.dashboard").open()
end

function M.toggle_dashboard()
	require("rocketlog.dashboard").toggle()
end

---@return boolean
function M.delete_next_log()
	return delete.delete_next_log()
end

---@return boolean
function M.delete_prev_log()
	return delete.delete_prev_log()
end

---@return integer
function M.clear_buffer_logs()
	return delete.clear_buffer_logs()
end

local function clear_registered_keymaps()
	for _, lhs in ipairs(M._registered_keymaps) do
		pcall(vim.keymap.del, "n", lhs)
	end

	M._registered_keymaps = {}
end

---@param lhs string|false|nil
---@param rhs function
---@param desc string
---@param opts table|nil
local function register_keymap(lhs, rhs, desc, opts)
	if not lhs or lhs == false then
		return
	end

	local keymap_opts = vim.tbl_deep_extend("force", { desc = desc }, opts or {})
	vim.keymap.set("n", lhs, rhs, keymap_opts)
	table.insert(M._registered_keymaps, lhs)
end

---@param log_type string
---@param desc string
---@return function, table
local function make_operator_mapping(log_type, desc)
	return function()
		_G.__rocket_log_anchor_line = vim.fn.line(".")
		_G.__rocket_log_type = log_type
		vim.o.operatorfunc = "v:lua.__rocket_log_motions"
		return "g@"
	end, { expr = true, desc = desc }
end

---@param log_type string
---@return function
local function make_word_mapping(log_type)
	return function()
		require("rocketlog").log_word_under_cursor(log_type)
	end
end

local function reset_user_commands()
	for _, command in ipairs(USER_COMMANDS) do
		pcall(vim.api.nvim_del_user_command, command.name)
	end
end

local function register_user_commands()
	for _, command in ipairs(USER_COMMANDS) do
		vim.api.nvim_create_user_command(command.name, command.callback, { desc = command.desc })
	end
end

---@param keymaps table
local function register_default_keymaps(keymaps)
	local operator_specs = {
		{ lhs = keymaps.motions, type = "log", desc = "Rocket log motions (motion/textobject)" },
		{
			lhs = keymaps.error_motions,
			type = "error",
			desc = "Rocket error log motions (motion/textobject)",
		},
		{
			lhs = keymaps.warn_motions,
			type = "warn",
			desc = "Rocket warn log motions (motion/textobject)",
		},
		{
			lhs = keymaps.info_motions,
			type = "info",
			desc = "Rocket info log motions (motion/textobject)",
		},
	}

	for _, spec in ipairs(operator_specs) do
		local rhs, opts = make_operator_mapping(spec.type, spec.desc)
		register_keymap(spec.lhs, rhs, opts.desc, opts)
	end

	local normal_specs = {
		{
			lhs = keymaps.word,
			rhs = make_word_mapping("log"),
			desc = "Rocket log word under cursor",
		},
		{
			lhs = keymaps.error_word,
			rhs = make_word_mapping("error"),
			desc = "Rocket error log word under cursor",
		},
		{
			lhs = keymaps.warn_word,
			rhs = make_word_mapping("warn"),
			desc = "Rocket warn log word under cursor",
		},
		{
			lhs = keymaps.info_word,
			rhs = make_word_mapping("info"),
			desc = "Rocket info log word under cursor",
		},
		{
			lhs = keymaps.find,
			rhs = function()
				require("rocketlog").find_logs()
			end,
			desc = "Find RocketLog entries",
		},
		{
			lhs = keymaps.dashboard,
			rhs = function()
				require("rocketlog").toggle_dashboard()
			end,
			desc = "Open RocketLog dashboard",
		},
		{
			lhs = keymaps.delete_all_buffer,
			rhs = function()
				require("rocketlog").clear_buffer_logs()
			end,
			desc = "Delete all RocketLogs in buffer",
		},
		{
			lhs = keymaps.delete_below,
			rhs = function()
				require("rocketlog").delete_next_log()
			end,
			desc = "Delete next RocketLog below",
		},
		{
			lhs = keymaps.delete_above,
			rhs = function()
				require("rocketlog").delete_prev_log()
			end,
			desc = "Delete RocketLog above",
		},
	}

	for _, spec in ipairs(normal_specs) do
		register_keymap(spec.lhs, spec.rhs, spec.desc)
	end
end

---@param opts table|nil
function M.setup(opts)
	config.apply(opts)
	M.config = config.config

	clear_registered_keymaps()
	reset_user_commands()

	if not config.config.enabled then
		return
	end

	register_user_commands()
	register_default_keymaps(config.config.keymaps)
end

vim.api.nvim_create_autocmd("BufWritePre", {
	group = vim.api.nvim_create_augroup("RocketLogRefreshOnSave", { clear = true }),
	pattern = "*",
	callback = function()
		if config.config.enabled == false or config.config.refresh_on_save == false then
			return
		end

		if vim.bo.buftype ~= "" then
			return
		end

		local ok_guards, guards = pcall(require, "rocketlog.guards")
		if ok_guards and not guards.is_supported_filetype() then
			return
		end

		refresh.refresh_buffer()
	end,
})

return M

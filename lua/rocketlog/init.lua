local config = require("rocketlog.config")
local actions = require("rocketlog.actions")
local delete = require("rocketlog.delete")
local refresh = require("rocketlog.refresh")

_G.RocketLogs = _G.RocketLogs or {}
local M = _G.RocketLogs

M.config = config.config
M._registered_keymaps = M._registered_keymaps or {}

-- Must be global because Neovim's operatorfunc requires a global function reference.
_G.__rocket_log_motions = function(optype)
	local log_type = _G.__rocket_log_type or "log"
	require("rocketlog").motions(optype, log_type)
	_G.__rocket_log_type = nil
end

---@param optype string
---@param log_type string|nil Optional log type (e.g., "error") to determine console method
function M.motions(optype, log_type)
	actions.motions(optype, log_type)
end

---@param log_type string|nil Optional log type (e.g., "error") to determine console method
function M.log_word_under_cursor(log_type)
	actions.log_word_under_cursor(log_type)
end

---@param opts table|nil Optional picker options
---@return nil
function M.find_logs(opts)
	require("rocketlog.telescope").find_logs(opts)
end

---@return nil
function M.open_dashboard()
	require("rocketlog.dashboard").open()
end

---@return nil
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

	local merged_opts = vim.tbl_deep_extend("force", { desc = desc }, opts or {})
	vim.keymap.set("n", lhs, rhs, merged_opts)
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

---@param opts table|nil
function M.setup(opts)
	config.apply(opts)
	M.config = config.config

	clear_registered_keymaps()
	pcall(vim.api.nvim_del_user_command, "RocketLogFind")
	pcall(vim.api.nvim_del_user_command, "RocketLogDashboard")

	if not config.config.enabled then
		return
	end

	vim.api.nvim_create_user_command("RocketLogFind", function()
		require("rocketlog").find_logs()
	end, { desc = "Open picker with RocketLog entries" })

	vim.api.nvim_create_user_command("RocketLogDashboard", function()
		require("rocketlog").open_dashboard()
	end, { desc = "Open RocketLog dashboard" })

	local keymap_config = config.config.keymaps

	local motions_rhs, motions_opts = make_operator_mapping("log", "Rocket log motions (motion/textobject)")
	register_keymap(keymap_config.motions, motions_rhs, motions_opts.desc, motions_opts)
	register_keymap(keymap_config.word, make_word_mapping("log"), "Rocket log word under cursor")
	register_keymap(keymap_config.error_word, make_word_mapping("error"), "Rocket error log word under cursor")

	local error_rhs, error_opts = make_operator_mapping("error", "Rocket error log motions (motion/textobject)")
	register_keymap(keymap_config.error_motions, error_rhs, error_opts.desc, error_opts)
	register_keymap(keymap_config.warn_word, make_word_mapping("warn"), "Rocket warn log word under cursor")

	local warn_rhs, warn_opts = make_operator_mapping("warn", "Rocket warn log motions (motion/textobject)")
	register_keymap(keymap_config.warn_motions, warn_rhs, warn_opts.desc, warn_opts)
	register_keymap(keymap_config.info_word, make_word_mapping("info"), "Rocket info log word under cursor")

	local info_rhs, info_opts = make_operator_mapping("info", "Rocket info log motions (motion/textobject)")
	register_keymap(keymap_config.info_motions, info_rhs, info_opts.desc, info_opts)

	register_keymap(keymap_config.find, function()
		require("rocketlog").find_logs()
	end, "Find RocketLog entries")

	register_keymap(keymap_config.dashboard, function()
		require("rocketlog").toggle_dashboard()
	end, "Open RocketLog dashboard")

	register_keymap(keymap_config.delete_all_buffer, function()
		require("rocketlog").clear_buffer_logs()
	end, "Delete all RocketLogs in buffer")

	register_keymap(keymap_config.delete_below, function()
		require("rocketlog").delete_next_log()
	end, "Delete next RocketLog below")

	register_keymap(keymap_config.delete_above, function()
		require("rocketlog").delete_prev_log()
	end, "Delete RocketLog above")
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

		local ok, guards = pcall(require, "rocketlog.guards")
		if ok and not guards.is_supported_filetype() then
			return
		end

		refresh.refresh_buffer()
	end,
})

return M

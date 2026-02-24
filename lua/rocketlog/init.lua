local config = require("rocketlog.config")
local actions = require("rocketlog.actions")
local refresh = require("rocketlog.refresh")

-- A stable global you can hang helpers off of.
-- (Lua global table is `_G`, not `__G`.)
_G.RocketLogs = _G.RocketLogs or {}
local M = _G.RocketLogs

-- Expose runtime config (kept in a separate module).
M.config = config.config

---Resolve the configured default console method.
---@return string
local function default_console_method()
	local cfg = config.config or {}
	local method = cfg.default_console_method
	if type(method) == "string" and method ~= "" then
		return method
	end
	return "log"
end

-- Must be global because Neovim's operatorfunc requires a global function reference.
---@param optype string
---@return nil
_G.__rocket_log_operator = function(optype)
	local log_type = _G.__rocket_log_type or default_console_method()
	require("rocketlog").operator(optype, log_type)

	-- Reset temporary operator state after each run.
	_G.__rocket_log_type = nil
end

---Operator entrypoint (used by g@ via operatorfunc).
---@param optype string
---@param log_type string|nil Optional log type (e.g., "error") to determine console method
---@return nil
function M.operator(optype, log_type)
	actions.operator(optype, log_type)
end

---Insert a rocket log for the word currently under the cursor.
---@param log_type string|nil Optional log type (e.g., "error") to determine console method
---@return nil
function M.log_word_under_cursor(log_type)
	actions.log_word_under_cursor(log_type)
end

---Open Telescope and list only RocketLog entries.
---@param opts table|nil Optional Telescope picker options
---@return nil
function M.find_logs(opts)
	require("rocketlog.telescope").find_logs(opts)
end

---Setup plugin configuration, keymaps, and commands.
---@param opts table|nil
---@return nil
function M.setup(opts)
	config.apply(opts)
	M.config = config.config

	if not config.config.enabled then
		return
	end

	local keymap_config = config.config.keymaps

	-- Expose a command for project-wide RocketLog discovery.
	pcall(vim.api.nvim_del_user_command, "RocketLogFind")
	vim.api.nvim_create_user_command("RocketLogFind", function()
		require("rocketlog").find_logs()
	end, { desc = "Open Telescope with RocketLog entries" })

	-- Operator-pending mapping for the configured default console method.
	if keymap_config.operator and keymap_config.operator ~= false then
		vim.keymap.set("n", keymap_config.operator, function()
			-- Save cursor line before g@ motion executes so we can anchor insertion.
			_G.__rocket_log_anchor_line = vim.fn.line(".")
			-- Tell the operator which console method to use.
			_G.__rocket_log_type = default_console_method()
			vim.o.operatorfunc = "v:lua.__rocket_log_operator"
			return "g@"
		end, { expr = true, desc = "Rocket log operator (motion/textobject)" })
	end

	-- Word-under-cursor mapping for the configured default console method.
	if keymap_config.word and keymap_config.word ~= false then
		vim.keymap.set("n", keymap_config.word, function()
			require("rocketlog").log_word_under_cursor(default_console_method())
		end, { desc = "Rocket log word under cursor" })
	end

	-- Word-under-cursor mapping for error logs.
	if keymap_config.error_word and keymap_config.error_word ~= false then
		vim.keymap.set("n", keymap_config.error_word, function()
			require("rocketlog").log_word_under_cursor("error")
		end, { desc = "Rocket error log word under cursor" })
	end

	-- Operator-pending mapping for error logging (motion/textobject based).
	if keymap_config.error_operator and keymap_config.error_operator ~= false then
		vim.keymap.set("n", keymap_config.error_operator, function()
			-- Save cursor line before g@ motion executes so we can anchor insertion.
			_G.__rocket_log_anchor_line = vim.fn.line(".")
			-- Tell the operator which console method to use.
			_G.__rocket_log_type = "error"
			vim.o.operatorfunc = "v:lua.__rocket_log_operator"
			return "g@"
		end, { expr = true, desc = "Rocket error log operator (motion/textobject)" })
	end

	-- Open Telescope scoped to RocketLog entries only.
	if keymap_config.find and keymap_config.find ~= false then
		vim.keymap.set("n", keymap_config.find, function()
			require("rocketlog").find_logs()
		end, { desc = "Find RocketLog entries" })
	end
end

-- Refresh generated labels before saving so line numbers stay accurate.
vim.api.nvim_create_autocmd("BufWritePre", {
	group = vim.api.nvim_create_augroup("RocketLogRefreshOnSave", { clear = true }),
	pattern = { "*.js", "*.jsx", "*.ts", "*.tsx" },
	callback = function()
		local rocketlog = require("rocketlog")

		-- Respect plugin enabled flag.
		if rocketlog.config and rocketlog.config.enabled == false then
			return
		end

		-- Configurable and enabled by default.
		if rocketlog.config and rocketlog.config.refresh_on_save == false then
			return
		end

		-- Optional filetype guard.
		local ok, guards = pcall(require, "rocketlog.guards")
		if ok and not guards.is_supported_filetype() then
			return
		end

		refresh.refresh_buffer()
	end,
})

return M

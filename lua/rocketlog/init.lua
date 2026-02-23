local config = require("rocketlog.config")
local actions = require("rocketlog.actions")
local refresh = require("rocketlog.refresh")

-- A stable global you can hang helpers off of.
-- (Lua global table is `_G`, not `__G`.)
_G.RocketLogs = _G.RocketLogs or {}
local M = _G.RocketLogs

-- Expose runtime config (kept in a separate module).
M.config = config.config

-- Must be global because Neovim's operatorfunc requires a global function reference.
_G.__rocket_log_operator = function(optype)
	require("rocketlog").operator(optype)
end

---Operator entrypoint (used by g@ via operatorfunc).
---@param optype string
function M.operator(optype)
	actions.operator(optype)
end

---Insert a rocket log for the word currently under the cursor.
function M.log_word_under_cursor()
	actions.log_word_under_cursor()
end

---Setup plugin configuration, keymaps, and commands.
---@param opts table|nil
function M.setup(opts)
	config.apply(opts)
	M.config = config.config

	if not config.config.enabled then
		return
	end

	local keymap_config = config.config.keymaps

	-- Operator-pending mapping (motion/textobject based)
	if keymap_config.operator and keymap_config.operator ~= false then
		vim.keymap.set("n", keymap_config.operator, function()
			-- Save cursor line before g@ motion executes so we can anchor insertion.
			_G.__rocket_log_anchor_line = vim.fn.line(".")
			vim.o.operatorfunc = "v:lua.__rocket_log_operator"
			return "g@"
		end, { expr = true, desc = "Rocket log operator (motion/textobject)" })
	end

	-- Word-under-cursor mapping
	if keymap_config.word and keymap_config.word ~= false then
		vim.keymap.set("n", keymap_config.word, function()
			require("rocketlog").log_word_under_cursor()
		end, { desc = "Rocket log word under cursor" })
	end

	-- User command for logging word under cursor
	vim.api.nvim_create_user_command("RocketLogWord", function()
		require("rocketlog").log_word_under_cursor()
	end, { desc = "Insert rocket log for word under cursor" })
end

vim.api.nvim_create_autocmd("BufWritePre", {
	group = vim.api.nvim_create_augroup("RocketLogRefreshOnSave", { clear = true }),
	pattern = { "*.js", "*.jsx", "*.ts", "*.tsx" },
	callback = function()
		local rocketlog = require("rocketlog")

		-- Respect plugin enabled flag if you already use one
		if rocketlog.config and rocketlog.config.enabled == false then
			return
		end

		-- Configurable, default true
		if rocketlog.config and rocketlog.config.refresh_on_save == false then
			return
		end

		-- Optional guard check
		local ok, guards = pcall(require, "rocketlog.guards")
		if ok and not guards.is_supported_filetype() then
			return
		end

		refresh.refresh_buffer()
	end,
})

return M

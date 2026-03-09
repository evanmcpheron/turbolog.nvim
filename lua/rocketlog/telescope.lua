local M = {}

local config = require("rocketlog.config")

---Open the configured project picker and list only RocketLog entries.
---The search query is fixed to the RocketLog marker so users cannot change the
---underlying grep pattern from this picker.
---@param opts table|nil Optional picker options (theme, cwd, layout, etc.)
---@return nil
function M.find_logs(opts)
	local ok, Snacks = pcall(require, "snacks")
	if not ok or not Snacks.picker then
		vim.notify("snacks.nvim picker is not available", vim.log.levels.WARN)
		return
	end

	local picker_opts = vim.tbl_deep_extend("force", {
		source = "grep",
		title = "RocketLog",
		search = config.get_marker(),
		live = false,
		regex = false,
	}, opts or {})

	Snacks.picker.pick(picker_opts)
end

return M

local M = {}

local build = require("rocketlog.build")

---Open a Telescope picker that lists only RocketLog entries in the current project.
---The search query is fixed to the RocketLog marker so users cannot change the
---underlying grep pattern from this picker.
---@param opts table|nil Optional Telescope picker options (theme, cwd, layout, etc.)
---@return nil
function M.find_logs(opts)
	local rocketlog_label = RocketLogs.config.label or "ROCKETLOG"
	local ok, Snacks = pcall(require, "snacks")
	if not ok or not Snacks.picker then
		vim.notify("snacks.nvim picker is not available", vim.log.levels.WARN)
		return
	end

	Snacks.picker.pick({
		source = "grep",
		title = "RocketLog",
		search = "[" .. rocketlog_label .. "]",
		live = false,
		regex = false,
	})
end

return M

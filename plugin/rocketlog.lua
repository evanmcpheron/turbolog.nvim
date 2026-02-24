-- Optional auto-setup with defaults.
-- Set `vim.g.rocketlog_disable_auto_setup = true` before loading to disable.
if not vim.g.rocketlog_disable_auto_setup then
	pcall(function()
		require("rocketlog").setup()
	end)
end

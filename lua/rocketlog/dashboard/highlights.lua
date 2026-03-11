local M = {}

function M.setup()
	vim.api.nvim_set_hl(0, "RocketLogDashboardBorder", { link = "FloatBorder", default = true })
	vim.api.nvim_set_hl(0, "RocketLogDashboardPaneBorder", { link = "FloatBorder", default = true })
	vim.api.nvim_set_hl(0, "RocketLogDashboardTitle", { link = "Title", default = true })
	vim.api.nvim_set_hl(0, "RocketLogDashboardPaneTitle", { link = "Title", default = true })
	vim.api.nvim_set_hl(0, "RocketLogDashboardHeader", { link = "Keyword", default = true })
	vim.api.nvim_set_hl(0, "RocketLogDashboardFooter", { link = "Comment", default = true })
	vim.api.nvim_set_hl(0, "RocketLogDashboardMetaLabel", { link = "Special", default = true })
	vim.api.nvim_set_hl(0, "RocketLogDashboardHintKey", { link = "Directory", default = true })
	vim.api.nvim_set_hl(0, "RocketLogDashboardGroup", { link = "Directory", default = true })
	vim.api.nvim_set_hl(0, "RocketLogDashboardFoldIcon", { link = "Special", default = true })
	vim.api.nvim_set_hl(0, "RocketLogDashboardPath", { link = "Comment", default = true })
	vim.api.nvim_set_hl(0, "RocketLogDashboardLineNr", { link = "LineNr", default = true })
	vim.api.nvim_set_hl(0, "RocketLogDashboardStale", { link = "DiagnosticWarn", default = true })
	vim.api.nvim_set_hl(0, "RocketLogDashboardDisabled", { link = "Comment", default = true })
	vim.api.nvim_set_hl(0, "RocketLogDashboardLog", { link = "DiagnosticInfo", default = true })
	vim.api.nvim_set_hl(0, "RocketLogDashboardWarn", { link = "DiagnosticWarn", default = true })
	vim.api.nvim_set_hl(0, "RocketLogDashboardError", { link = "DiagnosticError", default = true })
	vim.api.nvim_set_hl(0, "RocketLogDashboardInfo", { link = "DiagnosticHint", default = true })
	vim.api.nvim_set_hl(0, "RocketLogDashboardPreview", { link = "NormalFloat", default = true })
	vim.api.nvim_set_hl(0, "RocketLogDashboardPreviewMeta", { link = "Comment", default = true })
	vim.api.nvim_set_hl(0, "RocketLogDashboardPreviewTarget", { link = "Visual", default = true })
	vim.api.nvim_set_hl(0, "RocketLogDashboardCursorLine", { link = "Visual", default = true })
end

return M

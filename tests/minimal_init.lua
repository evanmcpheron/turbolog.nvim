-- Keep startup deterministic for tests.
-- We want specs to explicitly call `require("rocketlog").setup()` when needed.
vim.g.rocketlog_disable_auto_setup = true

vim.opt.runtimepath:prepend(vim.fn.getcwd())

local data_dir = vim.fn.stdpath("data")
local plenary_path = data_dir .. "/lazy/plenary.nvim"
vim.opt.runtimepath:append(plenary_path)

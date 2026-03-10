local h = require("tests.helpers")

describe("rocketlog.init", function()
	local rocketlog

	before_each(function()
		vim.g.rocketlog_disable_auto_setup = true
		_G.RocketLogs = nil
		_G.__rocket_log_type = nil
		_G.__rocket_log_anchor_line = nil

		package.loaded["rocketlog"] = nil
		package.loaded["rocketlog.init"] = nil
		rocketlog = require("rocketlog")
	end)

	it("exports setup", function()
		assert.is_true(type(rocketlog.setup) == "function")
	end)

	it("exports public logging actions", function()
		assert.is_true(type(rocketlog.motions) == "function")
		assert.is_true(type(rocketlog.log_word_under_cursor) == "function")
		assert.is_true(type(rocketlog.find_logs) == "function")
		assert.is_true(type(rocketlog.open_dashboard) == "function")
		assert.is_true(type(rocketlog.toggle_dashboard) == "function")
	end)

	it("exports public delete actions", function()
		assert.is_true(type(rocketlog.delete_next_log) == "function")
		assert.is_true(type(rocketlog.delete_prev_log) == "function")
		assert.is_true(type(rocketlog.clear_buffer_logs) == "function")
	end)

	it("setup creates the RocketLogFind and RocketLogDashboard user commands", function()
		rocketlog.setup({
			keymaps = {
				motions = false,
				word = false,
				error_motions = false,
				error_word = false,
				warn_motions = false,
				warn_word = false,
				info_motions = false,
				info_word = false,
				delete_below = false,
				delete_above = false,
				delete_all_buffer = false,
				find = false,
				dashboard = false,
			},
		})
		assert.are.equal(2, vim.fn.exists(":RocketLogFind"))
		assert.are.equal(2, vim.fn.exists(":RocketLogDashboard"))
	end)

	it("setup applies user config without error", function()
		rocketlog.setup({
			label = "MYLABEL",
			refresh_on_insert = false,
			keymaps = {
				motions = false,
				word = false,
				error_motions = false,
				error_word = false,
				warn_motions = false,
				warn_word = false,
				info_motions = false,
				info_word = false,
				delete_below = false,
				delete_above = false,
				delete_all_buffer = false,
				find = false,
				dashboard = false,
			},
		})

		assert.are.equal("MYLABEL", rocketlog.config.label)
		assert.is_false(rocketlog.config.refresh_on_insert)
	end)

	it("setup can be called multiple times safely", function()
		rocketlog.setup({
			label = "FIRST",
			keymaps = {
				motions = false,
				word = false,
				error_motions = false,
				error_word = false,
				warn_motions = false,
				warn_word = false,
				info_motions = false,
				info_word = false,
				delete_below = false,
				delete_above = false,
				delete_all_buffer = false,
				find = false,
				dashboard = false,
			},
		})

		rocketlog.setup({
			label = "SECOND",
			keymaps = {
				motions = false,
				word = false,
				error_motions = false,
				error_word = false,
				warn_motions = false,
				warn_word = false,
				info_motions = false,
				info_word = false,
				delete_below = false,
				delete_above = false,
				delete_all_buffer = false,
				find = false,
				dashboard = false,
			},
		})

		assert.are.equal("SECOND", rocketlog.config.label)
	end)

	it("operator-pending mapping uses operatorfunc and stages the log type", function()
		local captured_callback
		local restore_set = h.stub(vim.keymap, "set", function(_, lhs, rhs, opts)
			if lhs == "gm" then
				captured_callback = rhs
				assert.is_true(opts.expr)
			end
		end)

		local restore_line = h.stub(vim.fn, "line", function(arg)
			if arg == "." then
				return 7
			end
			return 1
		end)

		rocketlog.setup({
			keymaps = {
				motions = "gm",
				word = false,
				error_motions = false,
				error_word = false,
				warn_motions = false,
				warn_word = false,
				info_motions = false,
				info_word = false,
				delete_below = false,
				delete_above = false,
				delete_all_buffer = false,
				find = false,
				dashboard = false,
			},
		})

		assert.is_truthy(captured_callback)
		assert.are.equal("g@", captured_callback())
		assert.are.equal(7, _G.__rocket_log_anchor_line)
		assert.are.equal("log", _G.__rocket_log_type)
		assert.are.equal("v:lua.__rocket_log_motions", vim.o.operatorfunc)

		restore_set()
		restore_line()
	end)

	it("setup registers the dashboard keymap when enabled", function()
		local seen = false
		local restore_set = h.stub(vim.keymap, "set", function(_, lhs)
			if lhs == "<leader>rr" then
				seen = true
			end
		end)

		rocketlog.setup({
			keymaps = {
				motions = false,
				word = false,
				error_motions = false,
				error_word = false,
				warn_motions = false,
				warn_word = false,
				info_motions = false,
				info_word = false,
				delete_below = false,
				delete_above = false,
				delete_all_buffer = false,
				find = false,
				dashboard = "<leader>rr",
			},
		})

		assert.is_true(seen)
		restore_set()
	end)

	it("refresh-on-save autocmd respects supported filetypes", function()
		local refresh = require("rocketlog.refresh")
		local calls = 0

		local restore_refresh = h.stub(refresh, "refresh_buffer", function()
			calls = calls + 1
			return 0
		end)

		local bufnr = h.set_buffer({
			"console.log(`🚀[ROCKETLOG] ~ wrong.ts:1 ~ x:`, x);",
		}, { filetype = "typescript", name = "/tmp/test.ts" })

		rocketlog.setup({ keymaps = { motions = false, word = false } })
		vim.bo[bufnr].buftype = ""
		vim.api.nvim_exec_autocmds("BufWritePre", { buffer = bufnr })
		assert.are.equal(1, calls)

		vim.bo[bufnr].filetype = "lua"
		vim.api.nvim_exec_autocmds("BufWritePre", { buffer = bufnr })
		assert.are.equal(1, calls)

		restore_refresh()
	end)
end)

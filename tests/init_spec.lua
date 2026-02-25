describe("rocketlog.init", function()
	local rocketlog

	before_each(function()
		vim.g.rocketlog_disable_auto_setup = true

		package.loaded["rocketlog"] = nil
		package.loaded["rocketlog.init"] = nil
		rocketlog = require("rocketlog")
	end)

	it("exports setup", function()
		assert.is_true(type(rocketlog.setup) == "function")
	end)

	it("exports public logging actions", function()
		assert.is_true(type(rocketlog.operator) == "function")
		assert.is_true(type(rocketlog.log_word_under_cursor) == "function")
		assert.is_true(type(rocketlog.find_logs) == "function")
	end)

	it("exports public delete actions", function()
		assert.is_true(type(rocketlog.delete_next_log) == "function")
		assert.is_true(type(rocketlog.delete_prev_log) == "function")
		assert.is_true(type(rocketlog.clear_buffer_logs) == "function")
	end)

	it("setup creates the RocketLogFind user command", function()
		rocketlog.setup({ keymaps = { operator = false, word = false, error_operator = false, error_word = false, warn_operator = false, warn_word = false, info_operator = false, info_word = false, delete_below = false, delete_above = false, delete_all_buffer = false, find = false } })
		-- Vim returns 2 for a user-defined Ex command.
		assert.are.equal(2, vim.fn.exists(":RocketLogFind"))
	end)

	it("setup applies user config without error", function()
		rocketlog.setup({
			label = "MYLABEL",
			refresh_on_insert = false,
			keymaps = {
				operator = false,
				word = false,
				error_operator = false,
				error_word = false,
				warn_operator = false,
				warn_word = false,
				info_operator = false,
				info_word = false,
				delete_below = false,
				delete_above = false,
				delete_all_buffer = false,
				find = false,
			},
		})

		assert.are.equal("MYLABEL", rocketlog.config.label)
		assert.is_false(rocketlog.config.refresh_on_insert)
	end)

	it("setup can be called multiple times safely", function()
		rocketlog.setup({
			label = "FIRST",
			keymaps = {
				operator = false,
				word = false,
				error_operator = false,
				error_word = false,
				warn_operator = false,
				warn_word = false,
				info_operator = false,
				info_word = false,
				delete_below = false,
				delete_above = false,
				delete_all_buffer = false,
				find = false,
			},
		})

		rocketlog.setup({
			label = "SECOND",
			keymaps = {
				operator = false,
				word = false,
				error_operator = false,
				error_word = false,
				warn_operator = false,
				warn_word = false,
				info_operator = false,
				info_word = false,
				delete_below = false,
				delete_above = false,
				delete_all_buffer = false,
				find = false,
			},
		})

		assert.are.equal("SECOND", rocketlog.config.label)
	end)
end)

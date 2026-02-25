local h = require("tests.helpers")

describe("rocketlog.actions", function()
	local actions
	local config

	before_each(function()
		-- Ensure the global label exists for build + delete modules.
		_G.RocketLogs = { config = { label = "ROCKETLOG" } }

		-- Fresh buffer for each test.
		h.set_buffer({ "const user = { name: 'Evan' };" }, { filetype = "typescript", name = "/tmp/test.ts" })
		h.set_cursor(1, 6) -- on "user"

		-- Reset config to defaults, then apply per-test overrides.
		package.loaded["rocketlog.config"] = nil
		config = require("rocketlog.config")
		config.apply({
			enabled = true,
			refresh_on_insert = true,
			prefer_treesitter = false, -- isolate actions tests from parser availability
		})

		-- Load the public module so actions.refresh_after_insert_if_enabled can read rocketlog.config.
		package.loaded["rocketlog"] = nil
		package.loaded["rocketlog.init"] = nil
		require("rocketlog").setup({
			-- Disable keymaps in tests to avoid polluting global state.
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

		package.loaded["rocketlog.actions"] = nil
		actions = require("rocketlog.actions")
	end)

	after_each(function()
		pcall(vim.cmd, "bwipeout!")
	end)

	it("bails on unsupported filetypes", function()
		vim.bo.filetype = "lua"

		local restore_notify, messages = h.capture_notify()
		-- Avoid accidental inserts.
		local insert = require("rocketlog.insert")
		local restore_insert = h.stub(insert, "insert_after_statement", function()
			error("should not insert")
		end)

		actions.log_word_under_cursor("log")

		restore_insert()
		restore_notify()

		assert.is_true(#messages >= 1)
		assert.is_true(messages[1].msg:find("unsupported filetype", 1, true) ~= nil)
	end)

	it("logs word under cursor with default log type", function()
		local insert = require("rocketlog.insert")
		local build = require("rocketlog.build")
		local refresh = require("rocketlog.refresh")

		local restore_find = h.stub(insert, "find_log_line_number", function(anchor)
			-- Ensure the anchor is the current cursor line.
			assert.are.equal(1, anchor)
			return 2
		end)

		local restore_build
		local build_calls = {}
		restore_build = h.stub(build, "build_rocket_log_lines", function(file, line_num, expr, log_type)
			table.insert(build_calls, { file = file, line_num = line_num, expr = expr, log_type = log_type })
			return { "console.log('stub');" }
		end)

		local restore_insert
		local insert_calls = {}
		restore_insert = h.stub(insert, "insert_after_statement", function(lines, start_line, ctx)
			table.insert(insert_calls, { lines = lines, start_line = start_line, ctx = ctx })
			return 2, nil
		end)

		local restore_refresh
		local refresh_calls = 0
		restore_refresh = h.stub(refresh, "refresh_buffer", function()
			refresh_calls = refresh_calls + 1
			return 0
		end)

		actions.log_word_under_cursor(nil)

		restore_find()
		restore_build()
		restore_insert()
		restore_refresh()

		assert.are.equal(1, #build_calls)
		assert.are.equal("test.ts", build_calls[1].file)
		assert.are.equal(2, build_calls[1].line_num)
		assert.are.equal("user", build_calls[1].expr)
		assert.is_nil(build_calls[1].log_type)

		assert.are.equal(1, #insert_calls)
		assert.are.equal(1, insert_calls[1].start_line)
		assert.are.same({ "console.log('stub');" }, insert_calls[1].lines)
		assert.is_true(type(insert_calls[1].ctx) == "table")

		assert.are.equal(1, refresh_calls)
	end)

	it("logs word under cursor with error log type", function()
		local build = require("rocketlog.build")
		local insert = require("rocketlog.insert")

		local restore_build
		restore_build = h.stub(build, "build_rocket_log_lines", function(_, _, _, log_type)
			assert.are.equal("error", log_type)
			return { "console.error('stub');" }
		end)

		local restore_insert = h.stub(insert, "insert_after_statement", function()
			return 2, nil
		end)

		actions.log_word_under_cursor("error")

		restore_build()
		restore_insert()
	end)

	it("logs word under cursor with warn log type", function()
		local build = require("rocketlog.build")
		local insert = require("rocketlog.insert")

		local restore_build
		restore_build = h.stub(build, "build_rocket_log_lines", function(_, _, _, log_type)
			assert.are.equal("warn", log_type)
			return { "console.warn('stub');" }
		end)

		local restore_insert = h.stub(insert, "insert_after_statement", function()
			return 2, nil
		end)

		actions.log_word_under_cursor("warn")

		restore_build()
		restore_insert()
	end)

	it("runs refresh after insert when refresh_on_insert is true", function()
		config.apply({ refresh_on_insert = true })
		require("rocketlog").setup({ refresh_on_insert = true, keymaps = { operator = false, word = false } })

		local refresh = require("rocketlog.refresh")
		local insert = require("rocketlog.insert")

		local restore_insert = h.stub(insert, "insert_after_statement", function()
			return 2, nil
		end)

		local restore_refresh
		local calls = 0
		restore_refresh = h.stub(refresh, "refresh_buffer", function()
			calls = calls + 1
			return 0
		end)

		actions.log_word_under_cursor("log")

		restore_insert()
		restore_refresh()

		assert.are.equal(1, calls)
	end)

	it("does not run refresh after insert when refresh_on_insert is false", function()
		config.apply({ refresh_on_insert = false })
		require("rocketlog").setup({ refresh_on_insert = false, keymaps = { operator = false, word = false } })

		local refresh = require("rocketlog.refresh")
		local insert = require("rocketlog.insert")

		local restore_insert = h.stub(insert, "insert_after_statement", function()
			return 2, nil
		end)

		local restore_refresh
		local calls = 0
		restore_refresh = h.stub(refresh, "refresh_buffer", function()
			calls = calls + 1
			return 0
		end)

		actions.log_word_under_cursor("log")

		restore_insert()
		restore_refresh()

		assert.are.equal(0, calls)
	end)

	it("handles treesitter implicit arrow body errors gracefully", function()
		local insert = require("rocketlog.insert")
		local refresh = require("rocketlog.refresh")

		local restore_notify, messages = h.capture_notify()
		local restore_insert = h.stub(insert, "insert_after_statement", function()
			return nil, "implicit_arrow_body"
		end)

		local restore_refresh
		local calls = 0
		restore_refresh = h.stub(refresh, "refresh_buffer", function()
			calls = calls + 1
			return 0
		end)

		actions.log_word_under_cursor("log")

		restore_notify()
		restore_insert()
		restore_refresh()

		assert.are.equal(0, calls)
		assert.is_true(#messages >= 1)
		assert.is_true(messages[1].msg:find("implicit arrow", 1, true) ~= nil)
	end)

	it("handles treesitter function header selection errors gracefully", function()
		local insert = require("rocketlog.insert")
		local refresh = require("rocketlog.refresh")

		local restore_notify, messages = h.capture_notify()
		local restore_insert = h.stub(insert, "insert_after_statement", function()
			return nil, "selection_in_function_header"
		end)

		local restore_refresh
		local calls = 0
		restore_refresh = h.stub(refresh, "refresh_buffer", function()
			calls = calls + 1
			return 0
		end)

		actions.log_word_under_cursor("log")

		restore_notify()
		restore_insert()
		restore_refresh()

		assert.are.equal(0, calls)
		assert.is_true(#messages >= 1)
		assert.is_true(messages[1].msg:find("function header", 1, true) ~= nil)
	end)

	it(
		"falls back to heuristic insertion when treesitter is unavailable if supported",
		function()
			-- Force treesitter failure so insert module must use its heuristic path.
			-- Prefer Tree-sitter first so we are actually testing the fallback behavior.
			require("rocketlog.config").apply({ prefer_treesitter = true, fallback_to_heuristics = true })
			local restore_ts = h.stub(vim.treesitter, "get_parser", function()
				error("no parser")
			end)

			-- Use real insert/build to validate insertion actually happens.
			h.set_buffer({
				"const a = 1;",
				"const b = 2;",
			}, { filetype = "typescript", name = "/tmp/test.ts" })
			h.set_cursor(1, 6)

			actions.log_word_under_cursor("log")

			restore_ts()

			local lines = h.get_lines()
			assert.is_true(#lines == 3)
			assert.is_true(lines[2]:find("console.log", 1, true) ~= nil)
		end
	)

	it("does not insert when selection extraction fails", function()
		local insert = require("rocketlog.insert")
		local selection = require("rocketlog.selection")

		local restore_sel = h.stub(selection, "get_text_from_marks", function()
			return nil
		end)

		local restore_insert = h.stub(insert, "insert_after_statement", function()
			error("should not insert")
		end)

		actions.operator("char", "log")

		restore_sel()
		restore_insert()
	end)

	it("passes the correct filename and line number to build", function()
		local build = require("rocketlog.build")
		local insert = require("rocketlog.insert")

		local restore_find = h.stub(insert, "find_log_line_number", function(anchor)
			assert.are.equal(1, anchor)
			return 10
		end)

		local restore_build = h.stub(build, "build_rocket_log_lines", function(file, line_num)
			assert.are.equal("test.ts", file)
			assert.are.equal(10, line_num)
			return { "console.log('stub');" }
		end)

		local restore_insert = h.stub(insert, "insert_after_statement", function()
			return 2, nil
		end)

		actions.log_word_under_cursor("log")

		restore_find()
		restore_build()
		restore_insert()
	end)

	it("passes the correct expression text to build", function()
		local build = require("rocketlog.build")
		local insert = require("rocketlog.insert")

		local restore_build = h.stub(build, "build_rocket_log_lines", function(_, _, expr)
			assert.are.equal("user", expr)
			return { "console.log('stub');" }
		end)

		local restore_insert = h.stub(insert, "insert_after_statement", function()
			return 2, nil
		end)

		actions.log_word_under_cursor("log")

		restore_build()
		restore_insert()
	end)

	it("passes the correct log type through to build", function()
		local build = require("rocketlog.build")
		local insert = require("rocketlog.insert")

		local restore_build = h.stub(build, "build_rocket_log_lines", function(_, _, _, log_type)
			assert.are.equal("info", log_type)
			return { "console.info('stub');" }
		end)

		local restore_insert = h.stub(insert, "insert_after_statement", function()
			return 2, nil
		end)

		actions.log_word_under_cursor("info")

		restore_build()
		restore_insert()
	end)
end)

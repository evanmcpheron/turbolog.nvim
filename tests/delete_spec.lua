local h = require("tests.helpers")

describe("rocketlog.delete", function()
	local delete
	local build

	before_each(function()
		_G.RocketLogs = { config = { label = "ROCKETLOG" } }

		-- Force Tree-sitter delete path to be unavailable so tests stay deterministic.
		-- We still validate the actual deletion behavior via the fallback logic.
		if vim.treesitter and vim.treesitter.get_parser then
			vim._rocketlog_restore_get_parser = vim.treesitter.get_parser
			vim.treesitter.get_parser = function()
				error("no parser")
			end
		end

		h.set_buffer({}, { filetype = "typescript", name = "/tmp/test.ts" })

		package.loaded["rocketlog.build"] = nil
		build = require("rocketlog.build")

		package.loaded["rocketlog.delete"] = nil
		delete = require("rocketlog.delete")
	end)

	after_each(function()
		if vim._rocketlog_restore_get_parser then
			vim.treesitter.get_parser = vim._rocketlog_restore_get_parser
			vim._rocketlog_restore_get_parser = nil
		end
		pcall(vim.cmd, "bwipeout!")
	end)

	it("deletes the nearest RocketLog below the cursor", function()
		h.set_buffer({
			"const a = 1;",
			"console.log(`🚀[ROCKETLOG] ~ test.ts:2 ~ a:`, a);",
			"const b = 2;",
		}, { filetype = "typescript" })

		h.set_cursor(1, 0)
		local ok = delete.delete_next_log()
		local lines = h.get_lines()

		assert.is_true(ok)
		assert.are.same({ "const a = 1;", "const b = 2;" }, lines)
	end)

	it("deletes the nearest RocketLog above the cursor", function()
		h.set_buffer({
			"const a = 1;",
			"console.log(`🚀[ROCKETLOG] ~ test.ts:2 ~ a:`, a);",
			"const b = 2;",
		}, { filetype = "typescript" })

		h.set_cursor(3, 0)
		local ok = delete.delete_prev_log()
		local lines = h.get_lines()

		assert.is_true(ok)
		assert.are.same({ "const a = 1;", "const b = 2;" }, lines)
	end)

	it("does not delete non-RocketLog console statements", function()
		h.set_buffer({
			"console.log('normal log');",
			"console.log(`🚀[ROCKETLOG] ~ test.ts:2 ~ a:`, a);",
			"console.log('still normal');",
		}, { filetype = "typescript" })

		h.set_cursor(1, 0)
		delete.delete_next_log()
		local lines = h.get_lines()

		assert.are.same({
			"console.log('normal log');",
			"console.log('still normal');",
		}, lines)
	end)

	it("deletes only one log when multiple RocketLogs exist below", function()
		h.set_buffer({
			"const a = 1;",
			"console.log(`🚀[ROCKETLOG] ~ test.ts:2 ~ a:`, a);",
			"console.log(`🚀[ROCKETLOG] ~ test.ts:3 ~ b:`, b);",
			"const c = 3;",
		}, { filetype = "typescript" })

		h.set_cursor(1, 0)
		delete.delete_next_log()
		local lines = h.get_lines()

		-- Only the first RocketLog below the cursor should be deleted.
		assert.are.same({
			"const a = 1;",
			"console.log(`🚀[ROCKETLOG] ~ test.ts:3 ~ b:`, b);",
			"const c = 3;",
		}, lines)
	end)

	it("deletes only one log when multiple RocketLogs exist above", function()
		h.set_buffer({
			"console.log(`🚀[ROCKETLOG] ~ test.ts:1 ~ a:`, a);",
			"console.log(`🚀[ROCKETLOG] ~ test.ts:2 ~ b:`, b);",
			"const c = 3;",
		}, { filetype = "typescript" })

		h.set_cursor(3, 0)
		delete.delete_prev_log()
		local lines = h.get_lines()

		-- Only the nearest RocketLog above should be deleted (line 2 in original buffer).
		assert.are.same({
			"console.log(`🚀[ROCKETLOG] ~ test.ts:1 ~ a:`, a);",
			"const c = 3;",
		}, lines)
	end)

	it("deletes all RocketLogs in the current buffer", function()
		h.set_buffer({
			"console.log(`🚀[ROCKETLOG] ~ test.ts:1 ~ a:`, a);",
			"const x = 1;",
			"console.log(`🚀[ROCKETLOG] ~ test.ts:3 ~ b:`, b);",
		}, { filetype = "typescript" })

		h.set_cursor(2, 0)
		local count = delete.clear_buffer_logs()
		local lines = h.get_lines()

		assert.are.equal(2, count)
		assert.are.same({ "const x = 1;" }, lines)
	end)

	it("preserves non-log code when deleting all RocketLogs", function()
		h.set_buffer({
			"const a = 1;",
			"console.log(`🚀[ROCKETLOG] ~ test.ts:2 ~ a:`, a);",
			"const b = 2;",
			"console.log('normal');",
			"console.log(`🚀[ROCKETLOG] ~ test.ts:5 ~ b:`, b);",
			"const c = 3;",
		}, { filetype = "typescript" })

		delete.clear_buffer_logs()
		local lines = h.get_lines()

		assert.are.same({
			"const a = 1;",
			"const b = 2;",
			"console.log('normal');",
			"const c = 3;",
		}, lines)
	end)

	it("deletes a multiline RocketLog block completely", function()
		local multiline = build.build_rocket_log_lines("test.ts", 2, "users\n  .filter(Boolean)", "log")

		-- Build produces a well-formed multi-line console call. Insert it into a buffer.
		local lines = { "const x = 1;" }
		for _, l in ipairs(multiline) do
			table.insert(lines, l)
		end
		table.insert(lines, "const y = 2;")

		h.set_buffer(lines, { filetype = "typescript" })
		h.set_cursor(1, 0)

		local ok = delete.delete_next_log()
		assert.is_true(ok)

		local after = h.get_lines()
		assert.are.same({ "const x = 1;", "const y = 2;" }, after)
	end)

	it("handles mixed single-line and multiline RocketLogs in the same buffer", function()
		local multiline = build.build_rocket_log_lines("test.ts", 3, "users\n  .filter(Boolean)", "log")

		local lines = {
			"console.log(`🚀[ROCKETLOG] ~ test.ts:1 ~ a:`, a);",
			"const x = 1;",
		}

		for _, l in ipairs(multiline) do
			table.insert(lines, l)
		end

		table.insert(lines, "const y = 2;")

		h.set_buffer(lines, { filetype = "typescript" })

		local count = delete.clear_buffer_logs()
		assert.are.equal(2, count)

		local after = h.get_lines()
		assert.are.same({ "const x = 1;", "const y = 2;" }, after)
	end)

	it("returns false or no-op when no RocketLog exists below", function()
		h.set_buffer({ "const x = 1;" }, { filetype = "typescript" })
		h.set_cursor(1, 0)

		local ok = delete.delete_next_log()
		assert.is_false(ok)
	end)

	it("returns false or no-op when no RocketLog exists above", function()
		h.set_buffer({ "const x = 1;" }, { filetype = "typescript" })
		h.set_cursor(1, 0)

		local ok = delete.delete_prev_log()
		assert.is_false(ok)
	end)

	it("returns false or no-op when clearing a buffer with no RocketLogs", function()
		h.set_buffer({ "const x = 1;" }, { filetype = "typescript" })

		local count = delete.clear_buffer_logs()
		assert.are.equal(0, count)
	end)

	it("matches current label format for RocketLog detection", function()
		_G.RocketLogs.config.label = "MYLABEL"
		h.set_buffer({
			"const x = 1;",
			"console.log(`🚀[MYLABEL] ~ test.ts:2 ~ x:`, x);",
			"const y = 2;",
		}, { filetype = "typescript" })

		h.set_cursor(1, 0)
		local ok = delete.delete_next_log()
		assert.is_true(ok)
		assert.are.same({ "const x = 1;", "const y = 2;" }, h.get_lines())
	end)

	it("matches legacy RocketLog formats if you support them", function()
		-- Legacy format (rocket-only marker): `🚀 ~ file.ts:line ~`
		h.set_buffer({
			"const x = 1;",
			"console.log(`🚀 ~ wrong.ts:99 ~ x:`, x);",
			"const y = 2;",
		}, { filetype = "typescript" })

		h.set_cursor(1, 0)
		local ok = delete.delete_next_log()
		assert.is_true(ok)
		assert.are.same({ "const x = 1;", "const y = 2;" }, h.get_lines())
	end)
end)

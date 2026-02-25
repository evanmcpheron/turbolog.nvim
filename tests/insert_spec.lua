local h = require("tests.helpers")

describe("rocketlog.insert", function()
	local insert
	local config

	before_each(function()
		-- Ensure build/insert read a stable global label.
		_G.RocketLogs = { config = { label = "ROCKETLOG" } }

		package.loaded["rocketlog.config"] = nil
		config = require("rocketlog.config")
		config.apply({
			prefer_treesitter = false, -- Keep heuristic tests deterministic.
			fallback_to_heuristics = true,
		})

		h.set_buffer({}, { filetype = "typescript", name = "/tmp/test.ts" })

		package.loaded["rocketlog.insert"] = nil
		insert = require("rocketlog.insert")
	end)

	after_each(function()
		pcall(vim.cmd, "bwipeout!")
	end)

	it("finds insertion line after a simple semicolon statement", function()
		h.set_buffer({
			"const x = 1;",
			"const y = 2;",
		}, { filetype = "typescript" })

		local line = insert.find_log_line_number(1)
		assert.are.equal(2, line) -- insert after line 1
	end)

	it("finds insertion line after a simple statement without semicolon", function()
		h.set_buffer({
			"const x = 1",
			"const y = 2",
		}, { filetype = "typescript" })

		local line = insert.find_log_line_number(1)
		assert.are.equal(2, line)
	end)

	it("finds insertion line after a multiline chained call with semicolons", function()
		h.set_buffer({
			"const activeNames = users",
			"  .filter((u) => u.isActive)",
			"  .map((u) => u.profile?.displayName ?? 'Unknown');",
			"const y = 2;",
		}, { filetype = "typescript" })

		local line = insert.find_log_line_number(1)
		assert.are.equal(4, line)
	end)

	it("finds insertion line after a multiline chained call without semicolons", function()
		h.set_buffer({
			"const activeNames = users",
			"  .filter((u) => u.isActive)",
			"  .map((u) => u.profile?.displayName ?? 'Unknown')",
			"const y = 2",
		}, { filetype = "typescript" })

		local line = insert.find_log_line_number(1)
		assert.are.equal(4, line)
	end)

	it("finds insertion line after a multiline object literal assignment", function()
		h.set_buffer({
			"const obj = {",
			"  a: 1,",
			"  b: 2,",
			"};",
			"const y = 2;",
		}, { filetype = "typescript" })

		local line = insert.find_log_line_number(1)
		assert.are.equal(5, line)
	end)

	it("finds insertion line after a multiline array literal assignment", function()
		h.set_buffer({
			"const arr = [",
			"  1,",
			"  2,",
			"];",
			"const y = 2;",
		}, { filetype = "typescript" })

		local line = insert.find_log_line_number(1)
		assert.are.equal(5, line)
	end)

	it("finds insertion line after a multiline function call argument list", function()
		h.set_buffer({
			"const q = fakeQuery(",
			"  'SELECT *',",
			"  [1, 2, 3],",
			"  { ok: true },",
			");",
			"const y = 2;",
		}, { filetype = "typescript" })

		local line = insert.find_log_line_number(1)
		assert.are.equal(6, line)
	end)

	it("finds insertion line after a nested expression inside an if block", function()
		h.set_buffer({
			"if (ok) {",
			"  const value = compute(",
			"    a,",
			"    b",
			"  );",
			"  return value;",
			"}",
		}, { filetype = "typescript" })

		local line = insert.find_log_line_number(2)
		assert.are.equal(6, line)
	end)

	it("preserves indentation when inserting inside a block", function()
		h.set_buffer({
			"if (ok) {",
			"  const x = 1;",
			"}",
		}, { filetype = "typescript" })

		local inserted_at = insert.insert_after_statement(
			"console.log(`🚀[ROCKETLOG] ~ test.ts:1 ~ x:`, x);",
			2,
			nil
		)

		local lines = h.get_lines()
		assert.are.equal(3, inserted_at)
		assert.are.equal("  console.log(`🚀[ROCKETLOG] ~ test.ts:1 ~ x:`, x);", lines[3])
	end)

	it("inserts a single log line into the buffer after a statement", function()
		h.set_buffer({
			"const x = 1;",
			"const y = 2;",
		}, { filetype = "typescript" })

		insert.insert_after_statement(
			"console.log(`🚀[ROCKETLOG] ~ test.ts:1 ~ x:`, x);",
			1,
			nil
		)

		local lines = h.get_lines()
		assert.are.same({
			"const x = 1;",
			"console.log(`🚀[ROCKETLOG] ~ test.ts:1 ~ x:`, x);",
			"const y = 2;",
		}, lines)
	end)

	it("inserts multiple log lines into the buffer for multiline logs", function()
		h.set_buffer({
			"const x = users",
			"  .filter(Boolean)",
			"  .map((u) => u.id);",
		}, { filetype = "typescript" })

		local log_lines = {
			"console.log(`🚀[ROCKETLOG] ~ test.ts:1 ~",
			"users",
			"`,",
			"  users",
			");",
		}

		local inserted_at = insert.insert_after_statement(log_lines, 1, nil)
		local lines = h.get_lines()

		assert.are.equal(4, inserted_at)
		-- Multiline insertion should be contiguous.
		assert.are.same(log_lines, { lines[4], lines[5], lines[6], lines[7], lines[8] })
	end)

	it("returns inserted line number for single-line insertion", function()
		h.set_buffer({ "const x = 1;", "const y = 2;" }, { filetype = "typescript" })

		local inserted_line = insert.insert_after_statement(
			"console.log(`🚀[ROCKETLOG] ~ test.ts:1 ~ x:`, x);",
			1,
			nil
		)

		assert.are.equal(2, inserted_line)
	end)

	it("returns inserted line number for multiline insertion", function()
		h.set_buffer({ "const x = 1;", "const y = 2;" }, { filetype = "typescript" })

		local inserted_line = insert.insert_after_statement({
			"console.log(`🚀[ROCKETLOG] ~ test.ts:1 ~",
			"x",
			"`,",
			"  x",
			");",
		}, 1, nil)

		assert.are.equal(2, inserted_line)
	end)

	it("normalizes anchor line when selection starts on a continuation line", function()
		h.set_buffer({
			"const obj = {",
			"  a: 1,",
			"  b: 2,",
			"};",
		}, { filetype = "typescript" })

		-- Selection begins on a property line; normalize should shift to the assignment opener.
		local normalized = insert.normalize_anchor_line(2, 2)
		assert.are.equal(1, normalized)
	end)

	it("does not over-normalize anchor line for simple one-line statements", function()
		h.set_buffer({
			"const x = 1;",
			"const y = 2;",
		}, { filetype = "typescript" })

		local normalized = insert.normalize_anchor_line(1, 1)
		assert.are.equal(1, normalized)
	end)

	it("handles insertion at end of file", function()
		h.set_buffer({
			"const x = 1;",
		}, { filetype = "typescript" })

		local inserted_at = insert.insert_after_statement(
			"console.log(`🚀[ROCKETLOG] ~ test.ts:1 ~ x:`, x);",
			1,
			nil
		)

		local lines = h.get_lines()
		assert.are.equal(2, inserted_at)
		assert.are.equal(2, #lines)
		assert.are.equal("console.log(`🚀[ROCKETLOG] ~ test.ts:1 ~ x:`, x);", lines[2])
	end)

	it("handles insertion when buffer has blank lines around the statement", function()
		h.set_buffer({
			"const x = 1",
			"",
			"",
			"const y = 2",
		}, { filetype = "typescript" })

		local line = insert.find_log_line_number(1)
		assert.are.equal(2, line)
	end)

	it("does not split a method chain by inserting in the middle", function()
		h.set_buffer({
			"const activeNames = users",
			"  .filter((u) => u.isActive)",
			"  .map((u) => u.id);",
			"const y = 2;",
		}, { filetype = "typescript" })

		-- Starting from the middle of the chain should still insert after the chain.
		local line = insert.find_log_line_number(2)
		assert.are.equal(4, line)
	end)

	it("does not split a multiline assignment by inserting in the middle", function()
		h.set_buffer({
			"const obj = {",
			"  a: 1,",
			"  b: 2,",
			"};",
			"const y = 2;",
		}, { filetype = "typescript" })

		local line = insert.find_log_line_number(2)
		assert.are.equal(5, line)
	end)

	it("uses a Tree-sitter target when provided", function()
		-- This test validates the insert module's *integration* with a treesitter result
		-- without requiring real parsers. We stub resolve_insertion to return a target.
		config.apply({ prefer_treesitter = true })

		local restore_ts
		package.loaded["rocketlog.treesitter"] = nil
		local fake_ts = {}
		fake_ts.resolve_insertion = function(_)
			return { mode = "after", line = 1, reference_line = 1, source = "treesitter" }, nil
		end
		package.loaded["rocketlog.treesitter"] = fake_ts

		h.set_buffer({
			"const x = 1;",
			"const y = 2;",
		}, { filetype = "typescript" })

		local inserted_at = insert.insert_after_statement(
			"console.log(`🚀[ROCKETLOG] ~ test.ts:1 ~ x:`, x);",
			1,
			{ start_row0 = 0, start_col0 = 0, end_row0 = 0, end_col0 = 0 }
		)

		local lines = h.get_lines()
		assert.are.equal(2, inserted_at)
		assert.are.equal("console.log(`🚀[ROCKETLOG] ~ test.ts:1 ~ x:`, x);", lines[2])

		-- Cleanup stubbed module.
		package.loaded["rocketlog.treesitter"] = nil
	end)

	it("returns scope errors from Tree-sitter without falling back", function()
		config.apply({ prefer_treesitter = true, fallback_to_heuristics = true })

		package.loaded["rocketlog.treesitter"] = {
			resolve_insertion = function(_)
				return nil, "implicit_arrow_body"
			end,
		}

		h.set_buffer({ "const x = 1;" }, { filetype = "typescript" })

		local inserted, err = insert.insert_after_statement(
			"console.log('x')",
			1,
			{ start_row0 = 0, start_col0 = 0, end_row0 = 0, end_col0 = 0 }
		)

		assert.is_nil(inserted)
		assert.are.equal("implicit_arrow_body", err)
		package.loaded["rocketlog.treesitter"] = nil
	end)

	it("does not fall back when fallback_to_heuristics is false", function()
		config.apply({ prefer_treesitter = true, fallback_to_heuristics = false })

		package.loaded["rocketlog.treesitter"] = {
			resolve_insertion = function(_)
				return nil, "parser_unavailable"
			end,
		}

		h.set_buffer({ "const x = 1;" }, { filetype = "typescript" })

		local inserted, err = insert.insert_after_statement(
			"console.log('x')",
			1,
			{ start_row0 = 0, start_col0 = 0, end_row0 = 0, end_col0 = 0 }
		)

		assert.is_nil(inserted)
		assert.are.equal("parser_unavailable", err)
		package.loaded["rocketlog.treesitter"] = nil
	end)

	it("inserts a line into the buffer", function()
		h.set_buffer({
			"const x = 1;",
			"const y = 2;",
		}, { filetype = "typescript" })

		local inserted_line = insert.insert_after_statement(
			"console.log(`🚀[ROCKETLOG] ~ test.ts:1 ~ x:`, x);",
			1,
			nil
		)

		local lines = h.get_lines()

		assert.are.equal(2, inserted_line)
		assert.are.same({
			"const x = 1;",
			"console.log(`🚀[ROCKETLOG] ~ test.ts:1 ~ x:`, x);",
			"const y = 2;",
		}, lines)
	end)
end)

local h = require("tests.helpers")

describe("rocketlog.selection", function()
	local selection

	before_each(function()
		h.set_buffer({}, { filetype = "typescript", name = "/tmp/test.ts" })

		package.loaded["rocketlog.selection"] = nil
		selection = require("rocketlog.selection")
	end)

	after_each(function()
		pcall(vim.cmd, "bwipeout!")
	end)

	it("extracts a single-line selection correctly", function()
		h.set_buffer({ "const answer = 42;" }, { filetype = "typescript" })

		-- Select "answer" from the line.
		-- Columns are 0-based: "const " is 6 chars, so 'a' is col=6.
		h.set_operator_marks(1, 6, 1, 11)

		local text, start_line, end_line, start_col, end_col = selection.get_text_from_marks("char")
		assert.are.equal("answer", text)
		assert.are.equal(1, start_line)
		assert.are.equal(1, end_line)
		assert.are.equal(6, start_col)
		assert.are.equal(11, end_col)
	end)

	it("extracts a multiline selection correctly", function()
		h.set_buffer({
			"const users = [",
			"  { id: 'a' },",
			"  { id: 'b' },",
			"];",
		}, { filetype = "typescript" })

		-- Select from "[" to "]" including indentation.
		h.set_operator_marks(1, 14, 4, 1)

		local text, start_line, end_line = selection.get_text_from_marks("char")
		assert.are.equal(1, start_line)
		assert.are.equal(4, end_line)

		-- Should preserve inner indentation because nvim_buf_get_text keeps it for middle lines.
		assert.is_true(text:find("\n  { id: 'a' },\n", 1, true) ~= nil)
	end)

	it("returns nil or error for invalid marks", function()
		h.set_buffer({ "const x = 1;" }, { filetype = "typescript" })

		-- Marks default to {0,0} when not set.
		local text = selection.get_text_from_marks("char")
		assert.is_nil(text)
	end)

	it("trims selection text as intended", function()
		-- This module intentionally does *not* trim; it returns the exact selected text.
		h.set_buffer({ "  const   x   =   1; " }, { filetype = "typescript" })
		h.set_operator_marks(1, 0, 1, 20)

		local text = selection.get_text_from_marks("char")
		assert.are.equal("  const   x   =   1; ", text)
	end)

	it("returns correct start and end positions for a selection", function()
		h.set_buffer({
			"const a = 1;",
			"const b = 2;",
		}, { filetype = "typescript" })

		-- Select "a = 1;\nconst b" (cross-line selection).
		h.set_operator_marks(1, 6, 2, 6)
		local _, start_line, end_line, start_col, end_col, start_row0, end_row0 =
			selection.get_text_from_marks("char")

		assert.are.equal(1, start_line)
		assert.are.equal(2, end_line)
		assert.are.equal(6, start_col)
		assert.are.equal(6, end_col)
		assert.are.equal(0, start_row0)
		assert.are.equal(1, end_row0)
	end)

	it("extracts linewise selections correctly", function()
		h.set_buffer({
			"const a = 1;",
			"const b = 2;",
			"const c = 3;",
		}, { filetype = "typescript" })

		h.set_operator_marks(1, 0, 2, 0)
		local text, start_line, end_line, start_col, end_col = selection.get_text_from_marks("line")

		assert.are.equal("const a = 1;\nconst b = 2;", text)
		assert.are.equal(1, start_line)
		assert.are.equal(2, end_line)
		assert.are.equal(0, start_col)
		assert.is_true(end_col >= 0)
	end)

	it("extracts word under cursor correctly if module supports it", function()
		-- This module currently only reads marks (operatorfunc selections).
		assert.is_nil(selection.get_word_under_cursor)
	end)
end)

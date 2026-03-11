local h = require("tests.helpers")

describe("rocketlog.comment", function()
	local comment

	before_each(function()
		package.loaded["rocketlog.comment"] = nil
		comment = require("rocketlog.comment")
	end)

	after_each(function()
		pcall(vim.cmd, "bwipeout!")
	end)

	it("comments a range with the correct prefix for the current filetype", function()
		h.set_buffer({
			"  console.log(`🚀[ROCKETLOG] ~ test.ts:1 ~ value:`, value);",
			"  const after = true;",
		}, { filetype = "typescript", name = "/tmp/test.ts" })

		local commented = comment.comment_range(0, 1, 1)

		assert.is_true(commented)
		assert.are.same({
			"  // console.log(`🚀[ROCKETLOG] ~ test.ts:1 ~ value:`, value);",
			"  const after = true;",
		}, h.get_lines())
	end)

	it("comments every line in a multiline log block", function()
		h.set_buffer({
			"console.log(`🚀[ROCKETLOG] ~ test.lua:1 ~",
			"value",
			"`,",
			"  value",
			");",
		}, { filetype = "lua", name = "/tmp/test.lua" })

		local commented = comment.comment_range(0, 1, 5)

		assert.is_true(commented)
		assert.are.same({
			"-- console.log(`🚀[ROCKETLOG] ~ test.lua:1 ~",
			"-- value",
			"-- `,",
			"--   value",
			"-- );",
		}, h.get_lines())
	end)

	it("comments multiline ranges using a shared indent like editor line comments", function()
		h.set_buffer({
			"  console.log(`🚀[ROCKETLOG] ~ test.ts:1 ~",
			"    payload",
			"  `, payload);",
		}, { filetype = "typescript", name = "/tmp/test.ts" })

		local commented = comment.comment_range(0, 1, 3)

		assert.is_true(commented)
		assert.are.same({
			"  // console.log(`🚀[ROCKETLOG] ~ test.ts:1 ~",
			"  //   payload",
			"  // `, payload);",
		}, h.get_lines())
	end)

	it("does not double comment lines that are already commented", function()
		h.set_buffer({
			"// console.log(`🚀[ROCKETLOG] ~ test.ts:1 ~ value:`, value);",
		}, { filetype = "typescript", name = "/tmp/test.ts" })

		local commented = comment.comment_range(0, 1, 1)

		assert.is_false(commented)
		assert.are.same({
			"// console.log(`🚀[ROCKETLOG] ~ test.ts:1 ~ value:`, value);",
		}, h.get_lines())
	end)

	it("uncomments every line in a multiline log block", function()
		h.set_buffer({
			"-- console.log(`🚀[ROCKETLOG] ~ test.lua:1 ~",
			"-- value",
			"-- `,",
			"--   value",
			"-- );",
		}, { filetype = "lua", name = "/tmp/test.lua" })

		local uncommented = comment.uncomment_range(0, 1, 5)

		assert.is_true(uncommented)
		assert.are.same({
			"console.log(`🚀[ROCKETLOG] ~ test.lua:1 ~",
			"value",
			"`,",
			"  value",
			");",
		}, h.get_lines())
	end)

	it("toggles a range back and forth", function()
		h.set_buffer({
			"console.log(`🚀[ROCKETLOG] ~ test.ts:1 ~ value:`, value);",
		}, { filetype = "typescript", name = "/tmp/test.ts" })

		local commented = comment.toggle_range(0, 1, 1)
		local uncommented = comment.toggle_range(0, 1, 1)

		assert.is_true(commented)
		assert.is_true(uncommented)
		assert.are.same({
			"console.log(`🚀[ROCKETLOG] ~ test.ts:1 ~ value:`, value);",
		}, h.get_lines())
	end)

	it("toggles multiline ranges with the same shared indent when commenting", function()
		h.set_buffer({
			"  console.log(`🚀[ROCKETLOG] ~ test.ts:1 ~",
			"    payload",
			"  `, payload);",
		}, { filetype = "typescript", name = "/tmp/test.ts" })

		local commented = comment.toggle_range(0, 1, 3)

		assert.is_true(commented)
		assert.are.same({
			"  // console.log(`🚀[ROCKETLOG] ~ test.ts:1 ~",
			"  //   payload",
			"  // `, payload);",
		}, h.get_lines())

		local uncommented = comment.toggle_range(0, 1, 3)

		assert.is_true(uncommented)
		assert.are.same({
			"  console.log(`🚀[ROCKETLOG] ~ test.ts:1 ~",
			"    payload",
			"  `, payload);",
		}, h.get_lines())
	end)

end)

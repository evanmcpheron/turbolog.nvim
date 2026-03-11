local h = require("tests.helpers")

describe("rocketlog.dashboard.layout", function()
	local layout
	local render
	local scan
	local state_mod

	before_each(function()
		package.loaded["rocketlog.config"] = nil
		require("rocketlog.config").apply({ label = "ROCKETLOG" })

		package.loaded["rocketlog.dashboard.layout"] = nil
		package.loaded["rocketlog.dashboard.render"] = nil
		package.loaded["rocketlog.dashboard.scan"] = nil
		package.loaded["rocketlog.dashboard.state"] = nil

		layout = require("rocketlog.dashboard.layout")
		render = require("rocketlog.dashboard.render")
		scan = require("rocketlog.dashboard.scan")
		state_mod = require("rocketlog.dashboard.state")
	end)

	after_each(function()
		state_mod.close(state_mod.get_current())
		pcall(vim.cmd, "only")
	end)

	it("fits the main panes and full-width chrome inside the dashboard frame", function()
		local source_bufnr = h.set_buffer({
			"console.log(`🚀[ROCKETLOG] ~ test.ts:1 ~ answer:`, answer);",
		}, { filetype = "typescript", name = "test.ts" })
		local state = state_mod.new(source_bufnr)
		state_mod.set_current(state)

		layout.open(state)

		assert.is_true(state.ui.left_outer_width + state.ui.pane_gap + state.ui.right_outer_width <= state.ui.width)
		assert.is_true(state.ui.header_width <= state.ui.width)
		assert.is_true(state.ui.help_width <= state.ui.width)
		assert.are.equal(state.ui.list_height, state.ui.preview_height)
		assert.are.equal(state.ui.left_outer_width - 2, state.ui.list_width)
		assert.are.equal(state.ui.right_outer_width - 2, state.ui.preview_width)
	end)

	it("renders organized metadata at the top and a full-width cheatsheet at the bottom", function()
		local source_bufnr = h.set_buffer({
			"console.log(`🚀[ROCKETLOG] ~ test.ts:1 ~ answer:`, answer);",
		}, { filetype = "typescript", name = "test.ts" })
		local state = state_mod.new(source_bufnr)
		state_mod.set_current(state)
		layout.open(state)
		scan.collect_groups(state)
		render.refresh(state)

		local overview_lines = vim.api.nvim_buf_get_lines(state.ui.header_buf, 0, -1, false)
		local help_lines = vim.api.nvim_buf_get_lines(state.ui.help_buf, 0, -1, false)

		assert.is_truthy(overview_lines[1]:find("CWD", 1, true))
		assert.is_truthy(overview_lines[2]:find("Source", 1, true))
		assert.is_truthy(overview_lines[3]:find("Scope", 1, true))
		assert.is_truthy(help_lines[1]:find("Open [<CR>/o]", 1, true))
		assert.is_truthy(help_lines[2]:find("Close [q/Esc]", 1, true))
		assert.is_truthy(help_lines[3]:find("Selected", 1, true))
	end)
end)

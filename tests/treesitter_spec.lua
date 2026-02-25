local h = require("tests.helpers")

describe("rocketlog.treesitter", function()
	local treesitter
	local restore_get_parser

	-- Minimal fake TSNode implementation for unit testing resolve_insertion.
	local node_id = 0
	local function new_node(node_type, sr, sc, er, ec, named)
		node_id = node_id + 1
		local node = {
			_id = node_id,
			_type = node_type,
			_range = { sr, sc, er, ec },
			_parent = nil,
			_children = {},
			_named = named ~= false,
		}

		function node:id()
			return self._id
		end

		function node:type()
			return self._type
		end

		function node:range()
			return self._range[1], self._range[2], self._range[3], self._range[4]
		end

		function node:parent()
			return self._parent
		end

		function node:named()
			return self._named
		end

		function node:iter_children()
			local i = 0
			return function()
				i = i + 1
				return self._children[i]
			end
		end

		return node
	end

	local function add_child(parent, child)
		child._parent = parent
		table.insert(parent._children, child)
		return child
	end

	local function make_parser_with_root(root)
		-- Tree object returned by parser.parse()
		local tree = {
			root = function()
				return root
			end,
		}

		return {
			parse = function()
				return { tree }
			end,
		}
	end

	before_each(function()
		h.set_buffer({}, { filetype = "typescript" })

		restore_get_parser = nil
		package.loaded["rocketlog.treesitter"] = nil
		treesitter = require("rocketlog.treesitter")
	end)

	after_each(function()
		if restore_get_parser then
			restore_get_parser()
		end
		pcall(vim.cmd, "bwipeout!")
	end)

	it("finds insertion point for a simple expression statement", function()
		local program = new_node("program", 0, 0, 0, 0)
		local stmt = add_child(program, new_node("expression_statement", 0, 0, 0, 10))
		local ident = add_child(stmt, new_node("identifier", 0, 6, 0, 8))

		-- Always return the selected node for the requested range.
		program.named_descendant_for_range = function()
			return ident
		end

		local parser = make_parser_with_root(program)
		local restore = h.stub(vim.treesitter, "get_parser", function()
			return parser
		end)
		restore_get_parser = restore

		local target, err = treesitter.resolve_insertion({
			bufnr = 0,
			start_row = 0,
			start_col = 6,
			end_row = 0,
			end_col = 8,
		})

		assert.is_nil(err)
		assert.are.equal("after", target.mode)
		assert.are.equal(1, target.line)
		assert.are.equal("expression_statement", target.statement_type)
	end)

	it("finds insertion point for a multiline method chain", function()
		local program = new_node("program", 0, 0, 0, 0)
		local stmt = add_child(program, new_node("expression_statement", 0, 0, 2, 0))
		local call = add_child(stmt, new_node("call_expression", 0, 0, 2, 0))

		program.named_descendant_for_range = function()
			return call
		end

		local parser = make_parser_with_root(program)
		local restore = h.stub(vim.treesitter, "get_parser", function()
			return parser
		end)
		restore_get_parser = restore

		local target, err = treesitter.resolve_insertion({
			bufnr = 0,
			start_row = 1,
			start_col = 0,
			end_row = 1,
			end_col = 10,
		})

		assert.is_nil(err)
		assert.are.equal("after", target.mode)
		-- end_row=2 => 1-based line 3
		assert.are.equal(3, target.line)
	end)

	it("rejects selections in implicit arrow bodies", function()
		local program = new_node("program", 0, 0, 0, 0)
		local arrow = add_child(program, new_node("arrow_function", 0, 0, 0, 0))
		local expr_body = add_child(arrow, new_node("identifier", 0, 4, 0, 7))

		program.named_descendant_for_range = function()
			return expr_body
		end

		local parser = make_parser_with_root(program)
		local restore = h.stub(vim.treesitter, "get_parser", function()
			return parser
		end)
		restore_get_parser = restore

		local target, err = treesitter.resolve_insertion({
			bufnr = 0,
			start_row = 0,
			start_col = 4,
			end_row = 0,
			end_col = 7,
		})

		assert.is_nil(target)
		assert.are.equal("implicit_arrow_body", err)
	end)

	it("rejects selections in function parameter lists", function()
		local program = new_node("program", 0, 0, 0, 0)
		local fn = add_child(program, new_node("function_declaration", 0, 0, 4, 0))
		local params = add_child(fn, new_node("formal_parameters", 0, 10, 0, 20))
		add_child(fn, new_node("statement_block", 1, 0, 4, 0))

		program.named_descendant_for_range = function()
			return params
		end

		local parser = make_parser_with_root(program)
		local restore = h.stub(vim.treesitter, "get_parser", function()
			return parser
		end)
		restore_get_parser = restore

		local target, err = treesitter.resolve_insertion({
			bufnr = 0,
			start_row = 0,
			start_col = 12,
			end_row = 0,
			end_col = 13,
		})

		assert.is_nil(target)
		assert.are.equal("selection_in_function_header", err)
	end)

	it("returns nil or fallback signal when parser is unavailable", function()
		local restore = h.stub(vim.treesitter, "get_parser", function()
			error("no parser")
		end)
		restore_get_parser = restore

		local target, err = treesitter.resolve_insertion({
			bufnr = 0,
			start_row = 0,
			start_col = 0,
			end_row = 0,
			end_col = 0,
		})

		assert.is_nil(target)
		assert.are.equal("parser_unavailable", err)
	end)

	it("handles malformed syntax without crashing", function()
		local program = new_node("program", 0, 0, 0, 0)

		local parser = {
			parse = function()
				error("parse failed")
			end,
		}

		local restore = h.stub(vim.treesitter, "get_parser", function()
			return parser
		end)
		restore_get_parser = restore

		local target, err = treesitter.resolve_insertion({
			bufnr = 0,
			start_row = 0,
			start_col = 0,
			end_row = 0,
			end_col = 0,
		})

		assert.is_nil(target)
		assert.are.equal("parse_failed", err)
	end)
end)

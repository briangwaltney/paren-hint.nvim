local parens = {
	[")"] = "(",
	["}"] = "{",
	["]"] = "[",
}

-- Trim the whitespace from the beginning and end of a string
-- @param s string: the string to trim
-- @return string: the trimmed string
local function trim(s)
	return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local M = {}
M.namespace = vim.api.nvim_create_namespace("paren-hint")

-- Default options
M.default_opts = {
	-- Include the opening paren in the ghost text
	include_paren = true,

	-- Show ghost text when cursor is anywhere on the line that includes the close paren rather just when the cursor is on the close paren
	anywhere_on_line = true,
	-- Show the ghost text when the opening paren is on the same line as the close paren
	show_same_line_opening = false,

    -- Start the ghost text with a comment string (Ex: "-- " for Lua, "// " for JS)
    start_with_comment = false,

	-- style of the ghost text using highlight group
	-- :Telescope highlights to see the available highlight groups if you have telescope installed
	highlight = "Comment",

	-- excluded filetypes (copied from indent-blankline)
	excluded_filetypes = {
		"lspinfo",
		"packer",
		"checkhealth",
		"help",
		"man",
		"gitcommit",
		"TelescopePrompt",
		"TelescopeResults",
		"",
	},

	-- excluded buftypes (copied from indent-blankline)
	excluded_buftypes = {
		"terminal",
		"nofile",
		"quickfix",
		"prompt",
	},
}

M.opts = M.default_opts

-- Setup the plugin
M.setup = function(opts)
	M.opts = vim.tbl_extend("force", M.default_opts, opts or {})
end

-- Check if plugin should be enabled for the current file type
-- @return boolean: true if treesitter is active
M.is_active_file_type = function()
	local file_type = vim.bo.filetype
	local buftype = vim.bo.buftype
	return not vim.tbl_contains(M.opts.excluded_filetypes, file_type)
		and not vim.tbl_contains(M.opts.excluded_buftypes, buftype)
end

-- Add the ghost text when the cursor is moved
vim.api.nvim_create_autocmd("CursorMoved", {
	pattern = "*",
	callback = function()
		if M.is_active_file_type() then
			M.delete_ghost_text()
			M.add_ghost_text()
		end
	end,
})

-- Delete the ghost text when entering insert mode
vim.api.nvim_create_autocmd("InsertEnter", {
	pattern = "*",
	callback = function()
		if M.is_active_file_type() then
			M.delete_ghost_text()
		end
	end,
})

-- Check if the character is a white space
-- @param char string: the character to check
-- @return boolean: true if the character is a white space
local function isWhiteSpace(char)
	return char == " " or char == "\t"
end

-- Get the line number, column, and paren type of the close paren
-- @return number, number, string: the line number, column, and char of the close paren
local get_close_paren = function()
	local lineNum = vim.api.nvim_win_get_cursor(0)[1] - 1
	local cur_col = vim.api.nvim_win_get_cursor(0)[2] + 1
	local lineContent = vim.api.nvim_get_current_line()
	if cur_col > #lineContent then
		return
	end
	local char = string.sub(lineContent, cur_col, cur_col)
	if parens[char] ~= nil or not M.opts.anywhere_on_line then
		return lineNum, cur_col, char
	end
	for i = 1, #lineContent do
		local char_in_line = string.sub(lineContent, i, i)
		if parens[char_in_line] ~= nil then
			cur_col = i
			char = char_in_line
		end
	end
	return lineNum, cur_col, char
end

-- Get the function name from the line
-- @param lineCol number: the column of the last character of the function name
-- @param lineContent string: the content of the line
-- @return string: the function name
local get_func_name = function(lineCol, lineContent)
	local cut_point = lineCol - 1
	if M.opts.include_paren then
		cut_point = cut_point + 1
	end
	return trim(string.sub(lineContent, 0, cut_point))
end

-- Keep track of the current commentstring
local commentStr = ""

-- Add the ghost text to the buffer when the cursor is on a close paren variation.
-- If there is a space before the open paren, the ghost text will show everything preceding the open paren on the line.
M.add_ghost_text = function()
	local bufnr = vim.api.nvim_get_current_buf()
	local closeLineNum, closeCol, close_paren = get_close_paren()
	if close_paren == nil then
		return
	end
	local current_line_num = vim.api.nvim_win_get_cursor(0)[1] - 1

    -- Update the comment string if it's not already set
    if string.len(commentStr) < 1 then
        commentStr = vim.api.nvim_buf_get_option(0, "commentstring")
    end

	local text = ""
	local open_paren = parens[close_paren]
	local depth = 1
	local open_line_num = closeLineNum

	for line = closeLineNum, 0, -1 do
		if text ~= "" then
			break
		end

		local lineContent = vim.api.nvim_buf_get_lines(bufnr, line, line + 1, false)[1]
		local startCol = #lineContent
		if line == closeLineNum then
			startCol = closeCol - 1
		end

		for lineCol = startCol, 1, -1 do
			local lineChar = string.sub(lineContent, lineCol, lineCol)
			if lineChar == close_paren then
				depth = depth + 1
			elseif lineChar == open_paren then
				depth = depth - 1
				if depth == 0 then
					open_line_num = line
					if M.opts.start_with_comment then
						text = string.format(commentStr, get_func_name(lineCol, lineContent))
					else
						text = get_func_name(lineCol, lineContent)
					end
					break
				end
			end
		end
	end

	if not M.opts.show_same_line_opening and open_line_num == current_line_num then
		return
	end

	vim.api.nvim_buf_set_extmark(bufnr, M.namespace, closeLineNum, 0, {
		virt_text = { { text, M.opts.highlight } },
	})
end

-- Delete the ghost text from the buffer
M.delete_ghost_text = function()
	local bufnr = vim.api.nvim_get_current_buf()
	vim.api.nvim_buf_clear_namespace(bufnr, M.namespace, 0, -1)
end

return M

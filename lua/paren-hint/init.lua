local M = {}

local function is_treesitter_active()
	local filetype = vim.bo.filetype
	local parsers = require("nvim-treesitter.parsers")
	local installed_parsers = parsers.get_parser_configs()
	if installed_parsers[filetype] then
		return true
	end
	return false
end

-- Check if the character is a white space
-- @param char string: the character to check
-- @return boolean: true if the character is a white space
local function isWhiteSpace(char)
	return char == " " or char == "\t"
end

vim.api.nvim_create_autocmd("CursorMoved", {
	pattern = "*",
	callback = function()
		if is_treesitter_active() then
			M.delete_ghost_text()
			M.add_ghost_text()
		end
	end,
})

M.setup = function() end

M.namespace = vim.api.nvim_create_namespace("paren-hint")

local parens = {
	[")"] = "(",
	["}"] = "{",
	["]"] = "[",
}

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
	if parens[char] == nil then
		return nil, nil, nil
	end
	return lineNum, cur_col, char
end

-- Get the function name from the line
-- @param lineCol number: the column of the last character of the function name
-- @param lineContent string: the content of the line
-- @return string: the function name
local get_func_name = function(lineCol, lineContent)
	local text = ""
	for func_col = lineCol - 1, 0, -1 do
		local func_c = string.sub(lineContent, func_col, func_col)
		if func_col == lineCol - 1 and func_c == " " then
			text = string.sub(lineContent, 0, lineCol - 1)
			break
		end
		if isWhiteSpace(func_c) or func_col == 0 then
			text = string.sub(lineContent, func_col + 1, lineCol - 1)
			break
		end
	end
	return text
end

M.add_ghost_text = function()
	local bufnr = vim.api.nvim_get_current_buf()
	local closeLineNum, closeCol, char = get_close_paren()
	if char == nil then
		return
	end

	local text = ""
	local open_paren = parens[char]
	local close_paren = char
	local depth = 1

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
					text = get_func_name(lineCol, lineContent)
					break
				end
			end
		end
	end

	vim.api.nvim_buf_set_extmark(bufnr, M.namespace, closeLineNum, 0, {
		virt_text = { { text, "comment" } },
	})
end

M.delete_ghost_text = function()
	local bufnr = vim.api.nvim_get_current_buf()
	vim.api.nvim_buf_clear_namespace(bufnr, M.namespace, 0, -1)
end

return M

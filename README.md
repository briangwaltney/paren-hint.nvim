# paren-hint.nvim

## Purpose

Some of the libraries I use have a lot of nested parentheses. This makes it hard to see where the parentheses start. This plugin adds a ghost text to the right of the cursor that shows the text preceding the opening parentheses. This makes it easier to see where the parentheses start and where you are in the nesting.

![Example of Go code showing the ghost text](./goSS.jpg)
![Example of js code showing the ghost text](./jsSS.jpg)

## Installation

Add `"briangwaltney/paren-hint.nvim"` to your preferred package manager.

Lazy example

_All options are optional and defaults are shown below_

```lua
{
    "briangwaltney/paren-hint.nvim",
    lazy = false,
    config = function()
        -- you can create a custom highlight group for the ghost text with the below command.
        -- change the `highlight` option to `parenhint` if you use this method.
        -- vim.api.nvim_exec([[ highlight parenhint guifg='#56633E' ]], false)
        require("paren-hint").setup({
            -- Include the opening paren in the ghost text
            include_paren = true,

            -- Show ghost text when cursor is anywhere on the line that includes the close paren rather just when the cursor is on the close paren
            anywhere_on_line = true,

            -- show the ghost text when the opening paren is on the same line as the close paren
            show_same_line_opening = false,

            -- style of the ghost text using highlight group
            -- :Telescope highlights to see the available highlight groups if you have telescope installed
            highlight = "Comment",

            -- excluded filetypes
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
            -- excluded buftypes
            excluded_buftypes = {
                "terminal",
                "nofile",
                "quickfix",
                "prompt",
            },
        })
    end,
},
```

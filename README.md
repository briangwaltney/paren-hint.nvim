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
    dependencies = {
        "nvim-treesitter/nvim-treesitter",
    },
    config = function()
        require("paren-hint").setup({
            include_paren = true, -- Include the opening paren in the ghost text
        })
    end,
},
```

# tree-climber.nvim

Plugin for easy navigation around the syntax-tree produced by the treesitter that also works in comments and multi-language files!

It provides 4 basic motions: jump to next/previous sibling in the tree, jump to parent, and jump to child, as well as the ability to swap neighbouring nodes.
It also provides a node selection method that works similar to other text-object selections, hence the proposed mapping 'in' = "inner node".

For convenience 'tree-climber.nvim' squashes parents with a single child together and tries to preserve your tree depth between jumps so that you can always return from where you started.

### Motivation

It is actually quite surprising that this functionality is not provided by the treesitter itself.
The memorable alternatives are:
 * [nvim-treesitter-textobjects](https://github.com/nvim-treesitter/nvim-treesitter-textobjects) allows jumping in some filetypes to predefined node types, but each type requires its own keymap, whereas 'tree-climber.nvim' allows jumping over abstract treesitter trees.
 * [syntax-tree-surfer](https://github.com/ziontee113/syntax-tree-surfer) has a very similar functionality, but unfortunately does not support jumping over comments and across multi-language files.

### Installation

Load 'tree-climber.nvim' as any other neovim plugin using your favourite package manager.

The plugin provides 8 functions, that can be mapped by the user: `goto_next()`, `goto_prev()`, `goto_parent()`, `goto_child()`, `swap_next()`, `swap_prev()`,`select_node()` and `highlight_node()`.
Suggested mapping for easy copy-pasting:
```
local keyopts = { noremap = true, silent = true }
vim.keymap.set({'n', 'v', 'o'}, 'H', require('tree-climber').goto_parent, keyopts)
vim.keymap.set({'n', 'v', 'o'}, 'L', require('tree-climber').goto_child, keyopts)
vim.keymap.set({'n', 'v', 'o'}, 'J', require('tree-climber').goto_next, keyopts)
vim.keymap.set({'n', 'v', 'o'}, 'K', require('tree-climber').goto_prev, keyopts)
vim.keymap.set({'v', 'o'}, 'in', require('tree-climber').select_node, keyopts)
vim.keymap.set('n', '<c-k>', require('tree-climber').swap_prev, keyopts)
vim.keymap.set('n', '<c-j>', require('tree-climber').swap_next, keyopts)
vim.keymap.set('n', '<c-h>', require('tree-climber').highlight_node, keyopts)
```

### Configuration

Each function optionally accepts a table with a configuration, for example, `goto_next({ skip_comments = true})`.

The available options so far are:
* `skip_comments` (boolean) - ignore comment nodes as if they were not there at all (default: false)
* `highlight` (boolean) - When moving using the `goto_*()` functions, briefly highlight the new node (default: false)
* `timeout` (number) - When highlighting, the time in ms before highlight is cleared (default: 150)
* `on_macro` (boolean) - when `highlight` is true, highlight nodes even when executing a macro (default: false)
* `higroup` (string) - the highlight group to use for highlighting (default: `'IncSearch'`)

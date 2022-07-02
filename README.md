# tree-climber.nvim

Plugin for easy navigation around the syntax-tree produced by the treesitter that also works in comments and multi-language files!

It provides 4 basic motions: jump to next/previous sibling in the tree, jump to parent, and jump to child, as well as the ability to swap neighbouring nodes.

For convenience 'tree-climber.nvim' squashes parents with a single child together and tries to preserve your tree depth between jumps so that you can always return from where you started.

### Motivation

It is actually quite surprising that this functionality is not provided by the treesitter itself.
The memorable alternatives are:
 * [nvim-treesitter-textobjects](https://github.com/nvim-treesitter/nvim-treesitter-textobjects) allows jumping in some filetypes to predefined node types, but each type requires its own keymap, whereas 'tree-climber.nvim' allows jumping over abstract treesitter trees.
 * [syntax-tree-surfer](https://github.com/ziontee113/syntax-tree-surfer) has a very similar functionality, but unfortunately does not support jumping over comments and across multi-language files.

### Installation

Load 'tree-climber.nvim' as any other neovim plugin using your favourite package manager.

The plugin provides 6 functions, that can be mapped by the user: `goto_next()`, `goto_prev()`, `goto_parent()`, `goto_child()`, `swap_next()` and `swap_prev()`.
Suggested mapping for easy copy-pasting:
```
local keyopts = { noremap = true, silent = true }
vim.keymap.set({'n', 'v', 'o'}, 'H', require('tree-climber').goto_parent, keyopts)
vim.keymap.set({'n', 'v', 'o'}, 'L', require('tree-climber').goto_child, keyopts)
vim.keymap.set({'n', 'v', 'o'}, 'J', require('tree-climber').goto_next, keyopts)
vim.keymap.set({'n', 'v', 'o'}, 'K', require('tree-climber').goto_prev, keyopts)
vim.keymap.set('n', '<c-k>', require('tree-climber').swap_prev, keyopts)
vim.keymap.set('n', '<c-j>', require('tree-climber').swap_next, keyopts)
```

### Configuration

Each motion and swap function optionally accepts a table with a configuration, for example, `goto_next({ skip_comments = true})`.
The only available option so far is:
* `skip_comments` (boolean) - ignore comment nodes as if they were not there at all (default: false) - 

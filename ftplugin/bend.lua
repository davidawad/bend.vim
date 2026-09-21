-- ftplugin/bend.lua -- Neovim-only tree-sitter activation for Bend 2.
--
-- Classic Vim never autoloads a `.lua` ftplugin, so this file is invisible
-- to it; plain-Vim users get only syntax/bend.vim + indent/bend.vim (see
-- README.md's "Plain Vim" install section). Neovim users additionally get
-- this, which starts native tree-sitter highlighting IF the `bend2` parser
-- has been installed (see README.md's "Neovim" install section) -- it is a
-- silent no-op otherwise, so simply having this plugin on the runtimepath
-- without having built the parser yet does not error.
--
-- The internal parser/language name is `bend2` (not `bend`) because
-- nvim-treesitter's own parser list may already contain an abandoned
-- Bend-1-syntax grammar named `bend` -- see README.md for the full
-- reasoning. `vim.treesitter.language.register` maps this buffer's
-- `bend` filetype to that `bend2` language for the query/highlighter
-- lookup.
local ok_register = pcall(vim.treesitter.language.register, 'bend2', 'bend')
if ok_register then
  pcall(vim.treesitter.start)
end

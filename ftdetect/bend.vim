" ftdetect/bend.vim -- classic-Vim-compatible filetype detection for Bend 2.
" Works in plain Vim and in Neovim; Neovim additionally reads
" ftdetect/bend.lua (if present) -- there isn't one here on purpose, this
" single autocommand is the only filetype-detection source this plugin
" ships, so both editors agree on the same `bend` filetype name.
au BufRead,BufNewFile *.bend setfiletype bend

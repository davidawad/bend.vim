" syntax/bend.vim -- classic regex-based syntax highlighting for Bend 2.
" Works in plain Vim (no tree-sitter, no Lua) and in Neovim when the
" tree-sitter parser isn't installed/active. See README.md for how this
" relates to the tree-sitter highlights.scm layer.

if exists("b:current_syntax")
  finish
endif

" ---------------------------------------------------------------------
" Comments: line `# ...` and nested block `#{ ... #}`.
"
" Vim's `contains=bendBlockComment` on the region's own name gives it
" ordinary (non-recursive-aware, but self-referential) nesting support --
" good enough for the common case; it does not replicate the real
" compiler's additional rule that every continuation line of a multi-line
" block comment must itself start with `#` (empirically confirmed against
" real Bend 2.0.22 -- see README Known Limitations; the tree-sitter
" grammar's scanner.c documents the same tradeoff in more detail).
" ---------------------------------------------------------------------

syntax match bendComment "#.*$" contains=@Spell
syntax region bendBlockComment start="#{" end="#}" contains=bendBlockComment,@Spell

" ---------------------------------------------------------------------
" Strings and characters
" ---------------------------------------------------------------------

syntax region bendString start=+"+ skip=+\\\\\|\\"+ end=+"+ contains=@Spell
syntax match bendChar "'\(\\.\|[^'\\]\)'"

" ---------------------------------------------------------------------
" Keywords
" ---------------------------------------------------------------------

syntax keyword bendKeyword def law type is match case do return for exs where import as
syntax match bendUnsafe "@unsafe"
syntax keyword bendStorageType Type Data Kind Quant

" ---------------------------------------------------------------------
" Literals
" ---------------------------------------------------------------------

syntax match bendNumber "\<[0-9]\+n\?\>"
syntax match bendFloat "\<[0-9]\+\.[0-9]\+\>"
syntax match bendQuantity "&[012]\>"
syntax match bendHole "?\w\+"

" ---------------------------------------------------------------------
" `def NAME` / `law NAME` -- the binding being introduced.
" Uppercase-leading identifiers -- types and constructors everywhere in
" real Bend source (`Nat`, `U32`, `Cons`, a user's own `type` names).
" ---------------------------------------------------------------------

syntax match bendFunctionName "\%(\<def\>\|\<law\>\)\s\+\zs[a-zA-Z_][a-zA-Z0-9_.]*"
syntax match bendType "\<[A-Z][a-zA-Z0-9_]*\>"

" ---------------------------------------------------------------------
" Links
" ---------------------------------------------------------------------

highlight default link bendComment Comment
highlight default link bendBlockComment Comment
highlight default link bendString String
highlight default link bendChar Character
highlight default link bendKeyword Keyword
highlight default link bendUnsafe PreProc
highlight default link bendStorageType Type
highlight default link bendNumber Number
highlight default link bendFloat Float
highlight default link bendQuantity Constant
highlight default link bendHole Todo
highlight default link bendFunctionName Function
highlight default link bendType Type

let b:current_syntax = "bend"

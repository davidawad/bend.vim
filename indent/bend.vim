" indent/bend.vim -- classic indentexpr for Bend 2 (works in plain Vim too).
"
" Bend 2's blocks are Python-shaped off-side blocks, same as bend-mode.el's
" own Emacs indentation. This is deliberately the simplest-correct v1: copy
" the previous non-blank line's indent, add one `shiftwidth()` after a line
" whose (comment-stripped) text ends in `:`. It does not attempt smart
" dedent (aligning a new `case` back with an earlier sibling) -- see
" README.md's Roadmap.

if exists("b:did_indent")
  finish
endif
let b:did_indent = 1

setlocal indentexpr=BendIndent()
setlocal indentkeys=!^F,o,O
setlocal nosmartindent
setlocal noautoindent

if exists("*BendIndent")
  finish
endif

function! BendIndent() abort
  let l:prevlnum = prevnonblank(v:lnum - 1)
  if l:prevlnum == 0
    return 0
  endif

  let l:prevline = getline(l:prevlnum)
  " Strip a trailing `# ...` line comment before checking for `:` -- a
  " comment-only previous line never itself triggers an indent increase.
  let l:stripped = substitute(l:prevline, '#.*$', '', '')
  let l:indent = indent(l:prevlnum)

  if l:stripped =~ ':\s*$'
    return l:indent + shiftwidth()
  endif

  return l:indent
endfunction

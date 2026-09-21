# AGENTS.md -- tree-sitter-bend2

Standalone, publishable tree-sitter grammar and editor plugin for Bend 2
(https://github.com/bendlang/bend). Two independent layers live in this one
repo: a tree-sitter grammar (`grammar.js`, `src/scanner.c`) with Neovim
wiring (`queries/`, `ftplugin/bend.lua`), and a classic regex-based Vim
plugin (`syntax/bend.vim`, `indent/bend.vim`) that needs neither
tree-sitter nor Lua and works in plain Vim too. `ftdetect/bend.vim` is
shared by both.

## For agents

- Read `README.md` first; it is the complete feature, install, and
  known-limitations reference.
- Regenerate the parser after any `grammar.js` or `src/scanner.c` change:
  `tree-sitter generate`, then `tree-sitter test` (corpus in
  `test/corpus/`), then `tree-sitter parse examples/*.bend` and confirm
  zero `(ERROR)` nodes before considering a change done.
- `src/scanner.c`'s file header explains the external-scanner design in
  full (indentation NEWLINE/INDENT/DEDENT tracking, nested `#{ #}` block
  comments) -- read it before touching the scanner; it also documents a
  non-obvious tree-sitter GLR fact that the fix history depended on:
  mutating scanner state before a `false` return is not reliably observed
  on a later call (tree-sitter can revive a different parse version from
  an earlier *successful* checkpoint), which is why every state
  transition that must persist happens on a `true`-returning path.
- The `examples/*.bend` files are real, `bend --check-only`-verified Bend
  2.0.22 source (six of them are the task's own authoritative acceptance
  fixtures; three more were added for corpus breadth -- block comments,
  templates/`@unsafe`/holes, a foreign effect def). Any new corpus
  addition should be similarly verified against a real `bend` binary
  before being trusted, not just eyeballed as "looks right".
- Known, deliberately out-of-scope limitations (multi-line infix
  expression continuation, standalone comment lines swallowed by the
  indentation scanner in a couple of narrow positions, no `locals.scm`/
  `indents.scm`) are documented in README.md's Roadmap -- don't be
  surprised by them, and don't silently "fix" them without updating that
  section to match reality.
- Zero references to the owner's dotfiles are allowed here -- the repo
  must remain publishable as-is.
- Authorized: david, swe.

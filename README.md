# tree-sitter-bend2

A [tree-sitter](https://tree-sitter.github.io/tree-sitter/) grammar for
[Bend 2](https://github.com/bendlang/bend), a dependently typed, affine,
Python-shaped functional language whose compiler targets native CPU,
Metal/CUDA and JS -- plus a Neovim/Vim plugin built on top of it.

Bend 2 is a fresh rewrite: the compiler repo now belongs entirely to Bend 2,
and the editor ecosystem that existed for Bend 1
([LaBatata101/tree-sitter-bend](https://github.com/LaBatata101/tree-sitter-bend),
[SergioBonatto/bend-vim](https://github.com/SergioBonatto/bend-vim)) targets
the old syntax and does not apply. As of 2.0.22, Bend 2 itself ships only a
Sublime Text grammar (for the docs site). Neither version has ever had
tree-sitter or Neovim/Vim support before this package, as far as could be
found (confirmed via GitHub search this project's development session). It
is a sibling effort to
[bend-mode.el](https://github.com/davidawad/bend-mode.el) (an Emacs major
mode for the same language) -- same spirit, different editor, no shared
code.

## What it does

This repo has **two independent layers**. Nothing here is Neovim-only --
plain Vim gets real syntax highlighting and indentation with no tree-sitter
and no Lua required at all.

1. **Classic Vim layer** (`ftdetect/bend.vim`, `syntax/bend.vim`,
   `indent/bend.vim`) -- ordinary regex-based `:syntax match`/`:syntax
   region` highlighting and a simple `indentexpr`. Works in **plain Vim
   and Neovim alike**, with zero dependencies beyond the editor itself.
2. **Tree-sitter layer** (`grammar.js`, `src/scanner.c`,
   `queries/highlights.scm`, `ftplugin/bend.lua`) -- a real parser with
   accurate, structural highlighting. **Neovim only** (tree-sitter itself
   is a Neovim built-in; vanilla Vim has no equivalent), additive on top
   of the classic layer, not a replacement for it.

Covered syntax (both layers, to the extent each is capable of expressing
it): line comments (`# ...`) and nested block comments (`#{ ... #}`,
arbitrary nesting depth in the tree-sitter grammar -- see Known
Limitations for the one real-compiler rule it doesn't additionally
enforce), strings, char literals, all reserved keywords (`def law type is
match case do return for exs where import as`), `@unsafe`, the
kind-former keywords (`Type Data Kind Quant`), `def NAME`/`law NAME` as a
function name, uppercase type/constructor identifiers, numeric literals
(`U32`, `F32`, `Nat` with its `n` suffix), quantity markers (`&0 &1 &2`),
and `?hole`/`?TODO` goals.

The tree-sitter grammar additionally parses (with real structure, not
just highlighting): the full top-level (`import`, `type`, `def`, `law`,
`@unsafe def`, foreign-effect defs), statements (`let`, destructuring
`let`, parallel `let`, array writes, `match`/`case`, `do` blocks with
`bind`/`let`/`return`), the full pattern grammar (`Nat` successor
patterns, cons, tuple, constructor, wildcard), and the type/term grammar
(function/pair/either/dependent/equality types, lambdas, calls, templates,
arrays, rewrites `%e : P`, holes).

## Internal parser/language name

The Neovim `filetype` for a `*.bend` file is `bend` (set by
`ftdetect/bend.vim`, shared by both layers). The tree-sitter **language**
this grammar registers itself as is `bend2`, not `bend` -- deliberately,
in case nvim-treesitter's own built-in parser list ever gains an entry
named `bend` from some future revival of the abandoned Bend-1 effort.
`ftplugin/bend.lua` bridges the two with
`vim.treesitter.language.register('bend2', 'bend')`.

## Install

Bend 2 itself, if you want to actually run files (not required just for
editing):

```sh
curl -fsSL https://bend-lang.com/install.sh | sh
# review the script before piping it to sh if you'd rather not take that on faith
export PATH="$HOME/.bend/bin:$PATH"
```

### Plain Vim (or Neovim without tree-sitter)

Clone this repo onto your runtimepath -- e.g. with a plugin manager:

```vim
" vim-plug
Plug 'davidawad/tree-sitter-bend2'
```

or manually, Vim 8+ native packages:

```sh
mkdir -p ~/.vim/pack/plugins/start
git clone https://github.com/davidawad/tree-sitter-bend2 \
  ~/.vim/pack/plugins/start/tree-sitter-bend2
```

That alone gets you filetype detection, `syntax/bend.vim` highlighting,
and `indent/bend.vim` indentation for `*.bend` files -- no build step, no
tree-sitter, no Lua.

### Neovim (adds real tree-sitter parsing/highlighting on top)

1. Install the plugin the same way as above (any plugin manager, or a
   native package under `~/.config/nvim/pack/plugins/start/`).
2. Build the parser (requires a C compiler and the `tree-sitter` CLI --
   `cargo install tree-sitter-cli` or `npm install -g tree-sitter-cli`):

   ```sh
   cd ~/.config/nvim/pack/plugins/start/tree-sitter-bend2  # or wherever step 1 put it
   tree-sitter generate   # only needed if you edited grammar.js/scanner.c
   tree-sitter build -o bend2.so
   ```

3. Register the compiled parser. With
   [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
   installed, add to your config:

   ```lua
   require('nvim-treesitter.parsers').get_parser_configs().bend2 = {
     install_info = {
       -- Update this URL once the repo is published; a local checkout
       -- path also works here for now, e.g. during development.
       url = 'https://github.com/davidawad/tree-sitter-bend2',
       files = { 'src/parser.c', 'src/scanner.c' },
       branch = 'main',
     },
     filetype = 'bend',
   }
   ```

   then `:TSInstall bend2` (this re-clones and rebuilds from the `url`
   above, so step 2's manual build isn't needed once this is wired up).

   Without nvim-treesitter, the manual equivalent of `:TSInstall` is
   exactly steps 1-2 above plus telling Neovim where to find the `.so`:

   ```lua
   vim.treesitter.language.add('bend2', { path = '/path/to/tree-sitter-bend2/bend2.so' })
   ```

   `ftplugin/bend.lua` (shipped in this repo, loads automatically once the
   plugin is on your runtimepath) then registers the `bend` filetype
   against the `bend2` language and starts native highlighting for you --
   it is a silent no-op if the parser isn't installed yet, so having this
   plugin on your runtimepath without having built the parser does not
   error, it just falls back to the classic `syntax/bend.vim` layer.

## Testing / verification

```sh
tree-sitter generate               # regenerate src/parser.c from grammar.js
tree-sitter test                   # run test/corpus/*.txt
tree-sitter parse examples/*.bend  # zero (ERROR) nodes on all 9 real, compiler-verified files
```

All 9 files under `examples/` are real Bend 2 source, verified against the
actual installed `bend` 2.0.22 compiler (`bend FILE --check-only`) during
this repo's development -- not just plausible-looking syntax. Six of them
(`01`-`06`) are the authoritative acceptance fixtures this grammar was
built against; three more (`07`-`09`) were added for corpus breadth
(nested block comments, templates/`@unsafe`/tuple-destructure/holes, a
foreign-effect def).

## Known Limitations / Roadmap

- **Multi-line infix expressions are not supported.** Bend allows
  "Infix arithmetic can continue on the next line, including an operator
  at its start" (from the language's own documentation); this grammar's
  indentation-sensitive external scanner treats every physical newline as
  significant and does not suppress it inside an open expression the way
  e.g. tree-sitter-python suppresses newlines inside brackets. In
  practice this means a call/operator chain must fit on one logical line.
  Out of scope for v1; a real fix needs bracket/operator-aware newline
  suppression in `src/scanner.c`.
- **Standalone comment lines are sometimes absorbed as insignificant
  whitespace instead of becoming their own node.** This only happens in
  one narrow position: a comment used as the very first line of a
  freshly-opened block (right after a `:` that opens a `def`/`type`/
  `law`/`match`/`case`/`do` body). Comments between statements, and
  trailing comments after code on the same line, always get real
  `comment`/`block_comment` nodes and are highlighted normally. See
  `src/scanner.c`'s file header for exactly why (an inherent tradeoff of
  where tree-sitter's ordinary `extras` lexer versus this external
  scanner gets first refusal at a given position).
- **The real compiler's per-line-`#` rule for multi-line block comments
  is not enforced** -- this grammar accepts a superset (arbitrary nesting
  by simple `#{`/`#}` depth counting) rather than also requiring every
  continuation line to itself start with `#`. Since a grammar's job is to
  parse valid programs, not reject invalid ones, this is a safe
  simplification: every real multi-line block comment (which does follow
  the real rule) still parses correctly either way.
- **`locals.scm` and `indents.scm` are not implemented** -- only
  `highlights.scm`. Tree-sitter-driven local-variable-aware highlighting
  and indentation are both future work; `indent/bend.vim`'s classic
  `indentexpr` (copy the previous line's indent, `+1 shiftwidth()` after
  a line ending in `:`, no smart dedent) is the only indentation logic
  either layer currently has.
- **No smart dedent** in `indent/bend.vim` (aligning a new `case` back
  with an earlier sibling automatically, Python-mode-in-Vim style) --
  same tradeoff bend-mode.el's own Emacs indentation makes, stated there
  as "the current indentation is deliberately the simplest correct v1".

## License

MIT -- see [LICENSE](LICENSE).

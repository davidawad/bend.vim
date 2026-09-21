# bend.vim

Vim and Neovim support for [Bend 2](https://github.com/bendlang/bend), a
dependently typed, affine, Python-shaped functional language whose compiler
targets native CPU, Metal/CUDA and JS.

This repo is a **Vim plugin**. It ships an ordinary Vimscript layer
(`ftdetect`/`syntax`/`indent`) that gives both editors real highlighting and
indentation with **no build step and no dependencies**, and -- sitting *on
top* of that, Neovim-only -- real tree-sitter parsing whose parser is built
at install time from the grammar repo
[tree-sitter-bend2](https://github.com/davidawad/tree-sitter-bend2).

The grammar lives in its own repo because it has three consumers and none of
them is a Vim plugin: Helix fetches a grammar repo from `languages.toml`,
nvim-treesitter fetches one from a parser registry entry, and this plugin
builds a parser from it. This repo therefore commits **no** copy of the
grammar or its queries -- a committed copy is a copy that drifts.

Editor support for Bend 2: this plugin (Vim, Neovim),
[tree-sitter-bend2](https://github.com/davidawad/tree-sitter-bend2) (Helix,
nvim-treesitter, anything else tree-sitter), and
[bend-mode.el](https://github.com/davidawad/bend-mode.el) (Emacs).

## What you get, and what each layer needs

1. **Classic Vim layer** (`ftdetect/bend.vim`, `syntax/bend.vim`,
   `indent/bend.vim`) -- ordinary regex-based `:syntax match`/`:syntax
   region` highlighting plus a simple `indentexpr`. Works in **plain Vim and
   Neovim alike**, zero dependencies, nothing to build.
2. **Tree-sitter layer** (`ftplugin/bend.lua` + the parser built by
   `scripts/build-parser.sh`) -- accurate structural highlighting.
   **Neovim only** (tree-sitter is a Neovim built-in; vanilla Vim has no
   equivalent). Additive on top of the classic layer, not a replacement:
   if the parser is missing, this silently falls back to layer 1.

Covered syntax, in both layers to the extent each can express it: line
comments (`# ...`), nested block comments (`#{ ... #}`, arbitrary depth),
strings, char literals, all reserved keywords (`def law type is match case do
return for exs where import as`), `@unsafe`, the kind-former keywords (`Type
Data Kind Quant`), `def NAME`/`law NAME` as a function name, uppercase
type/constructor identifiers, numeric literals (`U32`, `F32`, `Nat` with its
`n` suffix), quantity markers (`&0 &1 &2`), and `?hole`/`?TODO` goals.

## Install

### vim-plug

```vim
" Plain Vim, or Neovim without a built parser -- classic layer only.
Plug 'davidawad/bend.vim', { 'branch': 'main' }

" Neovim, with the tree-sitter parser built at install time.
Plug 'davidawad/bend.vim', { 'branch': 'main', 'do': 'bash scripts/build-parser.sh' }
```

Then `:PlugInstall`. Two things in that line are load-bearing, and both fail
**silently** if you get them wrong:

- `{ 'branch': 'main' }` -- vim-plug checks out `master` by default and this
  repo's default branch is `main`, so a bare `Plug` line fails with
  `fatal: invalid reference: master`. The plugin directory is still created,
  which makes the breakage easy to miss: the `do` hook never runs, so there
  is no parser, so Neovim quietly drops to the classic layer.
- The `do` hook -- without it there is no `parser/bend2.so`, and Neovim
  searches the runtimepath for exactly `parser/<language>.so`. A `.so` at the
  repo root is never found.

`scripts/build-parser.sh` clones
[tree-sitter-bend2](https://github.com/davidawad/tree-sitter-bend2) at a
**pinned revision**, builds `parser/bend2.so`, and copies its
`queries/bend2/highlights.scm` into place. It needs the `tree-sitter` CLI and
a C compiler on `PATH`
(`cargo install tree-sitter-cli` or `npm i -g tree-sitter-cli`); if the CLI is
missing it says so and exits non-zero rather than half-installing. Both
outputs are gitignored build artifacts. Re-run it any time with
`bash scripts/build-parser.sh`; bump the grammar by editing `GRAMMAR_REV`
there.

### Native packages (no plugin manager)

```sh
git clone https://github.com/davidawad/bend.vim ~/.vim/pack/plugins/start/bend.vim
```

That is enough for the classic layer in both editors. For Neovim's
tree-sitter layer, additionally:

```sh
cd ~/.vim/pack/plugins/start/bend.vim && bash scripts/build-parser.sh
```

### nvim-treesitter instead of the `do` hook

If you already use nvim-treesitter, let *it* own the parser rather than both
managing `parser/bend2.so`, and install this plugin without the `do` hook:

```lua
require('nvim-treesitter.parsers').get_parser_configs().bend2 = {
  install_info = {
    url = 'https://github.com/davidawad/tree-sitter-bend2',
    files = { 'src/parser.c', 'src/scanner.c' },
    branch = 'main',
  },
  filetype = 'bend',
}
```

then `:TSInstall bend2`. Do not do both -- two managers writing the same
`parser/bend2.so` is a race, not redundancy.

## Internal parser/language name

The Neovim `filetype` for `*.bend` is `bend` (set by `ftdetect/bend.vim`,
shared by both layers). The tree-sitter **language** is `bend2`, not `bend`,
deliberately, in case nvim-treesitter's parser list ever gains a `bend` entry
from a revival of the abandoned Bend-1 grammar. `ftplugin/bend.lua` bridges
the two with `vim.treesitter.language.register('bend2', 'bend')`. Helix makes
the same bridge with `[[language]] name = "bend"` / `grammar = "bend2"`.

## Testing / verification

```sh
# classic layer: filetype, syntax and indent all load
vim -N --clean --cmd 'set runtimepath+=.' -c 'filetype plugin indent on' \
    -c 'syntax on' -c 'edit README.md' -c 'echo &filetype' -c 'qall!'

# tree-sitter layer: parser and queries must BOTH resolve by name
nvim --clean --headless \
  --cmd 'set runtimepath+=.' \
  -c 'lua print(vim.inspect(vim.api.nvim_get_runtime_file("parser/bend2.so", true)))' \
  -c 'lua print(vim.inspect(vim.treesitter.query.get_files("bend2", "highlights")))' \
  -c 'qall!'
```

Both `lua` lines must print a non-empty path list. Neither the grammar
failing to parse nor a missing `src/scanner.c` is what breaks here -- the
grammar is verified in
[tree-sitter-bend2](https://github.com/davidawad/tree-sitter-bend2)
(`tree-sitter test` 9/9, zero `(ERROR)` nodes on all 9 compiler-verified
examples). What breaks in *this* repo is discovery, which no grammar test
covers.

One trap worth knowing: a **headless** Neovim cannot prove highlighting
*renders*. It reports `highlighter_active=true` and applies zero highlight
extmarks, because highlighting is applied on window redraw. To actually
confirm drawing, open a `.bend` file in a real terminal with `:syntax off`
-- anything still colored is tree-sitter, since the classic layer is off.

## Known Limitations

Genuine grammar-level limitations (multi-line infix expressions, a
first-line-of-block comment edge case, block-comment rules not enforced,
missing `locals.scm`/`indents.scm`/`textobjects.scm`) are documented in
[tree-sitter-bend2's README](https://github.com/davidawad/tree-sitter-bend2),
because they are the grammar's, not this plugin's. The classic layer
additionally has **no smart dedent**: `indent/bend.vim` copies the previous
line's indent and adds one `shiftwidth()` after a line ending in `:`, and
does not align a new `case` back with an earlier sibling.

## Provenance

Written 2026-09-21 as the Vim/Neovim half of the Bend 2 editor-tooling gap,
alongside [bend-mode.el](https://github.com/davidawad/bend-mode.el) (Emacs).
Bend 2 as of 2.0.22 ships only a Sublime Text grammar, and the Bend-1-era
community tooling ([LaBatata101/tree-sitter-bend](https://github.com/LaBatata101/tree-sitter-bend),
[SergioBonatto/bend-vim](https://github.com/SergioBonatto/bend-vim)) targets
the old syntax and does not apply -- this is believed to be the first
tree-sitter/Vim/Neovim support either version of Bend has had. The grammar
was originally developed inside this repo and was extracted to
[tree-sitter-bend2](https://github.com/davidawad/tree-sitter-bend2) on
2026-09-21, where its commit history continues; this repo's history still
contains that development.

## License

MIT -- see [LICENSE](LICENSE).
#!/usr/bin/env bash
# build-parser.sh -- fetch the pinned Bend 2 grammar and build the Neovim parser.
#
# Run from the plugin root; vim-plug's `do` hook does exactly that. Produces
# two build artifacts, both gitignored, so the grammar has exactly one source
# of truth (davidawad/tree-sitter-bend2) and this repo commits no copy of it:
#
#   parser/bend2.so               -- what Neovim searches the runtimepath for,
#                                    by name. A bend2.so at the repo root is
#                                    never found, and the failure is silent.
#   queries/bend2/highlights.scm  -- the grammar's highlight queries. Neovim
#                                    resolves queries by language name, so they
#                                    must be under queries/<lang>/.
#
# Nothing here is Neovim-specific except that Neovim is the editor consuming
# the output; plain Vim ignores both files and uses syntax/bend.vim instead.
set -euo pipefail

GRAMMAR_REPO="https://github.com/davidawad/tree-sitter-bend2"
# Pinned on purpose. An unpinned grammar means `:PlugUpdate` can silently
# change how your files highlight, with no review. Bump deliberately.
GRAMMAR_REV="8ad225d157f7409b59c995a11a86908123b9b20c"

cd "$(dirname "${BASH_SOURCE[0]}")/.."

if ! command -v tree-sitter >/dev/null 2>&1; then
  echo "build-parser: the tree-sitter CLI is not on PATH." >&2
  echo "  install: cargo install tree-sitter-cli   (or: npm i -g tree-sitter-cli)" >&2
  echo "  then re-run: bash scripts/build-parser.sh" >&2
  exit 1
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

git clone --quiet --no-checkout "$GRAMMAR_REPO" "$tmp/grammar"
git -C "$tmp/grammar" checkout --quiet "$GRAMMAR_REV"

mkdir -p parser queries/bend2
tree-sitter build -o parser/bend2.so "$tmp/grammar"
cp "$tmp/grammar/queries/bend2/highlights.scm" queries/bend2/highlights.scm

echo "build-parser: wrote parser/bend2.so and queries/bend2/highlights.scm"
echo "build-parser: from $GRAMMAR_REPO @ ${GRAMMAR_REV:0:12}"
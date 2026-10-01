# Neovim config — reference

A minimal, LSP-first Neovim setup built for Go and Python. Plugin manager is
[lazy.nvim](https://github.com/folke/lazy.nvim); language servers are managed
by [mason.nvim](https://github.com/mason-org/mason.nvim). No frameworks
(LazyVim, NvChad, etc.) — every line in this config is one you (or this
session) wrote and can read.

## Layout

```
init.lua                    -- bootstraps lazy.nvim, loads vim-options + plugins
lua/vim-options.lua          -- core vim settings, leader key
lua/plugins.lua               -- empty; lazy.nvim auto-imports lua/plugins/*.lua
lua/plugins/
  lsp-config.lua              -- mason, mason-lspconfig, nvim-lspconfig, diagnostics, format-on-save
  completions.lua              -- nvim-cmp + LuaSnip
  telescope.lua                 -- fuzzy finder + fzf-native + ui-select
  tresetter.lua                  -- nvim-treesitter (syntax highlighting/indent)
  neo-tree.lua                    -- file explorer sidebar
  lualine.lua                      -- statusline
  catppuccin.lua                    -- colorscheme
  gitsigns.lua                       -- git gutter signs, hunk stage/reset, blame
  none-ls.lua                         -- stylua formatting for Lua files
  render-markdown.lua                  -- renders markdown in the buffer (headings, tables, code blocks)
  vim-tmux-navigator.lua                -- <C-h/j/k/l> across nvim splits and tmux panes
```

tmux's config lives outside this directory, at `~/.config/tmux/tmux.conf`.

`lazy.nvim` is told to load the whole `plugins` module (`require("lazy").setup("plugins")`
in `init.lua`); it globs every file under `lua/plugins/` automatically, so a
new file dropped in that directory is picked up with no other wiring needed.

## What's configured, and why

**Go** — `gopls` (LSP), with `gofumpt` and `staticcheck` turned on, plus inlay
hints for variable types, struct field names, and parameter names.
`golangci-lint` runs as a second LSP client (`golangci_lint_ls`) purely for
diagnostics. On save: imports are organized (unused ones dropped, missing
ones — for symbols already resolvable in your module — added, same as
`goimports`), then the file is formatted.

**Python** — two LSP clients: `pyright` for types/go-to-definition/hover, and
`ruff` for linting and formatting (`ruff`'s own hover is turned off so
pyright's richer one wins — that's the one asymmetric `on_attach` override in
the config). On save: imports are sorted/grouped (`isort`-equivalent — unlike
Go, unused imports are **not** auto-removed; that's a deliberate choice ruff
makes so it never silently deletes something you're mid-edit on), then the
file is formatted via ruff.

**Lua** — `lua_ls` for the language server, `stylua` (via none-ls) for
formatting. This is what formats *this config itself* on save.

**Completion** — `nvim-cmp`, sourced from the attached LSP client(s) first,
then snippets (LuaSnip + friendly-snippets), then open buffer words.

**Fuzzy finding** — Telescope, using the native `fzf` sorter (compiled via
`make` — this is why `telescope-fzf-native` has a `build` step) instead of
the slower pure-Lua one.

**Git** — gitsigns shows added/changed/removed lines in the gutter as you
edit, and can stage/reset/preview individual hunks or blame a line, all
without leaving the buffer.

**Colorscheme** — catppuccin (mocha flavour), with its integrations for cmp,
gitsigns, telescope, treesitter, and native LSP turned on so diagnostics,
completion menu icons, and picker UI all match the theme instead of falling
back to default highlight groups.

## Keybindings

Leader key is `<Space>`.

### Files & search (Telescope)
| Key | Action |
|---|---|
| `<C-p>` | Find files |
| `<leader>fg` | Live grep (search text across project) |
| `<leader>fb` | List open buffers |
| `<leader>fh` | Search help tags |
| `<C-n>` | Toggle file tree (Neo-tree), reveals current file |

### LSP (works in any Go/Python/Lua buffer with an attached server)
| Key | Action |
|---|---|
| `K` | Hover docs |
| `gd` | Go to definition |
| `gr` | List references |
| `gi` | Go to implementation |
| `<leader>rn` | Rename symbol (project-wide) |
| `<leader>ca` | Code action (quick fixes, refactors, `Add missing import`, etc.) |
| `<leader>e` | Show diagnostic under cursor in a float |
| `[d` / `]d` | Jump to previous / next diagnostic |
| `<leader>xx` | List every error/warning across all open buffers (quickfix list) |
| `<leader>gf` | Format buffer manually (also happens automatically on save) |

### Git (gitsigns)
| Key | Action |
|---|---|
| `]c` / `[c` | Jump to next / previous git hunk |
| `<leader>hs` | Stage hunk |
| `<leader>hr` | Reset hunk (discard change) |
| `<leader>hp` | Preview hunk diff |
| `<leader>hb` | Blame current line |

### Completion (insert mode, while `nvim-cmp` menu is open)
| Key | Action |
|---|---|
| `<C-Space>` | Trigger completion manually |
| `<CR>` | Confirm selected completion |
| `<C-e>` | Abort/close completion menu |
| `<C-f>` / `<C-b>` | Scroll docs preview down / up |

### Splits (windows)
Splits are built into Neovim; `splitright`/`splitbelow` make new ones open to
the right and below, like VS Code.
| Key | Action |
|---|---|
| `<C-w>v` / `<C-w>s` | Split side by side / below (or `:vs file` / `:sp file`) |
| `<C-v>` / `<C-x>` | In Telescope: open the selected file side by side / below |
| `s` / `S` | In Neo-tree: open the file side by side / below |
| `<C-h>` `<C-j>` `<C-k>` `<C-l>` | Move to the split left / down / up / right (continues into tmux panes) |
| `<C-w>=` | Make all splits equal size |
| `<C-w>>` / `<C-w><` | Wider / narrower (takes a count, e.g. `10<C-w>>`) |
| `<C-w>+` / `<C-w>-` | Taller / shorter |
| `<C-w>o` | Close all other splits |
| `<C-w>x` | Swap with the next split |
| `:q` / `<C-w>c` | Close this split |
| `<leader>tt` | Terminal in a split below; `<Esc><Esc>` returns to normal mode |

### Markdown (render-markdown)
| Key | Action |
|---|---|
| `:RenderMarkdown toggle` | Switch between rendered and raw markdown |

### tmux (`~/.config/tmux/tmux.conf`)
Every binding below starts with the prefix `<C-b>`: press it, release, then
press the key. The exception is `<C-h/j/k/l>`, which needs no prefix.

**Sessions** (one per project)
| Command / key | Action |
|---|---|
| `tmux new -s infra` | New named session |
| `tmux ls` | List sessions |
| `tmux attach -t infra` / `tmux a` | Reattach to a session / the last one |
| `prefix d` | Detach (everything keeps running) |
| `prefix s` | Pick a session or window from a list |
| `prefix $` | Rename the session |
| `tmux kill-session -t infra` | Kill a session |

**Windows** (like tabs)
| Key | Action |
|---|---|
| `prefix c` | New window (in the current directory) |
| `prefix 1`, `prefix 2`, … | Go to window 1, 2, … |
| `prefix n` / `prefix p` | Next / previous window |
| `prefix l` | Last window you were in |
| `prefix ,` | Rename the window |
| `prefix &` | Close the window |

**Panes** (splits inside a window)
| Key | Action |
|---|---|
| `prefix \|` / `prefix -` | Split side by side / below (in the current directory) |
| `<C-h>` `<C-j>` `<C-k>` `<C-l>` | Move between panes, and into nvim splits |
| `prefix H/J/K/L` | Resize (keep pressing to repeat), or drag the border with the mouse |
| `prefix z` | Zoom this pane to the full window / restore |
| `prefix !` | Move the pane into its own window |
| `prefix Space` | Cycle pane layouts |
| `prefix x` | Close the pane |

**Scrolling, copying, misc**
| Key | Action |
|---|---|
| Mouse wheel / `prefix [` | Scroll back (vim keys move in scroll mode) |
| `v`, `y`, `q` | In scroll mode: start selection, copy, leave |
| `prefix <C-l>` | Clear the shell (plain `<C-l>` moves to the right pane) |
| `prefix r` | Reload the tmux config |

A typical project layout: `tmux new -s infra`, window 1 runs `nvim .` (with
nvim splits for code), window 2 is split into `terraform plan` and a shell,
window 3 tails `docker compose logs -f`. `prefix d` to leave, `tmux a` to come
back to exactly that.

### Everything else is stock Neovim
This config doesn't remap core motions, so all of vim's native keys apply on
top of the above: `hjkl`, `w`/`b`/`e` word motions, `dd`/`yy`/`p`, `/` search,
`ciw`/`caw` (text objects), `.` (repeat), macros (`qa...q`, `@a`), marks
(`ma`, `` `a ``), the jumplist (`<C-o>`/`<C-i>`), `gg`/`G`, `%` (matching
bracket), visual block (`<C-v>`), and so on. If you don't already have these
under your fingers, that's the highest-leverage thing to drill — plugins are
a small multiplier on top of fast native motions, not a replacement for them.

## Day-to-day workflow

**Opening a project**: `cd` into a Go module (has `go.mod`) or a directory
with a `pyproject.toml`/`.git` before launching `nvim`, or open a file inside
one. LSP servers resolve their project root from these markers — outside of
one, gopls/pyright/ruff either won't attach or lose cross-file features.

**Saving**: just `:w` — formatting and import organization run automatically
via `BufWritePre`. There's no separate "format" step to remember for Go,
Python, or Lua.

**First time opening this config after a fresh clone**: launch `nvim`, let
`lazy.nvim` install everything (`:Lazy` to watch progress), then let mason
install `gopls`, `pyright`, `ruff`, `golangci_lint_ls`, `lua_ls`, and
`stylua` on the next launch (mason skips its auto-install step in headless
mode, so it runs on your first real interactive launch, not immediately).
Run `:Mason` to check status directly, or `:MasonInstall <tool>` to force one.

**Managing plugins**: `:Lazy` opens the plugin manager UI — `U` updates all,
`x` removes ones no longer in the spec, `L` shows the changelog. Plugin
versions are pinned in `lazy-lock.json`; commit that file so a `git pull`
elsewhere reproduces exact versions.

**Managing LSP servers/tools**: `:Mason` opens the tool manager UI. To add a
new language, add its lspconfig-registered name to `ensure_installed` in
`lua/plugins/lsp-config.lua`'s `mason-lspconfig` block, then add a
`vim.lsp.config["<name>"] = { capabilities = capabilities }` block and a
`vim.lsp.enable("<name>")` call, following the existing pattern.

**Checking LSP health**: `:LspInfo` shows attached clients for the current
buffer. `:checkhealth lsp` / `:checkhealth mason` catch most misconfigurations.

## Deliberately left out

These are common in "batteries-included" configs but were skipped here to
keep the setup minimal — add them individually if you find yourself wanting
them, they're one plugin file each:

- **which-key.nvim** — a popup listing available keybindings as you type a
  prefix. Skipped since this doc is the reference; add it if you'd rather
  have it in-editor.
- **nvim-autopairs** — auto-closes brackets/quotes. Pure preference, not a
  correctness thing.
- **Comment.nvim** — not needed: Neovim 0.10+ has built-in comment toggling
  on `gc` (operator, e.g. `gcc` for a line, `gcip` for a paragraph) using
  each filetype's comment syntax already.
- **conform.nvim + nvim-lint** — the more actively maintained,
  current-generation replacement for `none-ls`/`null-ls` (which is in
  maintenance mode). Not swapped in because `none-ls` still does the one
  thing it's asked to do here (stylua for Lua) correctly, and swapping it
  is a bigger change than a fix. Worth revisiting if you add more
  formatters/linters through it later, since `none-ls` wraps CLI tools
  awkwardly compared to `conform.nvim`'s direct model.
- **trouble.nvim** — a dedicated diagnostics/quickfix list UI. `<leader>e`
  and `[d`/`]d` cover the common case without it.


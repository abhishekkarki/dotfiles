# dotfiles — Neovim + tmux

A minimal, LSP-first Neovim setup for Go, Python, Lua, Terraform, Docker and
Markdown, plus a tmux config that shares navigation keys with it. Plugin manager is
[lazy.nvim](https://github.com/folke/lazy.nvim); language servers are managed
by [mason.nvim](https://github.com/mason-org/mason.nvim). No frameworks
(LazyVim, NvChad, etc.) — every line in this config is one you (or this
session) wrote and can read.

## Install (macOS or Linux)

```sh
git clone <this-repo-url> ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` is safe to rerun at any time; every step skips what is already
in place. It:

1. **Installs system dependencies.** On macOS it uses Homebrew (and asks for
   the Xcode Command Line Tools if they're missing). On Linux it uses apt, dnf
   or pacman for the basics, and downloads official builds of Neovim,
   tree-sitter, Node and Go into `~/.local` if the distro's versions are
   missing or too old (no root needed for those). On distros with glibc
   older than 2.39 (Ubuntu 22.04, Debian 12, RHEL 9) tree-sitter has no
   working prebuilt binary, so it is compiled with Rust (installed to
   `~/.cargo` via rustup; adds ~2 minutes once).
2. **Links the configs:** `~/.config/nvim` → `nvim/`, `~/.config/tmux` →
   `tmux/`. Anything already at those paths is moved to `*.bak.<timestamp>`,
   not deleted.
3. **Pre-installs everything nvim needs:** plugins at the exact versions in
   `nvim/lazy-lock.json`, the treesitter parsers, and all language servers
   and formatters (via `bootstrap.lua`). The first real `nvim` launch has
   nothing left to download.

Afterwards:
- On Linux, make sure `~/.local/bin` is on your `PATH` (the script warns if it isn't).
- Set your terminal font to a [Nerd Font](https://www.nerdfonts.com/), e.g.
  JetBrainsMono Nerd Font. Icons in the file tree, statusline and markdown
  rendering need it.
- `./install.sh --no-deps` skips step 1, for machines where you manage
  packages yourself.

**Requirements the script checks for:** Neovim ≥ 0.12, tree-sitter CLI ≥
0.26.1, git, make + a C compiler, curl, unzip, ripgrep, fd, tmux, Node ≥ 18
(pyright and the Docker servers run on it), Go ≥ 1.21 (gopls is built with
it), Python 3 with venv (ruff). Terraform and Docker themselves are **not**
installed. Completion and diagnostics work without them, but formatting
`.tf` files on save calls the `terraform` CLI, so install Terraform where
you want that.

## Layout

```
install.sh                  -- sets up a machine (see Install)
bootstrap.lua                -- headless nvim step of install.sh: parsers + Mason tools
tmux/tmux.conf                -- linked to ~/.config/tmux
nvim/                          -- linked to ~/.config/nvim
  init.lua                    -- bootstraps lazy.nvim, loads vim-options + plugins
  lazy-lock.json               -- pinned plugin versions
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

Because `~/.config/nvim` and `~/.config/tmux` are symlinks into this repo,
editing a config file *is* editing the repo; there is no copy step.

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

**Terraform** — `terraformls` for completion of resources and attributes,
hover docs, go-to-definition across modules and validation. `.tf` and
`.tfvars` files are formatted on save via `terraform fmt` (needs the
`terraform` CLI on `PATH`; without it, saving just skips formatting). Open the
project directory (`nvim .`) rather than a single file so it can see modules
and variables.

**Docker** — `dockerls` for Dockerfiles and `docker_compose_language_service`
for compose files. `compose.yaml`, `compose.yml` and `docker-compose*.yml`
are given the `yaml.docker-compose` filetype so the compose server attaches.

**Markdown** — render-markdown.nvim draws headings, lists, tables and code
blocks in the buffer. The line under the cursor (and insert mode) shows raw
text so editing is unaffected.

**Treesitter** — nvim-treesitter's `main` branch: parsers are compiled with
the `tree-sitter` CLI, and highlighting/indent are started per buffer by a
`FileType` autocmd in `tresetter.lua`. Any filetype without a parser falls
back to Neovim's regex highlighting.

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
| `<leader>fg` | Live grep: search text across the project, with preview |
| `<leader>fw` | Grep for the word under the cursor |
| `<leader>fb` | List open buffers |
| `<leader>fh` | Search help tags |
| `<C-n>` | Toggle file tree (Neo-tree), reveals current file |

### Searching for text
Search happens in Telescope, not the file tree (Neo-tree's `/` only filters
file *names*). Telescope uses `ripgrep`, so it respects `.gitignore`.

1. `<leader>fg`, then type the word. Results update as you type: matching
   lines on the left, the file around the selected match in the preview on
   the right.
2. `<C-n>` / `<C-p>` (or arrow keys) move through results; the preview follows.
3. `<CR>` opens the match, `<C-v>` / `<C-x>` open it in a split, `<C-t>` in a tab.
4. `<C-q>` sends **all** results to the quickfix list. Then `:copen` shows
   the list, and `:cnext` / `:cprev` walk through matches. Use this for
   "find every usage and fix each one".
5. `<Esc>` closes the picker.

`<leader>fw` skips the typing: it searches for the word under the cursor.
`<C-u>` / `<C-d>` scroll the preview.

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

**Fresh machine**: run `./install.sh` (see Install). If you skip it, nvim
still bootstraps itself on first launch, but you'll watch plugins, parsers
and servers download in the background. `:Mason` shows server status;
`:MasonInstall <tool>` forces one.

**Managing plugins**: `:Lazy` opens the plugin manager UI — `U` updates all,
`x` removes ones no longer in the spec, `L` shows the changelog. Plugin
versions are pinned in `lazy-lock.json`; commit that file so a `git pull`
elsewhere reproduces exact versions.

**Managing LSP servers/tools**: `:Mason` opens the tool manager UI. To add a
new language, add its lspconfig-registered name to `ensure_installed` in
`lua/plugins/lsp-config.lua`'s `mason-lspconfig` block, then add a
`vim.lsp.config["<name>"] = { capabilities = capabilities }` block and a
`vim.lsp.enable("<name>")` call, following the existing pattern. Then add
its parser to the `parsers` list in `lua/plugins/tresetter.lua`, and add both the
parser and the Mason package name to `bootstrap.lua` so `install.sh` sets it
up on other machines.

**Checking LSP health**: `:LspInfo` shows attached clients for the current
buffer. `:checkhealth lsp` / `:checkhealth mason` catch most misconfigurations.

## Standard workflow

### Working on a project

```sh
cd ~/code/my-infra
tmux new -s my-infra        # or `tmux a -t my-infra` if it already exists
nvim .
```

1. **Find your way in.** `<C-p>` for a file by name, `<leader>fg` for text,
   `<C-n>` for the tree. Use `gd` / `gr` to jump through definitions and
   references, and `<C-o>` to jump back.
2. **Lay out what you need.** Open related files side by side (`<C-v>` from
   Telescope, `s` from Neo-tree) and move between them with `<C-h/j/k/l>`.
3. **Edit and save.** `:w` formats and organizes imports. Diagnostics show
   inline; `<leader>xx` lists all of them, `<leader>ca` offers fixes.
4. **Run things next to the editor.** `<leader>tt` for a quick shell, or a
   tmux pane (`prefix |`) / window (`prefix c`) for long-running commands
   like `terraform plan`, tests or `docker compose logs -f`.
5. **Review and commit.** `]c` / `[c` walk your changes, `<leader>hp` previews
   a hunk, `<leader>hs` stages it, `<leader>hr` discards it. Commit from a
   shell pane with `git commit`.
6. **Leave.** `prefix d` detaches tmux; everything keeps running. `tmux a`
   brings it back exactly as it was.

### Keeping this repo in sync across machines

Edit the configs in place (they're symlinked), then commit like any repo:

```sh
cd ~/dotfiles
git status                      # see what you changed
git add -A && git commit -m "nvim: add rust support"
git push
```

On another machine:

```sh
cd ~/dotfiles
git pull
./install.sh                    # installs anything new; skips the rest
```

**Updating plugins** is deliberate, not automatic: `:Lazy update` in nvim
updates every plugin and rewrites `nvim/lazy-lock.json`. Try it for a bit,
then commit the lockfile. If an update breaks something, `git checkout
nvim/lazy-lock.json` and `:Lazy restore` puts every plugin back to the
committed versions. `:TSUpdate` rebuilds parsers after a treesitter update.
`:Mason` → `U` updates language servers.

### Expected `:checkhealth` warnings

These are informational, not problems:

- **mason:** `wget`, `cargo`, `luarocks`, `Composer`, `PHP`, `java`, `javac`,
  `julia` not available. Mason lists every installer it *could* use; none of
  the tools in this config need them.
- **vim.pack / lazy:** "found existing packages at …/site/pack/core" and
  "Lockfile is absent". That's Neovim's built-in package manager, which this
  config doesn't use (lazy.nvim does the job).
- **Linux only:** neo-tree's "`gio` not found" (it's only used for moving
  files to the trash), and Mason's "pip not available" (ruff is installed
  with `venv`, not pip). Over SSH or in a container without a display, the
  clipboard and locale/`infocmp` checks may also warn; they don't affect
  editing.
- **vim.lsp:** "Unknown filetype 'gotmpl'". gopls declares support for Go
  templates; harmless unless you edit them.

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


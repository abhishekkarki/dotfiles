#!/usr/bin/env bash
# Sets up this repo on macOS or Linux: installs what nvim and tmux need, links
# the configs into ~/.config, then pre-installs plugins, treesitter parsers and
# language servers so the first real nvim launch has nothing left to do.
# Safe to rerun; every step skips what is already in place.
#
#   ./install.sh            full setup
#   ./install.sh --no-deps  only link configs and sync nvim (no system packages)
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
LOCAL="$HOME/.local"

# Minimum versions this config is known to need.
NVIM_MIN=0.12.0     # vim.lsp.config, nvim-treesitter main branch
TS_MIN=0.26.1       # nvim-treesitter main compiles parsers with it
NODE_MIN=18         # pyright, docker language servers
GO_MIN=1.21         # gopls; 1.21+ fetches newer toolchains on its own

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2; }
die() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }
version_ge() { [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n1)" = "$2" ]; }

nvim_version() { nvim --version 2>/dev/null | head -n1 | sed 's/^NVIM v//; s/-.*//'; }
ts_version() { tree-sitter --version 2>/dev/null | awk '{print $2}'; }
node_major() { node --version 2>/dev/null | sed 's/^v//; s/\..*//'; }
go_version() { go version 2>/dev/null | awk '{print $3}' | sed 's/^go//'; }

nvim_ok() { have nvim && version_ge "$(nvim_version)" "$NVIM_MIN"; }
ts_ok() { have tree-sitter && version_ge "$(ts_version)" "$TS_MIN"; }
node_ok() { have node && have npm && [ "$(node_major)" -ge "$NODE_MIN" ]; }
go_ok() { have go && version_ge "$(go_version)" "$GO_MIN"; }

# --- macOS -------------------------------------------------------------------

install_macos() {
  xcode-select -p >/dev/null 2>&1 || {
    xcode-select --install || true
    die "Finish installing the Xcode Command Line Tools (make, cc), then rerun this script."
  }
  have brew || die "Homebrew is required: https://brew.sh"

  local missing=() pair
  for pair in git:git nvim:neovim tmux:tmux rg:ripgrep fd:fd tree-sitter:tree-sitter-cli \
    node:node go:go python3:python; do
    have "${pair%%:*}" || missing+=("${pair#*:}")
  done
  if [ ${#missing[@]} -gt 0 ]; then
    info "brew install ${missing[*]}"
    brew install "${missing[@]}"
  fi

  nvim_ok || { info "Upgrading neovim (need >= $NVIM_MIN)"; brew upgrade neovim; }
  ts_ok || { info "Upgrading tree-sitter-cli (need >= $TS_MIN)"; brew upgrade tree-sitter-cli; }
  node_ok || { info "Upgrading node (need >= $NODE_MIN)"; brew upgrade node; }
  go_ok || { info "Upgrading go (need >= $GO_MIN)"; brew upgrade go; }
}

# --- Linux -------------------------------------------------------------------

SUDO=""
[ "$(id -u)" -eq 0 ] || SUDO="sudo"

linux_packages() {
  # Distro packages for everything whose packaged version is recent enough.
  # nvim, tree-sitter, node and go are handled separately below, since stable
  # distros often ship versions too old for this config.
  if have apt-get; then
    $SUDO apt-get update -qq
    DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y -qq git curl unzip tar gzip \
      build-essential tmux ripgrep fd-find python3 python3-venv xclip wl-clipboard
  elif have dnf; then
    $SUDO dnf install -y -q git curl unzip tar gzip make gcc tmux ripgrep fd-find \
      python3 xclip wl-clipboard
  elif have pacman; then
    $SUDO pacman -S --needed --noconfirm git curl unzip tar gzip base-devel tmux ripgrep fd \
      python xclip wl-clipboard
  else
    die "Unsupported package manager (need apt, dnf or pacman). Install the packages listed in README.md by hand, then rerun with --no-deps."
  fi

  # Debian/Ubuntu name the fd binary fdfind
  if ! have fd && have fdfind; then
    ln -sf "$(command -v fdfind)" "$LOCAL/bin/fd"
  fi
}

# Official release builds, installed under ~/.local without root.
linux_release_tools() {
  local arch nvim_arch ts_arch node_arch go_arch tmp
  arch="$(uname -m)"
  case "$arch" in
    x86_64 | amd64) nvim_arch=x86_64 ts_arch=x64 node_arch=x64 go_arch=amd64 ;;
    aarch64 | arm64) nvim_arch=arm64 ts_arch=arm64 node_arch=arm64 go_arch=arm64 ;;
    *) die "Unsupported CPU architecture: $arch" ;;
  esac
  tmp="$(mktemp -d)"

  if ! nvim_ok; then
    info "Installing the latest Neovim release to $LOCAL/opt/nvim"
    curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-$nvim_arch.tar.gz" |
      tar -xz -C "$tmp"
    rm -rf "$LOCAL/opt/nvim" && mv "$tmp/nvim-linux-$nvim_arch" "$LOCAL/opt/nvim"
    ln -sf "$LOCAL/opt/nvim/bin/nvim" "$LOCAL/bin/nvim"
  fi

  if ! ts_ok; then
    info "Installing the latest tree-sitter CLI to $LOCAL/bin"
    curl -fsSL "https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-linux-$ts_arch.gz" |
      gunzip >"$LOCAL/bin/tree-sitter"
    chmod +x "$LOCAL/bin/tree-sitter"

    # The prebuilt binary needs glibc 2.39+; older distros (Ubuntu 22.04,
    # Debian 12, RHEL 9) build it from source instead (~2 min).
    if ! "$LOCAL/bin/tree-sitter" --version >/dev/null 2>&1; then
      rm -f "$LOCAL/bin/tree-sitter"
      info "Prebuilt tree-sitter needs a newer glibc; building it with cargo"
      if ! have cargo && [ ! -x "$HOME/.cargo/bin/cargo" ]; then
        curl -fsSL https://sh.rustup.rs | sh -s -- -y --profile minimal --no-modify-path
      fi
      PATH="$HOME/.cargo/bin:$PATH" cargo install --locked --root "$LOCAL" tree-sitter-cli
    fi
  fi

  if ! node_ok; then
    local file
    file="$(curl -fsSL https://nodejs.org/dist/latest-v22.x/SHASUMS256.txt |
      awk "/linux-$node_arch.tar.gz\$/{print \$2}")"
    info "Installing Node.js (${file%.tar.gz}) to $LOCAL/opt/node"
    curl -fsSL "https://nodejs.org/dist/latest-v22.x/$file" | tar -xz -C "$tmp"
    rm -rf "$LOCAL/opt/node" && mv "$tmp/${file%.tar.gz}" "$LOCAL/opt/node"
    ln -sf "$LOCAL/opt/node/bin/node" "$LOCAL/opt/node/bin/npm" "$LOCAL/opt/node/bin/npx" "$LOCAL/bin/"
  fi

  if ! go_ok; then
    local version
    version="$(curl -fsSL 'https://go.dev/VERSION?m=text' | head -n1)"
    info "Installing Go ($version) to $LOCAL/opt/go"
    curl -fsSL "https://go.dev/dl/$version.linux-$go_arch.tar.gz" | tar -xz -C "$tmp"
    rm -rf "$LOCAL/opt/go" && mv "$tmp/go" "$LOCAL/opt/go"
    ln -sf "$LOCAL/opt/go/bin/go" "$LOCAL/opt/go/bin/gofmt" "$LOCAL/bin/"
  fi

  rm -rf "$tmp"
}

# --- configs -----------------------------------------------------------------

# Symlink $1 to $2, moving aside anything already there that isn't our link.
link() {
  local src="$1" dst="$2"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    return
  elif [ -e "$dst" ] || [ -L "$dst" ]; then
    local backup
    backup="$dst.bak.$(date +%Y%m%d%H%M%S)"
    mv "$dst" "$backup"
    warn "Moved existing $dst to $backup"
  fi
  ln -s "$src" "$dst"
  info "Linked $dst -> $src"
}

link_configs() {
  mkdir -p "$CONFIG"
  link "$DOTFILES/nvim" "$CONFIG/nvim"
  link "$DOTFILES/tmux" "$CONFIG/tmux"
  # tmux reads ~/.tmux.conf before ~/.config/tmux/tmux.conf
  [ ! -e "$HOME/.tmux.conf" ] || warn "$HOME/.tmux.conf exists and overrides tmux/tmux.conf; remove it to use this repo's config."
}

bootstrap_nvim() {
  local log
  log="$(mktemp)"
  info "Installing nvim plugins at the versions pinned in lazy-lock.json"
  nvim --headless "+Lazy! restore" +qa >"$log" 2>&1 || { cat "$log"; die "Plugin install failed."; }
  rm -f "$log"

  # parser and language-server lists live in bootstrap.lua
  info "Building treesitter parsers and installing language servers"
  nvim --headless "+lua local ok, err = pcall(dofile, '$DOTFILES/bootstrap.lua'); if not ok then io.stderr:write(err .. '\\n'); vim.cmd('cquit 1') end" +qa ||
    die "nvim bootstrap failed (see above). Rerun ./install.sh; it picks up where it stopped."
}

# --- main --------------------------------------------------------------------

main() {
  local deps=1
  case "${1:-}" in
    --no-deps) deps=0 ;;
    "") ;;
    *) die "Unknown option: $1 (usage: ./install.sh [--no-deps])" ;;
  esac

  mkdir -p "$LOCAL/bin" "$LOCAL/opt"
  export PATH="$LOCAL/bin:$PATH"

  if [ "$deps" -eq 1 ]; then
    case "$(uname -s)" in
      Darwin) install_macos ;;
      Linux)
        linux_packages
        linux_release_tools
        ;;
      *) die "Unsupported OS: $(uname -s)" ;;
    esac
  fi

  local tool
  for tool in git nvim tmux rg make cc curl unzip tree-sitter node npm go python3; do
    have "$tool" || die "$tool is not installed (rerun without --no-deps, or install it by hand)."
  done
  nvim_ok || die "Neovim $(nvim_version) is too old; need >= $NVIM_MIN."
  ts_ok || die "tree-sitter $(ts_version) is too old; need >= $TS_MIN."

  link_configs
  bootstrap_nvim

  info "Done. nvim $(nvim_version), tmux $(tmux -V | awk '{print $2}'), tree-sitter $(ts_version)"
  case ":$PATH_BEFORE:" in
    *":$LOCAL/bin:"*) ;;
    *) [ -z "$(ls -A "$LOCAL/bin")" ] || warn "Add ~/.local/bin to your PATH, e.g. in ~/.bashrc or ~/.zshrc:  export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
  esac
  echo "Use a Nerd Font in your terminal (e.g. JetBrainsMono Nerd Font) so icons render."
}

PATH_BEFORE="$PATH"
main "$@"

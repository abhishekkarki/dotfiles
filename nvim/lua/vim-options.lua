vim.g.mapleader = " "

local opt = vim.opt

-- indentation (2 spaces by default; gofmt re-tabs Go files regardless of
-- these settings, Python is overridden to 4 spaces below per PEP 8)
opt.expandtab = true
opt.tabstop = 2
opt.softtabstop = 2
opt.shiftwidth = 2

-- ui
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.signcolumn = "yes"
opt.termguicolors = true
opt.scrolloff = 8
opt.splitright = true
opt.splitbelow = true

-- editing
opt.ignorecase = true
opt.smartcase = true
opt.undofile = true
opt.updatetime = 250
opt.clipboard = "unnamedplus"

-- no remote plugins are used; skipping providers avoids startup probing and
-- the matching checkhealth warnings
vim.g.loaded_python3_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.shiftwidth = 4
  end,
})

-- terminal: <leader>tt opens a shell in a split below (like VS Code's
-- integrated terminal); double-Esc leaves it, since a single Esc must still
-- reach programs running inside the terminal (e.g. a nested vim, a REPL)
vim.keymap.set('n', '<leader>tt', ':split | terminal<CR>i', {})
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', {})

-- lazygit in a centered floating terminal; closes itself when lazygit exits,
-- then reloads any buffers lazygit changed (checkout, stash, discard)
vim.keymap.set('n', '<leader>gg', function()
  local width = math.floor(vim.o.columns * 0.9)
  local height = math.floor(vim.o.lines * 0.9)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = 'wipe'
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    border = 'rounded',
  })
  vim.fn.jobstart({ 'lazygit' }, {
    term = true,
    on_exit = function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
      vim.cmd('checktime')
    end,
  })
  vim.cmd.startinsert()
end, {})



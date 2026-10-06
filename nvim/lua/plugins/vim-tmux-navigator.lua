return {
  'christoomey/vim-tmux-navigator',

  config = function()
    -- Ctrl+h/j/k/l moves between nvim splits, and on into tmux panes at the edge
    vim.keymap.set('n', '<C-h>', '<cmd>TmuxNavigateLeft<CR>', {})
    vim.keymap.set('n', '<C-j>', '<cmd>TmuxNavigateDown<CR>', {})
    vim.keymap.set('n', '<C-k>', '<cmd>TmuxNavigateUp<CR>', {})
    vim.keymap.set('n', '<C-l>', '<cmd>TmuxNavigateRight<CR>', {})
  end
}

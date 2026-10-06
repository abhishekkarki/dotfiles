return {
  "catppuccin/nvim",
  lazy = false,
  name = "catppuccin",
  priority = 1000,
  config = function()
    require("catppuccin").setup({
      flavour = "mocha",
      integrations = {
        cmp = true,
        gitsigns = true,
        telescope = true,
        native_lsp = {
          enabled = true,
        },
        neotree = true,
        treesitter = true,
      },
    })
    vim.cmd.colorscheme "catppuccin"
  end
}


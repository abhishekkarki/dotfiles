return {
  'nvim-treesitter/nvim-treesitter',
  branch = 'main',
  lazy = false,
  build = ':TSUpdate',

  config = function()
    -- main branch: install parsers, then start highlight/indent per buffer ourselves
    local parsers = { "lua", "go", "gomod", "gosum", "python", "markdown", "markdown_inline", "terraform", "hcl", "yaml", "dockerfile" }
    require('nvim-treesitter').install(parsers)

    vim.api.nvim_create_autocmd('FileType', {
      callback = function(args)
        if pcall(vim.treesitter.start, args.buf) then
          vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end
}

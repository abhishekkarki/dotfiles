return {
  {
    "mason-org/mason.nvim",
    config = function()
      require("mason").setup()
    end
  },
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "golangci_lint_ls", "gopls", "pyright", "ruff" }
      })
    end
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = { "hrsh7th/cmp-nvim-lsp" },
    config = function()
      -- Use native Neovim 0.11+ configuration
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      vim.lsp.config["lua_ls"] = {
        capabilities = capabilities,
      }

      vim.lsp.config["gopls"] = {
        capabilities = capabilities,
        settings = {
          gopls = {
            gofumpt = true,
            staticcheck = true,
            hints = {
              assignVariableTypes = true,
              compositeLiteralFields = true,
              parameterNames = true,
            },
          },
        },
      }

      -- pyright: types, go-to-def, hover. Formatting/linting handled by ruff.
      vim.lsp.config["pyright"] = {
        capabilities = capabilities,
      }

      -- ruff: lint + format for Python. Its hover is disabled so pyright's wins.
      vim.lsp.config["ruff"] = {
        capabilities = capabilities,
        on_attach = function(client)
          client.server_capabilities.hoverProvider = false
        end,
      }

      -- Enable servers
      vim.lsp.enable("lua_ls")
      vim.lsp.enable("gopls")
      vim.lsp.enable("pyright")
      vim.lsp.enable("ruff")

      vim.diagnostic.config({
        virtual_text = true,
        signs = true,
        underline = true,
        severity_sort = true,
      })

      vim.keymap.set('n', 'K', vim.lsp.buf.hover, {})
      vim.keymap.set('n', 'gd', vim.lsp.buf.definition, {})
      vim.keymap.set('n', 'gr', vim.lsp.buf.references, {})
      vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, {})
      vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, {})
      vim.keymap.set({'n', 'v'}, '<leader>ca', vim.lsp.buf.code_action, {})
      vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, {})
      vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, {})
      vim.keymap.set('n', ']d', vim.diagnostic.goto_next, {})
      -- list every error/warning across all open buffers, like an IDE "Problems" panel
      vim.keymap.set('n', '<leader>xx', function()
        vim.diagnostic.setqflist()
        vim.cmd('copen')
      end, {})

      -- organize imports on save (goimports-equivalent via gopls,
      -- isort-equivalent via ruff). Requested per-client, since Python
      -- buffers have two clients (pyright + ruff) with different position
      -- encodings, and a single unscoped request errors on that mismatch.
      local function organize_imports(bufnr)
        for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
          if client:supports_method("textDocument/codeAction", bufnr) then
            local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
            params.context = { only = { "source.organizeImports" }, diagnostics = {} }
            local resp = client:request_sync("textDocument/codeAction", params, 1000, bufnr)
            for _, action in ipairs((resp and resp.result) or {}) do
              if action.edit then
                vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
              elseif action.command then
                client:exec_cmd(action.command, { bufnr = bufnr })
              end
            end
          end
        end
      end

      vim.api.nvim_create_autocmd("BufWritePre", {
        pattern = { "*.go", "*.py", "*.lua" },
        callback = function(args)
          local ft = vim.bo[args.buf].filetype
          if ft == "go" or ft == "python" then
            organize_imports(args.buf)
          end
          vim.lsp.buf.format({ async = false })
        end,
      })
    end,
  },
}

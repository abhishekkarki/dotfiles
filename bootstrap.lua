-- Run by install.sh inside headless nvim (after lazy.nvim has loaded the
-- plugins): builds treesitter parsers and installs Mason tools, waiting for
-- both so nvim doesn't exit halfway. Exits non-zero if anything failed.

-- Keep in sync with nvim/lua/plugins/tresetter.lua
local parsers = {
  "lua", "go", "gomod", "gosum", "python", "markdown", "markdown_inline",
  "terraform", "hcl", "yaml", "dockerfile",
}

-- Mason package names for the servers in nvim/lua/plugins/lsp-config.lua,
-- plus CLI tools those servers and none-ls call out to
local tools = {
  "lua-language-server", "gopls", "golangci-lint-langserver", "golangci-lint",
  "pyright", "ruff", "terraform-ls", "dockerfile-language-server",
  "docker-compose-language-service", "stylua",
}

local failed = {}

print("treesitter: building " .. #parsers .. " parsers (skips ones already built)")
if not require("nvim-treesitter").install(parsers):wait(600000) then
  table.insert(failed, "treesitter parsers")
end

local registry = require("mason-registry")
registry.refresh()
local pending = 0
for _, name in ipairs(tools) do
  local pkg = registry.get_package(name)
  if not pkg:is_installed() then
    pending = pending + 1
    print("mason: installing " .. name)
    pkg:install({}, function(ok, err)
      if not ok then
        table.insert(failed, name .. " (" .. tostring(err) .. ")")
      end
      pending = pending - 1
    end)
  end
end
vim.wait(900000, function() return pending == 0 end, 200)

io.stdout:write("\n")
if #failed > 0 or pending > 0 then
  io.stderr:write("failed: " .. table.concat(failed, ", ") .. "\n")
  vim.cmd("cquit 1")
end

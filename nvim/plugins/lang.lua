-- pythondev — Python language wiring for Neovim.
-- SPDX-License-Identifier: MIT
--
-- LSP servers are installed at BUILD time into the baked venv and are on
-- PATH (Mason is disabled in common/nvim/plugins/disabled.lua):
--   * basedpyright  -> type checking, completion, navigation
--   * ruff (server) -> linting + formatting via `ruff server`
-- This intentionally does NOT use the deprecated `ruff-lsp`.
return {
  -- Treesitter grammar (appended to the common ensure_installed set).
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "python" })
    end,
  },

  -- LSP: basedpyright + ruff's built-in server, configured directly via
  -- LazyVim's `opts.servers` (no Mason auto-install).
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        basedpyright = {
          settings = {
            basedpyright = {
              analysis = {
                typeCheckingMode = "standard",
                diagnosticMode = "openFilesOnly",
                useLibraryCodeForTypes = true,
              },
            },
          },
        },
        ruff = {
          -- ruff's native language server (`ruff server`), NOT ruff-lsp.
          cmd = { "ruff", "server" },
        },
      },
      setup = {
        -- Let basedpyright own hover; ruff handles lint/format only.
        ruff = function()
          vim.api.nvim_create_autocmd("LspAttach", {
            callback = function(args)
              local client = vim.lsp.get_client_by_id(args.data.client_id)
              if client and client.name == "ruff" then
                client.server_capabilities.hoverProvider = false
              end
            end,
            desc = "ruff: defer hover to basedpyright",
          })
          return false
        end,
      },
    },
  },
}

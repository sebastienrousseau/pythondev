-- coding.lua
-- Enhanced Python development configuration with support for:
-- 1. Multiple LSPs (Pyright, Ruff, etc.)
-- 2. Testing frameworks (Pytest)
-- 3. Debugging capabilities
-- 4. Code quality tools
-- 5. Documentation support
return {
    -----------------------------------------------------------------------------
    -- Autocompletion with nvim-cmp
    -----------------------------------------------------------------------------
    {
        "hrsh7th/nvim-cmp",
        opts = function(_, opts)
            local cmp = require("cmp")
            opts.mapping = vim.tbl_deep_extend("force", opts.mapping, {
                ["<C-j>"] = cmp.mapping.select_next_item({
                    behavior = cmp.SelectBehavior.Insert
                }),
                ["<C-k>"] = cmp.mapping.select_prev_item({
                    behavior = cmp.SelectBehavior.Insert
                })
            })
        end
    },

    -----------------------------------------------------------------------------
    -- Treesitter Configuration
    -----------------------------------------------------------------------------
    {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
            if type(opts.ensure_installed) == "table" then
                vim.list_extend(opts.ensure_installed, {
                    "python", "toml", "yaml", "json", "markdown", "bash",
                    "regex", "vim"
                })
            end
        end
    },

    -----------------------------------------------------------------------------
    -- LSP Configuration
    -----------------------------------------------------------------------------
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "williamboman/mason.nvim", "folke/neodev.nvim" -- Better Lua development
        },
        config = function()
            local lspconfig = require("lspconfig")

            -- Pyright configuration
            lspconfig.pyright.setup({
                settings = {
                    python = {
                        analysis = {
                            typeCheckingMode = "basic",
                            autoSearchPaths = true,
                            useLibraryCodeForTypes = true,
                            diagnosticMode = "workspace",
                            inlayHints = {
                                variableTypes = true,
                                functionReturnTypes = true
                            },
                            -- Add these settings
                            diagnosticSeverityOverrides = {
                                reportGeneralTypeIssues = "warning",
                                reportOptionalMemberAccess = "warning",
                                reportOptionalSubscript = "warning",
                                reportPrivateImportUsage = "warning"
                            }
                        }
                    }
                }
            })

            -- Ruff LSP configuration
            lspconfig.ruff_lsp.setup({
                on_attach = function(client, bufnr)
                    -- Disable formatting if you want to use black instead
                    client.server_capabilities.documentFormattingProvider =
                        false
                end
            })
        end
    },

    -----------------------------------------------------------------------------
    -- Mason Tool Installation
    -----------------------------------------------------------------------------
    {
        "williamboman/mason.nvim",
        opts = {
            ensure_installed = {
                -- LSP
                "pyright", "ruff-lsp", "mypy", -- Formatters
                "black", "isort", -- Linters
                "pylint", "bandit", -- Debug Adapter
                "debugpy", -- Documentation
                "mdformat", -- Security
                "pip-audit"
            }
        }
    },

    -----------------------------------------------------------------------------
    -- Debugging Support
    -----------------------------------------------------------------------------
    {
        "mfussenegger/nvim-dap",
        dependencies = {"rcarriga/nvim-dap-ui", "mfussenegger/nvim-dap-python"},
        config = function()
            local dap = require("dap")
            local dapui = require("dapui")
            require("dap-python").setup("python")

            -- Configure debugging UI
            dapui.setup({
                layouts = {
                    {
                        elements = {
                            "scopes", "breakpoints", "stacks", "watches"
                        },
                        size = 40,
                        position = "left"
                    },
                    {
                        elements = {"repl", "console"},
                        size = 10,
                        position = "bottom"
                    }
                }
            })

            -- Debugging keymaps
            vim.keymap.set("n", "<F5>", dap.continue)
            vim.keymap.set("n", "<F10>", dap.step_over)
            vim.keymap.set("n", "<F11>", dap.step_into)
            vim.keymap.set("n", "<F12>", dap.step_out)
            vim.keymap.set("n", "<leader>b", dap.toggle_breakpoint)
        end
    },

    -----------------------------------------------------------------------------
    -- Testing Support
    -----------------------------------------------------------------------------
    {
        "nvim-neotest/neotest",
        dependencies = {
            "nvim-neotest/nvim-nio", -- Add this required dependency
            "nvim-lua/plenary.nvim", "antoinemadec/FixCursorHold.nvim",
            "nvim-treesitter/nvim-treesitter", "nvim-neotest/neotest-python"
        },
        config = function()
            require("neotest").setup({
                adapters = {
                    require("neotest-python")({
                        dap = {justMyCode = false},
                        runner = "pytest",
                        args = {"--cov", "--cov-report=term-missing"}
                    })
                }
            })
        end
    },

    -----------------------------------------------------------------------------
    -- Code Navigation and Search
    -----------------------------------------------------------------------------
    {
        "nvim-telescope/telescope.nvim",
        dependencies = {"nvim-telescope/telescope-fzf-native.nvim"},
        config = function()
            require("telescope").setup({
                extensions = {
                    fzf = {
                        fuzzy = true,
                        override_generic_sorter = true,
                        override_file_sorter = true,
                        case_mode = "smart_case"
                    }
                }
            })
        end
    },

    -----------------------------------------------------------------------------
    -- Additional Tools
    -----------------------------------------------------------------------------
    {
        "folke/todo-comments.nvim",
        dependencies = "nvim-lua/plenary.nvim",
        config = function() require("todo-comments").setup({}) end
    },
    -----------------------------------------------------------------------------
    -- Python Formatting
    -----------------------------------------------------------------------------
    {
        "stevearc/conform.nvim",
        opts = {
            formatters_by_ft = {python = {"black", "isort"}},
            format_on_save = {timeout_ms = 500, lsp_fallback = true}
        }
    },

    -----------------------------------------------------------------------------
    -- Python Docstring Support
    -----------------------------------------------------------------------------
    {
        "danymat/neogen",
        dependencies = "nvim-treesitter/nvim-treesitter",
        config = function()
            require("neogen").setup({
                enabled = true,
                languages = {
                    python = {
                        template = {annotation_convention = "google_docstrings"}
                    }
                }
            })
            -- Keymaps for generating documentation
            vim.keymap.set("n", "<Leader>nd",
                           ":lua require('neogen').generate()<CR>")
        end
    },

    -----------------------------------------------------------------------------
    -- Better Python Indentation
    -----------------------------------------------------------------------------
    {"Vimjas/vim-python-pep8-indent", ft = "python"},

    -----------------------------------------------------------------------------
    -- Python-specific Snippets
    -----------------------------------------------------------------------------
    {
        "L3MON4D3/LuaSnip",
        config = function()
            require("luasnip.loaders.from_vscode").lazy_load()
            require("luasnip").filetype_extend("python", {"python"})
        end
    },

    -----------------------------------------------------------------------------
    -- Better Python REPL Integration
    -----------------------------------------------------------------------------
    {
        "jpalardy/vim-slime",
        ft = "python",
        config = function()
            vim.g.slime_target = "neovim"
            vim.g.slime_python_ipython = 1
        end
    },

    -----------------------------------------------------------------------------
    -- Enhanced Python Syntax
    -----------------------------------------------------------------------------
    {
        "vim-python/python-syntax",
        ft = "python",
        config = function() vim.g.python_highlight_all = 1 end
    }
}

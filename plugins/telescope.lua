-- telescope.lua
return {
    {
        "nvim-telescope/telescope.nvim",
        branch = "0.1.x",
        dependencies = {
            "nvim-lua/plenary.nvim", {
                "nvim-telescope/telescope-fzf-native.nvim",
                build = "make",
                cond = function()
                    return vim.fn.executable("make") == 1
                end
            }, "nvim-telescope/telescope-dap.nvim",
            "nvim-telescope/telescope-file-browser.nvim",
            "nvim-telescope/telescope-project.nvim",
            "benfowler/telescope-luasnip.nvim"
        },
        config = function()
            local telescope = require("telescope")
            local actions = require("telescope.actions")
            local trouble = require("trouble.sources.telescope") -- Updated trouble requirement

            telescope.setup({
                defaults = {
                    -- Default configuration
                    prompt_prefix = "🔍 ",
                    selection_caret = "❯ ",
                    path_display = {"truncate"},

                    mappings = {
                        i = {
                            ["<C-j>"] = actions.move_selection_next,
                            ["<C-k>"] = actions.move_selection_previous,
                            ["<C-q>"] = actions.send_selected_to_qflist +
                                actions.open_qflist,
                            ["<C-t>"] = trouble.open, -- Updated trouble function
                            ["<Esc>"] = actions.close,
                            ["<C-Down>"] = actions.cycle_history_next,
                            ["<C-Up>"] = actions.cycle_history_prev
                        }
                    }
                },

                extensions = {
                    project = {
                        base_dirs = {
                            {path = vim.fn.expand("~/code")} -- Use expand to resolve home directory
                        },
                        hidden_files = true,
                        theme = "dropdown",
                        order_by = "asc",
                        search_by = "title",
                        sync_with_nvim_tree = true
                    }
                }
            })

            -- Load extensions
            telescope.load_extension("fzf")
            telescope.load_extension("file_browser")
            telescope.load_extension("project")
            telescope.load_extension("dap")
            telescope.load_extension("luasnip")

            -- Key mappings
            local keymap = vim.keymap.set
            local opts = {noremap = true, silent = true}

            -- Make sure project directory exists
            local function ensure_project_dir()
                local home = os.getenv("HOME")
                local code_dir = home .. "/code"
                if vim.fn.isdirectory(code_dir) == 0 then
                    os.execute("mkdir -p " .. code_dir)
                    os.execute("chmod 755 " .. code_dir)
                end
            end

            ensure_project_dir()

            -- Rest of your keymaps...
        end
    }
}

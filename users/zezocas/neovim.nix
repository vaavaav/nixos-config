{ pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withPython3 = false;
    withRuby = false;

    extraPackages = with pkgs; [
      git
      ripgrep
      fd
      nodejs_24
      ccls
      lua-language-server
      cmake-language-server
      bash-language-server
      nil
      nixfmt
      ltex-ls
      haskell-language-server
      (python3.withPackages (ps: with ps; [ black isort python-lsp-server python-lsp-black pyls-isort ]))
    ];

    initLua = ''
      vim.o.ignorecase = true
      vim.o.smartcase = true
      vim.o.relativenumber = true
      vim.o.number = true
      vim.o.shiftwidth = 2
      vim.o.smarttab = true
      vim.o.expandtab = true
      vim.o.hlsearch = true
      vim.g.mapleader = "\\"
      vim.o.termguicolors = true
      vim.o.autoread = true
      vim.o.clipboard = "unnamedplus"
      vim.o.signcolumn = "yes"
      vim.o.scrolloff = 8
      vim.o.undofile = true
      vim.o.updatetime = 300
      vim.o.splitright = true
      vim.o.splitbelow = true

      local map = vim.keymap.set

      map("n", "<Esc>", "<cmd>nohlsearch<CR>", { silent = true })
      map({ "n", "v" }, "<c-u>", "<c-u>zz")
      map({ "n", "v" }, "<c-d>", "<c-d>zz")
      map({ "n", "v" }, "n", "nzz")
      map({ "n", "v" }, "N", "Nzz")

      map("n", "<leader>nd", function() vim.diagnostic.jump({ count = 1, float = false }) end)
      map("n", "<leader>pd", function() vim.diagnostic.jump({ count = -1, float = false }) end)
      map("n", "<leader>d", function()
        vim.diagnostic.config({ virtual_text = not vim.diagnostic.config().virtual_text })
      end, { noremap = true, silent = true })

      vim.diagnostic.config({
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = "\u{f057}",
            [vim.diagnostic.severity.WARN]  = "\u{f071}",
            [vim.diagnostic.severity.INFO]  = "\u{f05a}",
            [vim.diagnostic.severity.HINT]  = "\u{f0335}",
          },
        },
      })

      local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
      if not (vim.uv or vim.loop).fs_stat(lazypath) then
        local out = vim.fn.system({
          "git", "clone", "--filter=blob:none", "--branch=stable",
          "https://github.com/folke/lazy.nvim.git", lazypath,
        })
        if vim.v.shell_error ~= 0 then
          vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out,                            "WarningMsg" },
            { "\nPress any key to exit..." },
          }, true)
          vim.fn.getchar()
          os.exit(1)
        end
      end
      vim.opt.rtp:prepend(lazypath)

      require("lazy").setup({

        {
          "rebelot/kanagawa.nvim",
          priority = 1000,
          config = function()
            require("kanagawa").load("wave")
          end,
        },

        { "nvim-tree/nvim-web-devicons", lazy = true },

        {
          "nvim-telescope/telescope.nvim",
          tag = "0.1.8",
          dependencies = { "nvim-lua/plenary.nvim" },
          cmd = "Telescope",
          keys = {
            { "<C-f>",     "<cmd>Telescope find_files<CR>", desc = "Find files" },
            { "<C-g>",     "<cmd>Telescope live_grep<CR>",  desc = "Live grep" },
            { "<leader>o", "<cmd>Telescope oldfiles<CR>",   desc = "Recent files" },
          },
          config = function()
            local actions = require("telescope.actions")
            require("telescope").setup({
              defaults = {
                mappings = {
                  i = {
                    ["<C-j>"] = actions.move_selection_next,
                    ["<C-k>"] = actions.move_selection_previous,
                    ["<Esc>"] = actions.close,
                  },
                  n = {
                    ["<C-j>"] = actions.move_selection_next,
                    ["<C-k>"] = actions.move_selection_previous,
                    ["<Esc>"] = actions.close,
                  },
                },
                vimgrep_arguments = {
                  "rg", "--no-heading", "--with-filename",
                  "--line-number", "--column", "--smart-case", "--no-ignore",
                },
              },
              pickers = {
                find_files = {
                  find_command = { "fd", "--type", "f", "--hidden", "--follow", "--no-ignore", "--exclude", ".git" },
                },
              },
            })
          end,
        },

        {
          "nvim-telekasten/telekasten.nvim",
          dependencies = { "nvim-telescope/telescope.nvim" },
          cmd = "Telekasten",
          keys = {
            { "<leader>zf", function() require("telekasten").find_notes() end,     desc = "TK find notes" },
            { "<leader>zg", function() require("telekasten").search_notes() end,   desc = "TK grep notes" },
            { "<leader>zn", function() require("telekasten").new_note() end,       desc = "TK new note" },
            { "<leader>zl", function() require("telekasten").insert_link() end,    desc = "TK insert link" },
            { "<leader>zb", function() require("telekasten").show_backlinks() end, desc = "TK backlinks" },
            { "<leader>zr", function() require("telekasten").rename_note() end,    desc = "TK rename note" },
            { "<leader>zd", function() require("telekasten").goto_today() end,     desc = "TK today" },
          },
          config = function()
            local home = vim.fn.expand("~/notes")
            require("telekasten").setup({
              home = home,
              dailies = home .. "/daily",
              templates = home .. "/templates",
              new_note_filename = "title",
              template_new_daily = home .. "/templates/daily.md",
              follow_creates_nonexisting = true,
              dailies_create_nonexisting = true,
            })
            vim.api.nvim_create_autocmd("FileType", {
              pattern = "markdown",
              callback = function()
                vim.keymap.set("n", "<CR>", function()
                  require("telekasten").follow_link()
                end, { buffer = true, silent = true })
              end,
            })
          end,
        },

        { "jinh0/eyeliner.nvim",         event = "VeryLazy" },

        {
          "nvim-tree/nvim-tree.lua",
          dependencies = { "nvim-tree/nvim-web-devicons" },
          keys = { { "<C-n>", "<cmd>NvimTreeToggle<CR>", desc = "File tree" } },
          config = function()
            require("nvim-tree").setup({
              sort = { sorter = "case_sensitive" },
              view = { width = 30 },
              renderer = { group_empty = true },
              filters = { dotfiles = false, git_ignored = false },
            })
          end,
        },

        {
          "aserowy/tmux.nvim",
          event = "VeryLazy",
          config = function()
            require("tmux").setup({ resize = { resize_step_x = 5, resize_step_y = 5 } })
            map("n", "<C-M-h>", function() require("tmux").resize_left() end, { silent = true })
            map("n", "<C-M-j>", function() require("tmux").resize_down() end, { silent = true })
            map("n", "<C-M-k>", function() require("tmux").resize_up() end, { silent = true })
            map("n", "<C-M-l>", function() require("tmux").resize_right() end, { silent = true })
          end,
        },

        {
          "nvim-lualine/lualine.nvim",
          dependencies = { "nvim-tree/nvim-web-devicons" },
          event = "VeryLazy",
          config = function()
            require("lualine").setup({
              options = { icons_enabled = true, theme = "palenight" },
              sections = {
                lualine_a = { "mode" },
                lualine_b = { "diagnostics" },
                lualine_c = { { "branch", icon = "\u{e0a0}" }, "diff" },
                lualine_x = { 'os.date("%H:%M | %a, %d-%m-%y")' },
                lualine_y = { { "filename", path = 1 } },
                lualine_z = { "location" },
              },
            })
          end,
        },

        {
          "lervag/vimtex",
          ft = { "tex", "plaintex", "latex" },
          init = function()
            vim.g.vimtex_view_method = "zathura"
            vim.g.vimtex_compiler_method = "latexmk"
            vim.g.vimtex_latexmk_automatic = 1
            vim.g.vimtex_complete_enabled = 1
            vim.g.vimtex_quickfix_enabled = 0
            vim.g.vimtex_syntax_enabled = 0
            map("n", "<leader>lv", "<cmd>VimtexView<CR>")
            map("n", "<leader>lc", "<cmd>VimtexCompile<CR>")
          end,
        },

        {
          "github/copilot.vim",
          event = "InsertEnter",
          config = function()
            vim.g.copilot_no_tab_map = true
            vim.g.copilot_enabled = true
            map("i", "<C-l>", 'copilot#Accept("<CR>")', { silent = true, expr = true, replace_keycodes = false })
            map("i", "<C-;>", 'copilot#AcceptLine("<CR>")', { silent = true, expr = true, replace_keycodes = false })
            map("", "<leader>c", function()
              vim.g.copilot_enabled = not vim.g.copilot_enabled
              vim.notify("Copilot " .. (vim.g.copilot_enabled and "enabled" or "disabled"), "info")
            end, { noremap = true, silent = true })
          end,
        },

        {
          "hrsh7th/nvim-cmp",
          event = { "InsertEnter", "CmdlineEnter" },
          dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "L3MON4D3/LuaSnip",
            "saadparwaiz1/cmp_luasnip",
          },
          config = function()
            local cmp = require("cmp")
            cmp.setup({
              sources = {
                { name = "nvim_lsp" },
                { name = "luasnip" },
                { name = "buffer" },
                { name = "path" },
              },
              snippet = {
                expand = function(args) vim.snippet.expand(args.body) end,
              },
              mapping = cmp.mapping.preset.insert({
                ["<CR>"]  = cmp.mapping.confirm({ select = true }),
                ["<C-j>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
                ["<C-k>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
              }),
            })
          end,
        },

        {
          "neovim/nvim-lspconfig",
          event = { "BufReadPre", "BufNewFile" },
          dependencies = { "hrsh7th/cmp-nvim-lsp" },
          config = function()
            vim.lsp.enable({ "ccls", "lua_ls", "cmake", "bashls", "pylsp", "nil_ls", "ltex", "hls" })

            vim.lsp.config("pylsp", {
              settings = {
                pylsp = {
                  plugins = {
                    black = { enabled = true },
                    isort = { enabled = true },
                    pycodestyle = { enabled = false },
                    mccabe = { enabled = false },
                    pyflakes = { enabled = false },
                    yapf = { enabled = false },
                    autopep8 = { enabled = false },
                  },
                },
              },
            })

            vim.lsp.config("nil_ls", {
              settings = { ["nil"] = { formatting = { command = { "nixfmt" } } } },
            })

            local autoformat = true
            map("n", "<leader>f", function()
              autoformat = not autoformat
              vim.notify("Autoformat " .. (autoformat and "enabled" or "disabled"), "info", { title = "Autoformat" })
            end, { noremap = true, silent = true })

            vim.api.nvim_create_autocmd("LspAttach", {
              callback = function(event)
                local client = vim.lsp.get_client_by_id(event.data.client_id)
                if client and client:supports_method("textDocument/formatting") then
                  vim.api.nvim_create_autocmd("BufWritePre", {
                    buffer = event.buf,
                    callback = function()
                      if autoformat then vim.lsp.buf.format({ async = false, timeout_ms = 10000 }) end
                    end,
                  })
                end
              end,
            })
          end,
        },

      }, {
        change_detection = { notify = false },
      })
    '';
  };

  home.sessionVariables.VISUAL = "nvim";
  home.file."notes/daily/.keep".text = "";
  home.file."notes/templates/daily.md".text = "# {{date}}\n\n";
}

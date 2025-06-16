local vim = vim
----------------------------------------------------------------------------------------
-- General settings
----------------------------------------------------------------------------------------
vim.o.ignorecase = true                                                        -- If true, ignore case in search pattern
vim.o.relativenumber = true                                                    -- If true, show relative line numbers
vim.o.number = true                                                            -- If true, show absolute line numbers
vim.o.shiftwidth = 2                                                           -- Number of spaces to use for each step of (auto)indent
vim.o.smarttab = true                                                          -- If true, insert indents automatically
vim.o.expandtab = true                                                         -- If true, convert tabs to spaces
vim.o.hlsearch = true                                                          -- If true, highlight search results
vim.g.mapleader = "\\"                                                         -- Set leader key
vim.o.termguicolors = true                                                     -- If true, use 24-bit RGB colors in the terminal
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { noremap = true, silent = true }) -- Exit terminal mode with ESC
vim.keymap.set("n", "<Esc>", ":noh<Esc>", { silent = true })                   -- Clear search highlights after pressing enter
vim.keymap.set({ "n", "v" }, "<c-u>", "<c-u>zz")                               -- Center after scrolling up
vim.keymap.set({ "n", "v" }, "<c-d>", "<c-d>zz")                               -- Center after scrolling down
vim.keymap.set({ "n", "v" }, "n", "nzz")                                       -- Center after jumping to next match
vim.keymap.set({ "n", "v" }, "N", "Nzz")                                       -- Center after jumping to previous match
vim.keymap.set("n", "<leader>nd", function() vim.diagnostic.goto_next({ float = false }) end)
vim.keymap.set("n", "<leader>pd", function() vim.diagnostic.goto_prev({ float = false }) end)
vim.api.nvim_set_keymap('n', '<leader>td',
  ':lua vim.diagnostic.config({ virtual_text = not vim.diagnostic.config().virtual_text })<CR>',
  { noremap = true, silent = true }) -- Toggle diagnostic virtual text on and off

vim.diagnostic.config({
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "",
      [vim.diagnostic.severity.WARN] = "",
      [vim.diagnostic.severity.INFO] = "",
      [vim.diagnostic.severity.HINT] = "",
    }
  }
})
----------------------------------------------------------------------------------------
-- Bootstrap lazy
----------------------------------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.notify("Lazy not found, cloning...", "info", { title = "Lazy" })
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out,                            "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)
----------------------------------------------------------------------------------------
-- Setup lazy and plugins
----------------------------------------------------------------------------------------
require("lazy").setup({
  {
    "rebelot/kanagawa.nvim",
    config = function()
      require("kanagawa").load("wave")
    end,
  },
  { "nvim-tree/nvim-web-devicons" },
  {
    'akinsho/toggleterm.nvim',
    opts = {
      vim.api.nvim_set_keymap('n', '<C-t>', ':ToggleTerm<CR>', { noremap = true, silent = true })
    }
  },
  {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.8',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      vim.keymap.set('', '<C-f>', ':Telescope find_files<CR>', { noremap = true, silent = true })
      vim.keymap.set('', '<C-g>', ':Telescope live_grep<CR>', { noremap = true, silent = true })
      vim.keymap.set('', '<leader>cs', ':Telescope colorscheme enable_preview=true<CR>',
        { noremap = true, silent = true })
      require('telescope').setup {
        defaults = {
          mappings = {
            i = {
              ["<C-j>"] = require('telescope.actions').move_selection_next,
              ["<C-k>"] = require('telescope.actions').move_selection_previous,
              ["<CR>"] = require('telescope.actions').select_default,
              ["<Esc>"] = require('telescope.actions').close,
            },
            n = {
              ["<C-j>"] = require('telescope.actions').move_selection_next,
              ["<C-k>"] = require('telescope.actions').move_selection_previous,
              ["<Esc>"] = require('telescope.actions').close,
            }
          },
          vimgrep_arguments = {
            "rg",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
            "--smart-case",
          }
        },
        pickers = {
          find_files = {
            find_command = { 'fd', '--type', 'f', '--hidden', '--follow', '--no-ignore', '--exclude', '.git' }
          }
        },
        extensions = {}
      }
    end,
  },
  { "jinh0/eyeliner.nvim" },
  {
    "goolord/alpha-nvim",
    config = function()
      require("alpha").setup(require("alpha.themes.startify").config)
    end,
  },
  {
    "aserowy/tmux.nvim",
    config = function()
      require('tmux').setup({
        resize = {
          resize_step_x = 5,
          resize_step_y = 5,
        }
      })
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    config = function()
      require('lualine').setup {
        options = {
          icons_enabled = true,
          theme = 'palenight',
        },
        sections = {
          lualine_a = { 'mode' },
          lualine_b = { 'diagnostics' },
          lualine_c = { { 'branch', icon = '' }, 'diff' },
          lualine_x = { 'os.date("%H:%M | %a, %d-%m-%y")' },
          lualine_y = {
            {
              'filename',
              path = 1,
            }
          },
          lualine_z = {
            'location'
          },
        }
      }
    end,
  },
  {
    "nvim-tree/nvim-tree.lua",
    config = function()
      require("nvim-tree").setup({
        sort = {
          sorter = "case_sensitive",
        },
        view = {
          width = 30,
        },
        renderer = {
          group_empty = true,
        },
        filters = {
          dotfiles = false,
          git_ignored = false,
        },
      })
      vim.keymap.set("n", "<C-n>", ":NvimTreeToggle<CR>")
    end,
  },
  {
    'lervag/vimtex',
    lazy = false,
    init = function()
      vim.g.vimtex_view_method = 'zathura'
      vim.g.vimtex_latexmk_automatic = 1
      vim.g.vimtex_quickfix_enabled = 0
      vim.g.vimtex_syntax_enabled = 0
      vim.g.vimtex_root_markers = { '.latexmkrc', '.git' }
      vim.keymap.set("n", "<leader>ls", ':VimtexView<CR>')
      vim.keymap.set("n", "<leader>lc", ':VimtexCompile<CR>')
      vim.keymap.set("n", "<leader>lo", ':VimtexCompileOutput<CR>')
    end
  },
  {
    "renerocksai/telekasten.nvim",
    dependencies = { 'nvim-telescope/telescope.nvim' },
    config = function()
      require("telekasten").setup {
        home = vim.fn.expand("~/.notes"), -- Change to your actual notes directory
        filename_space_subst = "",
        filename_small_case = true,
        vaults = {
          zettelkasten = {
            home = vim.fn.expand("~/.notes/zettelkasten"),
          },
        },
        templates = vim.fn.expand("~/.notes/templates"),
      }
      vim.keymap.set("n", "<leader>z", "<cmd>Telekasten panel<CR>")
      vim.keymap.set("n", "<leader>zn", "<cmd>Telekasten new_note<CR>")
      vim.keymap.set("n", "<leader>zt", "<cmd>Telekasten new_templated_note<CR>")
      vim.keymap.set("n", "<leader>zg", "<cmd>Telekasten search_notes<CR>")
      vim.keymap.set("n", "<leader>zd", "<cmd>Telekasten goto_today<CR>")
      vim.keymap.set("n", "<leader>zz", "<cmd>Telekasten follow_link<CR>")
      vim.keymap.set("n", "<leader>zc", "<cmd>Telekasten show_calendar<CR>")
      vim.keymap.set("n", "<leader>zb", "<cmd>Telekasten show_backlinks<CR>")
      vim.keymap.set("n", "<leader>zI", "<cmd>Telekasten insert_img_link<CR>")
      vim.keymap.set("i", "[[", "<cmd>Telekasten insert_link<CR>")
    end,

  },
  -- LSP
  {
    "VonHeikemen/lsp-zero.nvim",
    branch = "v4.x",
    dependencies = {
      -- LSP Support
      { "neovim/nvim-lspconfig" },

      -- Copilot
      {
        "github/copilot.vim",
        config = function()
          vim.g.copilot_no_tab_map = true
          vim.keymap.set("i", "<C-l>", 'copilot#Accept("<CR>")', { silent = true, expr = true, replace_keycodes = false })
          vim.keymap.set("n", "<leader>tc", ':lua ToggleCopilot()<CR>', { noremap = true, silent = true })
          local status = 'enable'
          function ToggleCopilot()
            status = status == 'enable' and 'disable' or 'enable'
            vim.cmd('Copilot ' .. status)
            vim.notify('Copilot ' .. status .. 'd', 'info', { title = 'Copilot' })
          end
        end,
      },

      -- Snippets
      { "L3MON4D3/LuaSnip" },

      -- Auto-completion
      { "hrsh7th/nvim-cmp" },
      { "hrsh7th/cmp-nvim-lsp" },
      { "hrsh7th/cmp-buffer" },
      { "hrsh7th/cmp-path" },
      { "saadparwaiz1/cmp_luasnip" },
      { "hrsh7th/cmp-nvim-lua" },
    },
    config = function()
      local lsp_zero = require('lsp-zero')

      local lsp_attach = function(_, bufnr)
        lsp_zero.default_keymaps({ buffer = bufnr, perserve_mappings = false })
      end

      lsp_zero.extend_lspconfig({
        lsp_attach = lsp_attach,
        set_lsp_keymaps = true,
      })

      for _, server in ipairs({ 'ccls', 'lua_ls', 'texlab', 'rust_analyzer', 'nil_ls', 'cmake', 'bashls', 'pylyzer', 'markdown_oxide' }) do
        require('lspconfig')[server].setup {}
      end

      local cmp = require('cmp')

      cmp.setup({
        sources = {
          { name = 'nvim_lsp' },
        },
        snippet = {
          expand = function(args)
            -- You need Neovim v0.10 to use vim.snippet
            vim.snippet.expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
          ['<C-j>'] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
          ['<C-u>'] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
        }),
      })

      -- Format on save
      local autoformat = true
      function ToggleAutoFormat()
        autoformat = not autoformat
        vim.notify('Autoformat ' .. (autoformat and 'enabled' or 'disabled'), 'info', { title = 'Autoformat' })
      end

      vim.api.nvim_set_keymap('n', '<leader>tf', ':lua ToggleAutoFormat()<CR>',
        { noremap = true, silent = true })
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(event)
          local id = vim.tbl_get(event, 'data', 'client_id')
          local client = id and vim.lsp.get_client_by_id(id)
          if client and client.supports_method("textDocument/formatting") then
            vim.api.nvim_create_autocmd('BufWritePre', {
              buffer = event.buf,
              callback = function()
                if autoformat then
                  vim.lsp.buf.format({ async = false, timeout_ms = 10000 })
                end
              end
            })
          end
        end,
      })
    end,
  },
})

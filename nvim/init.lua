-- init.lua — Neovim entry point
-- Lives in the dotfiles repo; symlinked to ~/.config/nvim by install.sh.

vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("config") -- options + keymaps

local ok, _ = pcall(require, "lazy")
if not ok then
  -- Bootstrap lazy.nvim on first run.
  local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
  if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
      "git", "clone", "--filter=blob:none",
      "https://github.com/folke/lazy.nvim.git",
      "--branch=stable", lazypath,
    })
  end
  vim.opt.rtp:prepend(lazypath)
end

require("lazy").setup({
  { "folke/tokyonight.nvim", priority = 1000 },
  -- Catppuccin to match terminal + Starship.
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    lazy = false,
    config = function()
      require("catppuccin").setup({ flavour = "mocha", transparent_background = true })
      vim.cmd.colorscheme("catppuccin")
    end,
  },

  "nvim-lua/plenary.nvim",
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
  "nvim-tree/nvim-web-devicons",
  "nvim-lua/popup.nvim",

  -- File explorer
  { "nvim-tree/nvim-tree.lua", config = function()
    require("nvim-tree").setup { }
  end },

  -- Auto pairs / closing brackets
  { "windwp/nvim-autopairs", event = "InsertEnter", config = true },
})
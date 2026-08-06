-- Editor options — sensible defaults, compatible with WSL + Windows nvim.

vim.opt.termguicolors = true   -- truecolor (needs a capable terminal: WezTerm ok)
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"
vim.opt.cursorline = true

vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.smartindent = true
vim.opt.autoindent = true
vim.opt.wrap = false

vim.opt.clipboard = "unnamedplus" -- uses OSC-52 from WezTerm
vim.opt.swapfile = false
vim.opt.undofile = true

vim.opt.scrolloff = 8
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.incsearch = true

vim.opt.updatetime = 250
vim.opt.timeoutlen = 400

-- Leader keymap helpers
vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", { desc = "Explorer" })
vim.keymap.set("n", "<leader>ff", "<cmd>!fzf<CR>", { desc = "Fuzzy find" })
vim.keymap.set("n", "<C-s>", "<cmd>write<CR>", { desc = "Save" })
vim.keymap.set("i", "<C-s>", "<cmd>write<CR>", { desc = "Save" })

-- Base config (loaded by init.lua)
return {}

-- Small terminal-first VPS configuration. No plugin downloads or background services.
vim.g.mapleader = " "
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.scrolloff = 5
vim.opt.termguicolors = true

vim.keymap.set("n", "<leader>w", "<cmd>write<cr>", { desc = "Write file" })
vim.keymap.set("n", "<leader>q", "<cmd>quit<cr>", { desc = "Quit window" })
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

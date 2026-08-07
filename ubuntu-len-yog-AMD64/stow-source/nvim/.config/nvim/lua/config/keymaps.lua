-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

-- Quick escape in insert mode
map("i", "jf", "<Esc>", { desc = "Escape insert mode" })
map("i", "fj", "<Esc>", { desc = "Escape insert mode" })

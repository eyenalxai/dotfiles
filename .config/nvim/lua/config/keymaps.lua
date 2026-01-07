-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Make delete operations not yank (use black hole register)
-- Only y should yank, only p and <C-v> should paste
vim.keymap.set({ "n", "v" }, "d", '"_d', { desc = "Delete without yanking" })
vim.keymap.set({ "n", "v" }, "D", '"_D', { desc = "Delete to end of line without yanking" })
vim.keymap.set({ "n", "v" }, "x", '"_x', { desc = "Delete char without yanking" })
vim.keymap.set({ "n", "v" }, "X", '"_X', { desc = "Delete char before without yanking" })
vim.keymap.set({ "n", "v" }, "c", '"_c', { desc = "Change without yanking" })
vim.keymap.set({ "n", "v" }, "C", '"_C', { desc = "Change to end of line without yanking" })
vim.keymap.set({ "n", "v" }, "s", '"_s', { desc = "Substitute without yanking" })
vim.keymap.set({ "n", "v" }, "S", '"_S', { desc = "Substitute line without yanking" })

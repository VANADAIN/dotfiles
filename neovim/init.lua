-- Set options
vim.opt.clipboard = "unnamedplus"  -- Use system clipboard (Linux/Wayland)
vim.opt.mouse = "a"


-- numbers
vim.opt.number = true
vim.opt.relativenumber = true


-- case
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true


-- tabs
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4


-- Key mappings
vim.keymap.set("v", "<C-c>", '"+y')  -- Visual mode: Ctrl+C to copy to system clipboard
-- vim.keymap.set("n", "<C-v>", '"+p')  -- Normal mode: Ctrl+V to paste from system clipboard
vim.keymap.set("i", "<C-v>", '<C-o>"+p')  -- Insert mode: Ctrl+V to paste from system clipboard


-- colors
vim.cmd.colorscheme("habamax")


-- other
require("config.lazy")


-- Read the docs: https://www.lunarvim.org/docs/configuration
-- Example configs: https://github.com/LunarVim/starter.lvim
-- Video Tutorials: https://www.youtube.com/watch?v=sFA9kX-Ud_c&list=PLhoH5vyxr6QqGu0i7tt_XoVK9v-KvZ3m6
-- Forum: https://www.reddit.com/r/lunarvim/
-- Discord: https://discord.com/invite/Xb9B4Ny
--

lvim.plugins = {
  { "zbirenbaum/copilot.lua", cmd = "Copilot", event = "InsertEnter" },
  { "zbirenbaum/copilot-cmp", after = { "copilot.lua" }, config = function()
      require("copilot_cmp").setup()
    end
  },
}

vim.opt.scrolloff = 20
vim.opt.relativenumber = true
vim.opt.wrap = false 

lvim.plugins = {
  { "github/copilot.vim" },
   {
     "Pocco81/auto-save.nvim",
     config = function()
       require("auto-save").setup {
         debounce_time = 5000, 
         on_write = function()
           vim.notify("---")
         end
       }
     end,
   },
 }

 local function open_nvim_tree()
    require("nvim-tree.api").tree.open()
  end
 
 require("nvim-tree").setup {
      view = {
          side = "right",
        }
 }

vim.api.nvim_create_autocmd({ "VimEnter" }, { callback = open_nvim_tree })
 
vim.keymap.set("n", "<A-;>", ":NvimTreeToggle<CR>", { noremap = true, silent = true })

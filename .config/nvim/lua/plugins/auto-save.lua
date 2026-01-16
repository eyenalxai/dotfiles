return {
  {
    "Pocco81/auto-save.nvim",
    event = { "InsertLeave", "TextChanged", "TextChangedI" },
    opts = {
      enabled = true,
      debounce_delay = 2000,
      write_all_buffers = false,
      execution_message = {
        enabled = false,
      },
      condition = function(buf)
        local fn = vim.fn
        local utils = require("auto-save.utils.data")

        if fn.getbufvar(buf, "&modifiable") ~= 1 then
          return false
        end

        -- Skip non-file buffers
        if vim.bo[buf].buftype ~= "" then
          return false
        end

        -- Skip some noisy filetypes
        if not utils.not_in(vim.bo[buf].filetype, { "gitcommit", "gitrebase" }) then
          return false
        end

        return true
      end,
    },
    keys = {
      { "<leader>uS", "<cmd>ASToggle<cr>", desc = "Toggle Auto-Save" },
    },
  },
}

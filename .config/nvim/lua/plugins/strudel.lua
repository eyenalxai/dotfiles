return {
  {
    "gruvw/strudel.nvim",
    build = "npm ci",
    config = function()
      local browser = vim.env.BROWSER
      browser = browser and vim.split(browser, "%s+")[1] or nil

      local browser_exec_path = nil
      if browser and browser ~= "" then
        local resolved = vim.fn.exepath(browser)
        browser_exec_path = resolved ~= "" and resolved or nil
      end

      require("strudel").setup({
        browser_exec_path = browser_exec_path,
      })
    end,
  },
}

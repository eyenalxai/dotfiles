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
  {
    "pedrozappa/tree-sitter-strdl",
    build = "npm run local_install",
  },
  {
    "nvim-treesitter/nvim-treesitter",
    dependencies = { "pedrozappa/tree-sitter-strdl" },
    config = function()
      -- Register strudel parser immediately
      require("nvim-treesitter.parsers").strudel = {
        install_info = {
          url = "https://github.com/pedrozappa/tree-sitter-strdl",
          branch = "main",
          generate = false,
          generate_from_json = false,
        },
      }

      -- Also register in TSUpdate autocmd for consistency
      vim.api.nvim_create_autocmd("User", {
        pattern = "TSUpdate",
        callback = function()
          require("nvim-treesitter.parsers").strudel = {
            install_info = {
              url = "https://github.com/pedrozappa/tree-sitter-strdl",
              branch = "main",
              generate = false,
              generate_from_json = false,
            },
          }
        end,
      })

      -- Register filetype mapping
      vim.treesitter.language.register("strudel", { "strdl" })

      -- Set up filetype detection for .strdl and .strudel files
      vim.filetype.add({
        extension = {
          strdl = "strdl",
          strudel = "strdl",
        },
      })
    end,
  },
}

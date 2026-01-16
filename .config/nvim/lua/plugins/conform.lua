return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      strdl = { "oxfmt" },

      -- Prefer oxfmt, fall back to Biome.
      javascript = { "oxfmt", "biome" },
      javascriptreact = { "oxfmt", "biome" },
      typescript = { "oxfmt", "biome" },
      typescriptreact = { "oxfmt", "biome" },
    },
    formatters = {
      oxfmt = {
        command = "oxfmt",
        args = function(self, ctx)
          -- Spoof the file extension as .js for oxfmt
          local filename = vim.fn.fnamemodify(ctx.filename, ":t:r") .. ".js"
          return { "--stdin-filepath=" .. filename }
        end,
        stdin = true,
      },
    },
  },
}

return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      local util = require("lspconfig.util")

      opts.servers = opts.servers or {}

      opts.servers.oxlint = {
        mason = false,
        -- Project-local oxlint (pnpm): run the real Node entrypoint.
        cmd = { "node", "node_modules/oxlint/bin/oxlint", "--lsp" },
        filetypes = {
          "javascript",
          "javascriptreact",
          "javascript.jsx",
          "typescript",
          "typescriptreact",
          "typescript.tsx",
          "vue",
          "svelte",
          "astro",
        },
        workspace_required = true,
        on_attach = function(client, bufnr)
          vim.api.nvim_buf_create_user_command(bufnr, "LspOxlintFixAll", function()
            client:exec_cmd({
              title = "Apply Oxlint automatic fixes",
              command = "oxc.fixAll",
              arguments = { { uri = vim.uri_from_bufnr(bufnr) } },
            })
          end, { desc = "Apply Oxlint automatic fixes" })
        end,
        root_dir = function(bufnr, on_dir)
          local fname = vim.api.nvim_buf_get_name(bufnr)
          local root_markers = util.insert_package_json({ ".oxlintrc.json" }, "oxlint", fname)[1]
          on_dir(vim.fs.dirname(vim.fs.find(root_markers, { path = fname, upward = true })[1]))
        end,
        init_options = {
          settings = {},
        },
      }
    end,
  },
}

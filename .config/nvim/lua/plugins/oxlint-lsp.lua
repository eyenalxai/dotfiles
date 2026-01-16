return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      local util = require("lspconfig.util")

      opts.servers = opts.servers or {}

      local function resolve_oxlint_cmd(root_dir)
        local bin = root_dir .. "/node_modules/oxlint/bin/oxlint"
        if vim.fn.filereadable(bin) == 1 then
          return { "node", bin, "--lsp" }
        end
        local shim = root_dir .. "/node_modules/.bin/oxlint"
        if vim.fn.filereadable(shim) == 1 then
          return { shim, "--lsp" }
        end
        return nil
      end

      opts.setup = opts.setup or {}
      opts.setup.oxlint = function(_, server_opts)
        local root_pattern = util.root_pattern(".oxlintrc.json", "pnpm-workspace.yaml", ".git")

        local function start_oxlint(bufnr)
          local filetype = vim.bo[bufnr].filetype
          if not vim.tbl_contains(server_opts.filetypes, filetype) then
            return
          end
          if #vim.lsp.get_clients({ name = "oxlint", bufnr = bufnr }) > 0 then
            return
          end
          local fname = vim.api.nvim_buf_get_name(bufnr)
          if fname == "" then
            return
          end
          local root_dir = root_pattern(fname)
          if not root_dir then
            return
          end
          local cmd = resolve_oxlint_cmd(root_dir)
          if not cmd then
            return
          end
          vim.lsp.start({
            name = "oxlint",
            cmd = cmd,
            root_dir = root_dir,
            filetypes = server_opts.filetypes,
            init_options = server_opts.init_options,
            workspace_folders = {
              { name = root_dir, uri = vim.uri_from_fname(root_dir) },
            },
          })
        end

        local augroup = vim.api.nvim_create_augroup("OxlintLspStart", { clear = true })
        vim.api.nvim_create_autocmd({ "FileType", "BufEnter", "BufWinEnter" }, {
          group = augroup,
          callback = function(args)
            start_oxlint(args.buf)
          end,
        })

        for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_loaded(bufnr) then
            start_oxlint(bufnr)
          end
        end

        return true
      end

      opts.servers.oxlint = {
        enabled = true,
        autostart = true,
        mason = false,
        -- Project-local oxlint (pnpm): resolve from workspace root.
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
          log_oxlint("on_attach client=" .. client.name .. " root_dir=" .. tostring(client.config.root_dir))
          vim.api.nvim_buf_create_user_command(bufnr, "LspOxlintFixAll", function()
            client:exec_cmd({
              title = "Apply Oxlint automatic fixes",
              command = "oxc.fixAll",
              arguments = { { uri = vim.uri_from_bufnr(bufnr) } },
            })
          end, { desc = "Apply Oxlint automatic fixes" })
        end,
        init_options = {
          settings = {},
        },
      }
    end,
  },
}

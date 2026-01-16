return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        biome = {
          cmd = { "biome", "lsp-proxy" },
          on_new_config = function(new_config, root_dir)
            local local_biome = root_dir .. "/node_modules/.bin/biome"
            if vim.uv.fs_stat(local_biome) then
              new_config.cmd = { local_biome, "lsp-proxy" }
            else
              -- Never use a global Biome; only run when project-local exists.
              new_config.autostart = false
            end
          end,
        },
      },
      setup = {
        biome = function(_, opts)
          -- Keep formatting handled by conform.nvim; use Biome for lint/diagnostics.
          local previous_on_attach = opts.on_attach
          opts.on_attach = function(client, buffer)
            if previous_on_attach then
              previous_on_attach(client, buffer)
            end
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.documentRangeFormattingProvider = false
          end
        end,
      },
    },
  },
}

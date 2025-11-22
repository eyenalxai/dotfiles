-- Strudel.nvim - Live coding with Strudel from Neovim
return {
  "gruvw/strudel.nvim",
  build = "npm install",
  -- Pin to a specific commit to avoid update issues with package-lock.json
  pin = true,
  config = function()
    local strudel = require("strudel")

    -- Setup strudel with default options
    strudel.setup({
      -- Strudel web user interface related options
      ui = {
        -- Maximise the menu panel
        maximise_menu_panel = true,
        -- Hide the Strudel menu panel (and handle)
        hide_menu_panel = false,
        -- Hide the default Strudel top bar (controls)
        hide_top_bar = false,
        -- Hide the Strudel code editor
        hide_code_editor = false,
        -- Hide the Strudel eval error display under the editor
        hide_error_display = false,
      },
      -- Automatically start playback when launching Strudel
      start_on_launch = true,
      -- Set to `true` to automatically trigger the code evaluation after saving the buffer content
      update_on_save = true,
      -- Enable two-way cursor position sync between Neovim and Strudel editor
      sync_cursor = true,
      -- Report evaluation errors from Strudel as Neovim notifications
      report_eval_errors = true,
      -- Headless mode: set to `true` to run the browser without launching a window
      headless = false,
      -- Path to the directory where Strudel browser user data is stored
      browser_data_dir = "~/.cache/strudel-nvim/",
    })

    -- Configure keymaps
    vim.keymap.set("n", "<leader>sl", strudel.launch, { desc = "Launch Strudel" })
    vim.keymap.set("n", "<leader>sq", strudel.quit, { desc = "Quit Strudel" })
    vim.keymap.set("n", "<leader>st", strudel.toggle, { desc = "Strudel Toggle Play/Stop" })
    vim.keymap.set("n", "<leader>su", strudel.update, { desc = "Strudel Update" })
    vim.keymap.set("n", "<leader>ss", strudel.stop, { desc = "Strudel Stop Playback" })
    vim.keymap.set("n", "<leader>sb", strudel.set_buffer, { desc = "Strudel set current buffer" })
    vim.keymap.set("n", "<leader>sx", strudel.execute, { desc = "Strudel set current buffer and update" })
  end,
}

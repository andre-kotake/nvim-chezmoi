vim.api.nvim_create_user_command("ChezmoiListSource", function()
  vim.cmd("Telescope nvim-chezmoi source_files")
end, {
  desc = "List all chezmoi managed files.",
  force = true,
})

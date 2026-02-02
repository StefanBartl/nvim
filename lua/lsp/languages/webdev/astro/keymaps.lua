---@module 'lsp.languages.webdev.astro.keymaps'

local M = {}

function M.attach()
  local bufnr = vim.api.nvim_get_current_buf()
  if not bufnr or type(bufnr) ~= "number" then
    vim.notify("bufnr in astro keymaps attaching is not valid")
    return nil
  end

  -- Component-Navigation
pcall(vim.keymap.set, "n", "gC", function()

  require("telescope.builtin").find_files({
    prompt_title = "Astro Components",
    search_dirs = { "src/components" },
    file_ignore_patterns = { "%.test%.", "%.spec%." },
  })
end, { buffer = bufnr, desc = "Find Astro Components" })

-- Script/Style Block Navigation
pcall(vim.keymap.set, "n", "<leader>as", function()
  vim.fn.search("^<script", "w")
end, { buffer = bufnr, desc = "Jump to <script>" })

pcall(vim.keymap.set, "n", "<leader>ay", function()
  vim.fn.search("^<style", "w")
end, { buffer = bufnr, desc = "Jump to <style>" })
end

return M

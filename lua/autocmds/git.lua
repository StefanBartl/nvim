---@module 'autocmds.git'

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    -- Prüfe, ob es Konflikte gibt
    local conflicts = vim.fn.systemlist("git diff --name-only --diff-filter=U")

    if #conflicts == 0 then return end

    -- Fülle quickfix-Liste mit den Konflikt-Dateien
    local qf_entries = {}
    for _, file in ipairs(conflicts) do
      table.insert(qf_entries, {
        filename = file,
        lnum = 1,
        col = 1,
        text = "Git conflict",
      })
    end

    vim.fn.setqflist(qf_entries, 'r')
    vim.cmd("copen")

    -- Optionale Notify-Meldung
    vim.notify("Git conflicts detected in:\n" .. table.concat(conflicts, "\n"), vim.log.levels.WARN)
  end,
})

# `buffer-ctx`

-- Fügt das aktuelle Datum ein (z. B. 10.07.2026)
vim.keymap.set('n', '<leader>d', 'i<C-r>=strftime("%d.%m.%Y")<CR><Esc>', { desc = 'Datum einfügen' })
+ usrcmd dafür

---


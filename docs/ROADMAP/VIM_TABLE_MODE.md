# `dhruvasagar/vim-table-mode`

Um das Plugin `dhruvasagar/vim-table-mode` in den **lazy.nvim** Plugin-Manager für Neovim einzubinden, kannst du die folgende Konfiguration verwenden.

Je nachdem, wie deine Neovim-Konfiguration strukturiert ist, fügst du den Code entweder in deine zentrale Plugin-Liste ein oder erstellst eine separate Datei (z. B. `lua/plugins/table-mode.lua`).

## Table of content

  - [Option 1: Einfache Einbindung (Standard)](#option-1-einfache-einbindung-standard)
  - [Option 2: Optimierte Einbindung (Lazy Loading)](#option-2-optimierte-einbindung-lazy-loading)
  - [Option 3: Mit Konfiguration der im README erwähnten Abkürzungen (`||` und `__`)](#option-3-mit-konfiguration-der-im-readme-erwhnten-abkrzungen-und)
  - [Kurze Erklärung zu den Lazy-Optionen:](#kurze-erklrung-zu-den-lazy-optionen)

---

## Option 1: Einfache Einbindung (Standard)

Wenn du das Plugin standardmäßig laden und die Standard-Tastenkombinationen (wie `<Leader>tm` zum Aktivieren) nutzen möchtest:

```lua
return {
  "dhruvasagar/vim-table-mode",
  -- Das Plugin wird geladen, sobald du Neovim startest
  lazy = false,
}

```

## Option 2: Optimierte Einbindung (Lazy Loading)

Um die Startzeit von Neovim zu optimieren, kannst du das Plugin so konfigurieren, dass es erst geladen wird, wenn du bestimmte Befehle aufrufst oder eine Markdown-/ReST-Datei öffnest:

```lua
return {
  "dhruvasagar/vim-table-mode",
  -- Lädt das Plugin nur bei diesen Befehlen oder Dateitypen
  cmd = { "TableModeToggle", "Tableize" },
  ft = { "markdown", "rst" },
  init = function()
    -- Hier kannst du Vim-Variablen definieren, BEVOR das Plugin geladen wird.
    -- Beispiel: Markdown-kompatible Ecken aktivieren (falls nötig)
    vim.g.table_mode_corner = '|'
  end,
}
```

## Option 3: Mit Konfiguration der im README erwähnten Abkürzungen (`||` und `__`)

Wenn du die im README beschriebenen automatischen Abkürzungen für den Insert-Modus nutzen möchtest, kannst du diese elegant über die `config`-Funktion von lazy.nvim als Lua-Code registrieren:

```lua
return {
  "dhruvasagar/vim-table-mode",
  ft = { "markdown", "rst" }, -- Lädt das Plugin nur für Markdown/ReST
  cmd = { "TableModeToggle", "Tableize" },
  config = function()
    -- Falls du Markdown-Tabellen erzwingen möchtest:
    vim.g.table_mode_corner = '|'

    -- Helferfunktion aus dem README in Lua übersetzt
    local function is_at_start_of_line(mapping)
      local col = vim.fn.col('.')
      local line = vim.fn.getline('.')
      local text_before_cursor = string.sub(line, 1, col - 1)
      local mapping_pattern = [[\V]] .. vim.fn.escape(mapping, [[\]])

      -- Kommentarzeichen der aktuellen Datei einbeziehen
      local commentstring = vim.bo.commentstring
      local comment_pattern = [[\V]] .. vim.fn.escape(vim.fn.substitute(commentstring, [[%s.*$]], '', ''), [[\]])

      local pattern = '^' .. [[\v(]] .. comment_pattern .. [[\v)?]] .. [[\s*\v]] .. mapping_pattern .. [[\v$]]
      return vim.fn.match(text_before_cursor, pattern) ~= -1
    end

    -- Tastenkombinationen / Abkürzungen für den Insert-Modus einrichten
    vim.keymap.set('ia', '||', function()
      if is_at_start_of_line('||') then
        return '<c-o>:TableModeEnable<cr><bar><space><bar><left><left>'
      else
        return '||'
      end
    end, { expr = true, buffer = false })

    vim.keymap.set('ia', '__', function()
      if is_at_start_of_line('__') then
        return '<c-o>:silent! TableModeDisable<cr>'
      else
        return '__'
      end
    end, { expr = true, buffer = false })
  end,
}

```

## Kurze Erklärung zu den Lazy-Optionen:

* **`cmd`**: Verhindert, dass das Plugin beim Starten Speicher verbraucht. Es wird erst aktiv, wenn du `:TableModeToggle` eintippst.
* **`ft`**: Lädt das Plugin automatisch, sobald du eine `.md` (Markdown) oder `.rst` Datei öffnest.
* **`init`**: Wird ausgeführt, während Neovim startet (wichtig für globale `vim.g.*` Variablen, die das Plugin beim Laden ausliest).
* **`config`**: Wird erst ausgeführt, *nachdem* das Plugin geladen wurde. Perfekt für Keymaps oder komplexere Setups.

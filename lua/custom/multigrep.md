```lua
-- Importiere Telescope-Module
local pickers = require "telescope.pickers"          -- Für das Erstellen eines neuen Pickers (Suchfenster)
local finders = require "telescope.finders"           -- Für das Erstellen eines Finders (Lieferung von Einträgen)
local make_entry = require "telescope.make_entry"     -- Zum Formatieren der Suchergebnisse
local conf = require "telescope.config".values        -- Zugriff auf Standard-Konfigurationen von Telescope

-- Lokales Modul-Table
local M = {}

-- Hauptfunktion für Multi-Grep
local live_multigrep = function(opts)
  opts = opts or {}                                   -- Initialisiere Optionen, falls nicht übergeben
  opts.cwd = opts.cwd or vim.uv.cwd()                 -- Setze das Arbeitsverzeichnis (current working directory)

  -- Definition des Finders (liefert die Suchergebnisse)
  local finder = finders.new_async_job {
    -- Funktion, die ein Shell-Command auf Basis der Benutzereingabe erstellt
    command_generator = function(prompt)
      if not prompt or prompt == "" then
        return nil                                    -- Wenn nichts eingegeben wurde, keinen Befehl zurückgeben
      end

      -- Eingabe in zwei Teile splitten (durch zwei Leerzeichen getrennt)
      local pieces = vim.split(prompt, "  ")
      local args = { "rg" }                           -- Starte mit 'rg' (ripgrep) als Basisbefehl

      -- Erster Teil: Suchmuster hinzufügen
      if pieces[1] then
        table.insert(args, "-e")
        table.insert(args, pieces[1])
      end

      -- Zweiter Teil: Datei- oder Pfadfilter hinzufügen
      if pieces[2] then
        table.insert(args, "-g")
        table.insert(args, pieces[2])
      end

      -- Debug-Ausgabe der kompletten ripgrep-Argumente
      print("rg args:", vim.inspect(args))

      -- Zusätzliche Standardoptionen für bessere Ausgabe anhängen
      local merged_args = vim.deepcopy(args)          -- Kopiere args, um Original nicht zu verändern
      vim.list_extend(merged_args, {
        "--color=never",                              -- Keine Farbcodes in der Ausgabe
        "--no-heading",                               -- Keine Dateiüberschrift
        "--with-filename",                            -- Zeige den Dateinamen bei Treffern
        "--line-number",                              -- Zeige die Zeilennummer
        "--column",                                   -- Zeige die Spaltennummer
        "--smart-case"                                -- Nutze intelligente Groß-/Kleinschreibung
      })

      -- Rückgabe des fertigen Kommandos für den Async-Job
      return merged_args
    end,

    -- Wie jedes Suchergebnis formatiert werden soll
    entry_maker = make_entry.gen_from_vimgrep(opts),
    cwd = opts.cwd,                                   -- Arbeitsverzeichnis für den Finder
  }

  -- Erstelle und starte einen neuen Picker mit dem konfigurierten Finder
  pickers.new(opts, {
    debounce = 100,                                   -- Wartezeit zum Dämpfen schneller Tippbewegungen
    prompt_title = "Multi Grep",                      -- Titel des Suchfensters
    finder = finder,                                  -- Verwendeter Finder (siehe oben)
    previewer = conf.grep_previewer(opts),             -- Previewer für Trefferinhalte
    sorter = require("telescope.sorters").empty(),     -- Kein spezielles Sortierverhalten
  }):find()                                            -- Starte die Suche
end

-- Setup-Funktion, um die Keymap zu setzen
M.setup = function()
  vim.keymap.set("n", "<leader>fg", live_multigrep)    -- Binde <leader>fg im Normalmodus an live_multigrep
end

-- Rückgabe des Modul-Tables
return M
```

---

# 📋 Was bedeutet das im Überblick?

- `live_multigrep()` ist dein **Custom-Telescope-Picker**, der
  - eine Eingabe verarbeitet
  - daraus `ripgrep`-Befehle baut
  - sie asynchron ausführt
  - und die Ergebnisse anzeigt.
- Der **Finder** (`finders.new_async_job`) erzeugt on-the-fly Shell-Kommandos.
- Du benutzt bewusst einen **leeren Sorter**, um möglichst direkte Ergebnisse zu zeigen.
- Keymap wird sauber über eine `setup()`-Funktion registriert → Lazy-kompatibel.

---

# 🧠 Hinweise:
- `print("rg args:", vim.inspect(args))` ist derzeit **Debug-Ausgabe** – du kannst das optional entfernen, wenn du fertig bist.

---

## 📦 Eingabe-Split:

```lua
local pieces = vim.split(prompt, "  ")
```

→ Hier wird die Benutzereingabe in zwei Teile aufgeteilt – **durch zwei Leerzeichen getrennt**.

Beispiel:

```
TODO  *.lua
```

führt zu:

```lua
pieces[1] = "TODO"
pieces[2] = "*.lua"
```

---

## 🔍 Bedeutung der Optionen

```lua
table.insert(args, "-e")
table.insert(args, pieces[1])
```

→ Fügt `-e <suchbegriff>` zu `rg` hinzu.
🧠 Das ist der **Suchbegriff**, nach dem `ripgrep` im Dateiinhalt sucht.

---

```lua
table.insert(args, "-g")
table.insert(args, pieces[2])
```

→ Fügt `-g <muster>` zu `rg` hinzu.
🧠 Das ist ein **Glob-Pattern für Dateinamen**, also z. B.:

- `*.lua` → nur `.lua`-Dateien durchsuchen
- `src/**` → nur Dateien im `src`-Verzeichnis
- `!tests/**` → Tests ausschließen

---

## 🔎 Beispiel: Was der finale Befehl bewirkt

Eingabe:

```text
myFunc  *.ts
```

ergibt:

```bash
rg -e myFunc -g *.ts \
  --color=never --no-heading --with-filename \
  --line-number --column --smart-case
```

→ Das bedeutet:

> **Suche nach `myFunc` nur in Dateien, die auf `.ts` enden.**

---

## 📋 Zusammenfassung

| `pieces[1]` | Wird mit `-e` an `rg` übergeben → ist der **Suchtext**           |
| ----------- | ---------------------------------------------------------------- |
| `pieces[2]` | Wird mit `-g` an `rg` übergeben → ist der **Dateifilter (Glob)** |

---

## 📢 Hinweis

Wenn du `prompt` nur `"TODO"` schreibst (ohne zwei Leerzeichen und Pattern), wird **alles** durchsucht.
Nur wenn du `"TODO  *.lua"` (doppelte Leertaste) eingibst, wird ein Filter auf `.lua` gesetzt.

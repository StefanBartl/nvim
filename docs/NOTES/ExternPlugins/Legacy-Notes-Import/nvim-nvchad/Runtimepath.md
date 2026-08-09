# runtimepath

Der `runtimepath` (`:set runtimepath?`) ist die zentrale Liste von Pfaden, in denen Neovim nach Laufzeitdateien wie Plugins, Farben, Syntaxdefinitionen, Autoload-Dateien, Lua-Module usw. sucht.

## Aufbau

Der `runtimepath` ist eine **durch Kommas getrennte Liste von Verzeichnissen**. Die Reihenfolge ist entscheidend für das Laden von Konfigurationsdateien und Plugins. Übliche Bestandteile sind:

1. `~/.config/nvim`
   → Hauptverzeichnis der Benutzerkonfiguration (inkl. `init.lua`, `lua/`, `plugin/`, etc.)

2. `~/.local/share/nvim/site`
   → Speicherort installierter Plugins (z. B. von `lazy.nvim`, `packer`, etc.)

3. `$VIMRUNTIME`
   → Systemverzeichnis für die mitgelieferten Plugins, Syntaxdefinitionen usw.

4. `.../after`
   → Pfade, die nachträglich geladen werden (z. B. `~/.config/nvim/after/plugin/...`), um bestehende Einstellungen zu überschreiben.

---

## Wie Plugins geladen werden

Neovim lädt automatisch `.vim`- oder `.lua`-Dateien aus folgenden Verzeichnissen innerhalb jedes `runtimepath`-Eintrags:

- `plugin/` → wird beim Start geladen
- `after/plugin/` → wird *nach* allen `plugin/`-Dateien geladen
- `ftplugin/` → für filetype-spezifische Konfigurationen
- `autoload/` → Lazy-loaded Funktionen (Vimscript oder Lua)
- `syntax/`, `indent/`, `colors/` → entsprechende Features

---

## Beispiel: runtimepath prüfen

```vim
:echo &runtimepath
```

---

## Plugin-Manager wie `lazy.nvim`

Tools wie `lazy.nvim` fügen beim Start dynamisch Einträge zum `runtimepath` hinzu. Sie laden Plugins aus z. B.:

```
~/.local/share/nvim/lazy/<plugin-name>
```

Die genaue Integration erfolgt per `nvim_set_runtime_path()`, `vim.opt.rtp:append()` oder durch Manipulation von `&runtimepath` direkt.

---

## Pfade priorisieren oder debuggen

Um z. B. sicherzustellen, dass ein bestimmtes `ftplugin/` geladen wird, kann man gezielt prüfen:

```lua
print(vim.opt.runtimepath:get())
```

Oder mit `:scriptnames` herausfinden, welche Datei geladen wurde.

---

## Wann `runtimepath` wichtig ist

- Bei Problemen mit Plugin-Ladereihenfolge
- Beim Debuggen von geladenen Dateien
- Beim Überschreiben von Defaults aus `$VIMRUNTIME`
- Beim Laden eigener Lua-Module (`require("meine.datei")` → muss unter `runtimepath/lua/` liegen)

---

# Zusammenfassung

`runtimepath` verbindet:
- Systemverzeichnis (`$VIMRUNTIME`)
- Benutzerverzeichnis (`~/.config/nvim`)
- Plugin-Verzeichnisse (`site`, `lazy`, etc.)
- Nachladbare Pfade (`after`)

Durch gezieltes Einfügen oder Anpassen lassen sich gezielt Konfigurations- oder Plugindateien priorisieren oder überlagern.

---
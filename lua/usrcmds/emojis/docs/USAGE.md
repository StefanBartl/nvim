# 🍿 Cheatsheet: Neovim `:Emojis` Usercommand

Das Modul stellt einen universellen, mächtigen Befehl zur Verfügung, der Emoji-Aktionen auf unterschiedlichen Gültigkeitsbereichen (**Scopes**) ausführen kann.

### **Generelle Syntax**

```vim
:Emojis [action] [scope]
:[range]Emojis [action]

```

* **Standard-Verhalten (ohne Argumente):** `:Emojis` $\rightarrow$ Entspricht `:Emojis clear %` (löscht alle Emojis im aktuellen Puffer).

---

## 🛠️ 1. Verfügbare Aktionen (`[action]`)

| Aktion | Beschreibung |
| --- | --- |
| `clear` | Entfernt alle Emojis im gewählten Scope restlos (Standard-Aktion). |
| `replace` | Ersetzt Emojis mit ihren `:HEXBYTES:` Platzhaltern. |
| `list` | Sucht alle Emojis im Scope und lädt sie in die **Quickfix-Liste** (`:copen`). |
| `count` | Zählt die Emojis im Scope und gibt das Ergebnis via Notification aus. |
| `insert` | Öffnet ein `vim.ui.select` Auswahlmenü am Cursor, um ein Emoji einzufügen. |

---

## 🔍 2. Verfügbare Bereiche (`[scope]`)

| Scope | Beschreibung |
| --- | --- |
| `%` | Der gesamte aktuelle Puffer (Standard-Scope). |
| `line` | Nur die Zeile, auf der sich der Cursor aktuell befindet. |
| `word` | Analysiert die aktuelle Zeile des Wortes unter dem Cursor. |
| `visual` | Die Zeilen der letzten (oder aktuellen) visuellen Auswahl. |
| `cwd` | **Asynchrone systemweite Suche** via `ripgrep` im aktuellen Arbeitsverzeichnis (nur für `list` und `count`). |

---

## 💡 3. Praktische Anwendungsbeispiele (Alltags-Befehle)

### **Löschen & Ersetzen (Destruktive Befehle)**

* **Ganze Datei säubern:**
```vim
:Emojis clear %

```


* **Emojis nur in der aktuellen Zeile entfernen:**
```vim
:Emojis clear line

```


* **Ausgewählten Block bereinigen (Visual Mode):**
Markiere Text und tippe `:` (wird automatisch zu `:'<,'>Emojis clear`). Der Vim-Range überschreibt jeden Keyword-Scope!

### **Analysieren & Suchen**

* **Wo sind Emojis in meiner Datei? (Quickfix-Ansicht):**
```vim
:Emojis list %

```


* **Projektweit nach Emojis suchen (Asynchron via `rg`):**
```vim
:Emojis list cwd

```


* **Wie viele Emojis habe ich im Projekt verbaut?**
```vim
:Emojis count cwd

```



### **Interaktives Arbeiten**

* **Emoji-Picker am Cursor öffnen:**
```vim
:Emojis insert

```


*(Hinweis: Bei `insert` wird das `scope`-Argument ignoriert, da direkt an der Cursor-Position gearbeitet wird).*

---

## ⚙️ 4. Integration & Setup in Lua

Du kannst das Modul in deiner Konfiguration (`init.lua` oder Lazy-Plugin-Spezifikation) laden. Beim Setup lässt sich der Standard-Scope anpassen:

```lua
local emojis = require("usrcmds.emojis")

emojis.setup({
  -- Ändert das Standard-Verhalten, falls kein Scope übergeben wird
  -- Gültig: "word", "line", "visual", "%", "cwd"
  default_scope = "%",
})

```

### ⌨️ Nützliche Keymaps (Vorschlag)

Um das Modul ohne Tipparbeit im Alltag zu nutzen, bieten sich folgende Kurzbefehle an:

```lua
-- Schneller Emoji-Picker im Insert- oder Normal-Mode
vim.keymap.set({ "n", "i" }, "<C-e>", "<cmd>Emojis insert<cr>", { desc = "Emoji: Picker öffnen" })

-- Schneller Check der aktuellen Datei
vim.keymap.set("n", "<leader>ec", "<cmd>Emojis count %<cr>", { desc = "Emoji: Zählen im Puffer" })
vim.keymap.set("n", "<leader>el", "<cmd>Emojis list %<cr>", { desc = "Emoji: In Quickfix auflisten" })

```

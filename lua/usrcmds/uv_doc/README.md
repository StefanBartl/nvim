# UVDoc – libuv Dokumentation für Neovim

Ein modulares Dokumentationssystem für libuv-Bindings (`vim.uv`/`vim.loop`) direkt in Neovim. Fetcht RST-Quelldateien von der offiziellen libuv-Dokumentation und extrahiert C-Signaturen sowie Beschreibungen.

## Table of content

- [UVDoc – libuv Dokumentation für Neovim](#uvdoc-libuv-dokumentation-fr-neovim)
  - [Features](#features)
  - [Installation](#installation)
  - [Voraussetzungen](#voraussetzungen)
  - [Befehle](#befehle)
    - [`:UVDoc [name]`](#uvdoc-name)
    - [`:UVDocList [query]`](#uvdoclist-query)
    - [`:UVDocHere [name]`](#uvdochere-name)
    - [`:UVDocCacheClear`](#uvdoccacheclear)
  - [Navigation in der Symbol-Liste](#navigation-in-der-symbol-liste)
  - [Konfiguration](#konfiguration)
  - [Architektur](#architektur)
    - [Modulare Struktur](#modulare-struktur)
    - [Design-Prinzipien](#design-prinzipien)
  - [Unterstützte Eingabeformate](#untersttzte-eingabeformate)
  - [Fuzzy-Search-Kategorien](#fuzzy-search-kategorien)
  - [Beispiel-Workflow](#beispiel-workflow)
  - [Integration mit /lib](#integration-mit-lib)
  - [Troubleshooting](#troubleshooting)
    - ["genindex unavailable"](#genindex-unavailable)
    - ["no uv_* anchors found"](#no-uv_-anchors-found)
    - ["function signature not found"](#function-signature-not-found)
  - [Performance-Hinweise](#performance-hinweise)
  - [Lizenz und Quellen](#lizenz-und-quellen)
  - [Verwandte Dokumentation](#verwandte-dokumentation)

---

## Features

- **Exakte und Fuzzy-Suche** nach `uv_*` Symbolen
- **Interaktive Symbol-Auswahl** mit Cursorline-Navigation
- **Signatur-Extraktion** aus RST-Quelldateien
- **Command-line Completion** für alle libuv-Symbole
- **Aggregierte Genindex-Parsing** (handhabt Split-Pages automatisch)
- **Session-basiertes Caching** mit expliziter Invalidierung
- **Lazy-Loading** aller Submodule für minimale Startup-Zeit

## Installation

Da dieses Modul Teil einer größeren Neovim-Konfiguration ist, wird es automatisch geladen, wenn man die User-Commands aktiviert:

```lua
require("usrcmds.uv_doc").enable_usercmd()
```

## Voraussetzungen

- Neovim ≥ 0.9 (für `vim.system` API)
- `curl` im `PATH` (Linux/macOS)
- Internetzugang für Dokumentationsabruf

## Befehle

### `:UVDoc [name]`

Zeigt Dokumentation für ein libuv-Symbol an.

**Verhalten:**
- Exakte Namen (`uv_timer_start`) werden direkt geöffnet
- Fuzzy-Queries (`timer`, `fs_event`) zeigen interaktive Auswahl
- Ohne Argument wird das Wort unter dem Cursor verwendet

**Beispiele:**
```vim
:UVDoc uv_timer_start
:UVDoc timer
:UVDoc vim.uv.new_tcp
```

### `:UVDocList [query]`

Öffnet interaktive Symbol-Liste mit optionalem Filter.

**Beispiele:**
```vim
:UVDocList          " Alle Symbole
:UVDocList fs       " Nur filesystem-Funktionen
:UVDocList tcp      " Nur TCP-Funktionen
```

### `:UVDocHere [name]`

Fügt C-Signatur an Cursorposition ein.

**Verhalten:**
- Funktionen werden als Markdown-Codeblock eingefügt
- Typdefinitionen als Kommentar-Zeile
- Fuzzy-Matching wie bei `:UVDoc`

**Beispiele:**
```vim
:UVDocHere uv_fs_stat
:UVDocHere loop
```

### `:UVDocCacheClear`

Löscht alle Session-Caches (Genindex und Symbol-Liste).

## Navigation in der Symbol-Liste

| Tastenkombination | Aktion                           |
|-------------------|----------------------------------|
| `<CR>`            | Öffnet Dokumentation für Symbol  |
| `y`               | Kopiert Symbol-Namen in Register |
| `q` / `<Esc>`     | Schließt Liste                   |

## Konfiguration

Standardkonfiguration kann über `uv_doc.config` angepasst werden:

```lua
local uv_doc = require("usrcmds.uv_doc")
local config = require("usrcmds.uv_doc.config")

-- Konfiguration anpassen
config.set({
  open = "float",        -- "float" oder "split"
  max_bytes = 512 * 1024, -- Max. HTTP-Response-Größe
  timeout = 15000,        -- HTTP-Timeout in Millisekunden
  user_agent = "uvdoc.nvim/0.4",
})

-- User-Commands registrieren
uv_doc.enable_usercmd()
```

## Architektur

### Modulare Struktur

```
usrcmds/uv_doc/
├── init.lua           # Haupteinstiegspunkt mit Lazy-Loading
├── @types.lua         # Typdefinitionen
├── cache.lua          # Session-Caching
├── completion.lua     # Command-line Completion
├── config.lua         # Konfigurationsverwaltung
├── constants.lua      # URLs und Konstanten
├── fetcher.lua        # Genindex-Aggregation
├── http.lua           # HTTP-Client
├── insert.lua         # Signatur-Insertion
├── normalize.lua      # Symbol-Normalisierung
├── parser.lua         # HTML/RST-Parsing
├── search.lua         # Fuzzy-Search
└── ui.lua             # UI-Rendering
```

### Design-Prinzipien

**Single Responsibility:** Jedes Modul hat genau eine Aufgabe.

**Lazy-Loading:** Submodule werden nur bei Bedarf geladen, um Startup-Zeit zu minimieren.

**Performance-Optimierung:**
- Array-Vorreservierung für bekannte Größen
- `table.concat` statt String-Konkatenation
- Lokale Funktionsreferenzen in Hot-Paths
- Session-scoped Caching mit `lib.memo`

**Error Handling:**
- Type Guards vor allen kritischen API-Calls
- `pcall` Wrapping bei `vim.api.*` Operationen
- Strukturierte Fehlerbehandlung mit `lib.notify`

## Unterstützte Eingabeformate

Die Symbole können in verschiedenen Formaten angegeben werden:

| Format              | Beispiel              | Wird zu           |
|---------------------|-----------------------|-------------------|
| Kanonisch           | `uv_timer_start`      | `uv_timer_start`  |
| vim.uv              | `vim.uv.timer_start`  | `uv_timer_start`  |
| vim.loop (Legacy)   | `vim.loop.new_tcp`    | `uv_tcp_init`     |
| Constructor Pattern | `new_timer`           | `uv_timer_init`   |
| Shorthand           | `cwd`                 | `uv_cwd`          |
| Kategorie-Prefix    | `fs`                  | `uv_fs_*`         |

## Fuzzy-Search-Kategorien

Häufig verwendete Präfixe für die Suche:

| Query      | Expandiert zu  | Beschreibung                |
|------------|----------------|-----------------------------|
| `loop`     | `uv_loop_*`    | Event-Loop-Funktionen       |
| `fs`       | `uv_fs_*`      | Filesystem-Operationen      |
| `fs_event` | `uv_fs_event_*`| Filesystem-Event-Watching   |
| `tcp`      | `uv_tcp_*`     | TCP-Socket-Operationen      |
| `udp`      | `uv_udp_*`     | UDP-Socket-Operationen      |
| `pipe`     | `uv_pipe_*`    | Pipe/IPC-Operationen        |
| `timer`    | `uv_timer_*`   | Timer-Funktionen            |
| `process`  | `uv_*`         | Prozess-Verwaltung          |
| `signal`   | `uv_signal_*`  | Signal-Handling             |

## Beispiel-Workflow

```lua
-- 1. Fuzzy-Search nach Timer-Funktionen
:UVDocList timer

-- 2. Navigation mit j/k, Auswahl mit <CR>
-- 3. Dokumentation wird in Float geöffnet

-- 4. Signatur direkt einfügen
:UVDocHere uv_timer_start
-- Fügt ein:
-- ```c
-- int uv_timer_start(uv_timer_t* handle, uv_timer_cb cb, uint64_t timeout, uint64_t repeat)
-- ```

-- 5. Cache bei Bedarf leeren
:UVDocCacheClear
```

## Integration mit /lib

Das Modul nutzt intensiv die `/lib`-Bibliothek:

- `lib.strings` – Sichere String-Operationen
- `lib.memo` – Memoization für teure Berechnungen
- `lib.notify` – Konsistente Fehlerbehandlung
- `lib.lazy` – Lazy-Loading-Wrapper

## Troubleshooting

### "genindex unavailable"

**Ursache:** HTTP-Request fehlgeschlagen oder Timeout.

**Lösung:**
- Internetverbindung prüfen
- `curl` Installation verifizieren
- Timeout erhöhen: `config.set({timeout = 30000})`

### "no uv_* anchors found"

**Ursache:** Genindex wurde geparst, aber keine Symbole gefunden.

**Lösung:**
- Cache leeren: `:UVDocCacheClear`
- Manuelle Überprüfung der URL: https://docs.libuv.org/en/v1.x/genindex.html

### "function signature not found"

**Ursache:** RST-Parsing konnte Signatur nicht extrahieren.

**Lösung:**
- Fallback auf Typ-Extraktion wird automatisch versucht
- Bei Persistenz: Bug-Report mit Symbol-Name

## Performance-Hinweise

**Erste Anfrage:** Langsam (HTTP-Fetch + Parsing)
- Genindex-Aggregation: ~500ms–2s
- Symbol-Extraktion: ~50–100ms

**Folgende Anfragen:** Schnell (Cache-Hit)
- Symbol-Lookup: <10ms
- RST-Fetch: 200–500ms (nicht gecacht)

**Optimierungen:**
- Genindex wird nur einmal pro Session geladen
- Symbol-Liste wird im Speicher gehalten
- Lazy-Loading minimiert Startup-Overhead

## Lizenz und Quellen

Die Dokumentation stammt von der offiziellen libuv-Website:
https://docs.libuv.org/en/v1.x/

Dieses Modul ist Teil einer privaten Neovim-Konfiguration und steht unter keiner spezifischen Lizenz.

## Verwandte Dokumentation

- `:h luvref.txt` – Neovim's eingebaute libuv-Referenz
- `:h vim.uv` – vim.uv API-Dokumentation
- `:h vim.loop` – Legacy vim.loop API

---


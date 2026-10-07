# `terminal.nvim` — Konzept (Arbeitstitel)

Angelegt 2026-10-07 aus der Notiz `TMUX_WEZTERM_USW.md`:

> nvim-Terminal-Plugin, das tmux-Funktionalität bzw. tmux einbindet, auch
> wezterm einbindet (z. B. Statusline), bzw. umgekehrt wezterm bindet die
> nvim-Statusline ein. `terminal.lua` ersetzen.

Status: **in Umsetzung** (Repo `StefanBartl/terminal.nvim`, Plan und Tasks im Wkdbook `terminal.nvim/`).
Ursprünglicher Arbeitstitel war `mux.nvim`; seit 2026-10-07 heißt es `terminal.nvim`
(Modul `terminal`, Command `:Terminal`). Die UserVar-Namen des Protokolls behalten
das Präfix `MUX_`.

---

## 1. Ist-Zustand (verifiziert)

| Was | Wo | Befund |
|---|---|---|
| „terminal.lua" | `lua/bindings/mappings/terminal.lua` | `<Esc>`/`<C-c>` verlassen Terminal-Mode, `<C-hjkl>` Fensterwechsel, `<A-l>` clear, `<A-h>` = **`Snacks.terminal.toggle`** als Float. Kein eigener Zustand, keine benannten Terminals. |
| Terminal-Autocmds | `lua/bindings/autocmds/terminals/` | Fenster-Optionen normalisieren, Auto-Insert, Kitty-Padding. |
| Helfer | `lib.nvim.terminal` | nur `escape`, `is_terminal_buf`, `delete_terminal_buf`, Kitty-Check. |
| Pipe-Server | `lib.nvim.system.rpc_pipe` | startet unter Windows eine Named Pipe mit vorhersagbarem Namen — Grundlage, um nvim von außen anzusprechen. |
| tmux-Config | `$REPOS_DIR/Configs/terminals/tmux/tmux.conf` | TPM, `vim-tmux-navigator`, `tmux-resurrect` (nvim-Strategie `session`), `treemux`, Status-Right mit Prefix-Highlight. **tmux ist auf diesem Rechner nicht installiert** (nur WSL vorhanden). |
| WezTerm-Config | `$REPOS_DIR/Configs/terminals/wezterm/` | `config/tabtitle.lua` erkennt nvim über Prozessname/Titel (heuristisch), `update-right-status` ist aktuell leer. |
| Statusline | `ui.nvim/lua/ui/statusline/` (`modules/`, `catalog.lua`, `render.lua`) | Modul-Katalog vorhanden → Segmente lassen sich wiederverwenden statt neu bauen. |

**Folgerung:** WezTerm ist der Primär-Host (Windows), tmux ist Sekundär
(WSL/SSH/Linux-Maschinen). Das Design darf tmux nicht voraussetzen.

---

## 2. Leitidee

Ein **Backend-Abstraktions-Plugin**: nvim spricht eine einheitliche
Pane-/Tab-/Statusline-API, hinter der austauschbare Backends stehen.

```
                 terminal.nvim  (API: terminals, panes, status, navigate)
                      │
   ┌──────────────────┼───────────────────┐
 native             wezterm              tmux
 (nvim :terminal)   (wezterm cli +       (tmux CLI, -L Socket,
                     OSC 1337 UserVars)   optional control mode)
```

Auto-Erkennung: `$TMUX` → tmux, `$WEZTERM_PANE` → wezterm, sonst native.
Verschachtelt (tmux in WezTerm) → beide Backends aktiv, Status geht an beide.

### Was es **nicht** sein soll

- Kein tmux-Klon. Ein nvim-`:terminal` stirbt mit nvim; echte Detach-
  Persistenz leistet nur ein externer Multiplexer. Statt das nachzubauen:
  **„Pin to backend"** — ein Terminal wird in einen WezTerm-/tmux-Pane
  ausgelagert und überlebt nvim (siehe 3.3).
- Kein Ersatz für `sessions.nvim` — nur Andockpunkt (3.5).

---

## 3. Funktionsblöcke

### 3.1 Terminal-Manager (ersetzt `terminal.lua` + Snacks-Abhängigkeit)

- Benannte, persistente Terminals pro Projekt: `:Terminal open <name>`, Toggle,
  Picker (`pickers.nvim`) über alle Terminals.
- Layouts: float / split / vsplit / tab; Größe & Border aus Config.
- Mappings aus `terminal.lua` wandern ins Plugin (Terminal-Mode-Esc,
  Fensternavigation, clear) — die Datei wird zum Einzeiler `require("terminal").setup()`.
- `send`: Zeile/Selektion/Datei/Befehl an ein Terminal (REPL-Workflow), mit
  Shell-Quoting über `lib.nvim` (Windows-Fallen siehe Abschnitt 6).
- `run`: Kommando in benanntem Terminal ausführen → Andockpunkt für
  `testing.nvim`, `tasks.nvim`, `dap.nvim` („Ziel: Terminal statt Job").
- Kitty-Autocmds aus `autocmds/terminals/` werden Teil des `native`-Backends.

### 3.2 nvim → Multiplexer: Statusline/Titel exportieren

nvim veröffentlicht einen kleinen, **versionierten Status-Datensatz**
(`mode`, `file`, `branch`, `diagnostics`, `recording`, `cwd`, `session`,
`pipe`):

- **WezTerm:** OSC 1337 `SetUserVar` (nvim kann das direkt auf stdout
  schreiben; siehe Memory „Bilder in nvim: nur OSC 1337"). WezTerm liest per
  `pane:get_user_vars()` in `update-right-status` / `format-tab-title`.
- **tmux:** `tmux set -g @nvim_mode …` bzw. pane-lokal `set -p`, im
  `status-right` als `#{@nvim_mode}` nutzbar. Aktualisierung entprellt
  (`lib.nvim.debounce`), nur bei Änderung senden.
- **Segmente kommen aus `ui.nvim`** (Statusline-Katalog) — gleiche Quelle,
  keine zweite Berechnungslogik; ohne `ui.nvim` kleiner Eigen-Satz.

### 3.3 Multiplexer → nvim: WezTerm-/tmux-Seite

Liegt als Gegenstück im Config-Repo (`Configs/terminals/…`), nicht im Plugin:

- `wezterm/config/nvim_status.lua`: rendert die UserVars als Right-Status und
  Tab-Titel; ersetzt die Heuristik in `tabtitle.lua` durch `is_nvim` aus
  UserVar `MUX_NVIM=1` (zuverlässig, unabhängig vom Prozessnamen).
- **Seamless Navigation** (wie `vim-tmux-navigator`, aber für WezTerm):
  WezTerm-Key prüft `is_nvim`; wenn ja → Taste durchreichen, nvim wechselt
  Fenster, und am Rand ruft `terminal.nvim` `wezterm cli activate-pane-direction`.
  tmux-Variante analog (`tmux select-pane`).
- **Pin to backend:** `:Terminal pin` startet den Terminal-Befehl via
  `wezterm cli split-pane` / `tmux split-window` im Multiplexer und schließt
  den nvim-Buffer; `:Terminal adopt` holt ihn als Link-Buffer zurück (nur Anzeige,
  kein Prozess-Transfer — ehrlich dokumentieren).
- WezTerm-Tastenkürzel können nvim ansprechen: UserVar `MUX_PIPE` trägt die
  Pipe-Adresse → `nvim --server <pipe> --remote-send/-expr`.

### 3.4 Sichtbarkeit / Menü

- `ui.nvim`-Kit für Menü und Formulare (`:Terminal` ohne Argument → Menü).
- `:checkhealth terminal`: welche Backends erkannt, `wezterm`/`tmux` im PATH,
  Pipe erreichbar, OSC-1337-Durchleitung geprüft (tmux braucht
  `allow-passthrough on`!).

### 3.5 Anbindung an die Familie

| Plugin | Rolle | Art |
|---|---|---|
| `lib.nvim` | `system.job`, `system.rpc_pipe`, `cross.run_argv`, `notify`, `debounce`, `terminal` | **harte** Abhängigkeit (bewusst, siehe Memory) |
| `ui.nvim` | Statusline-Segmente, Menü/Kit, Float-Fenster | weich (`pcall`) |
| `pickers.nvim` | Terminal-/Pane-Picker | weich |
| `sessions.nvim` | Terminals pro Branch/Projekt wiederherstellen (Befehl + cwd, kein Prozess) | weich |
| `testing.nvim` / `tasks.nvim` / `dap.nvim` | Ziel „im Terminal ausführen" | weich, über kleine Hook-API |
| `cmdlog.nvim` | an Terminals gesendete Befehle protokollieren | weich |
| `sandbox.nvim` | Terminal in Sandbox-Kontext starten | weich |
| `images.nvim` / `media.nvim` | teilen OSC-1337-Erkennung → in `lib.nvim` heben, nicht duplizieren | Refactor |

---

## 4. Verzeichnisstruktur (hexagonal, wie die anderen Plugins)

```
lua/terminal/
  init.lua            setup(), öffentliche API
  config/             defaults, Schema (aus Konsument ableiten)
  core/               Terminal-Registry, Layout, send/run (backend-unabhängig)
  backends/
    native.lua        :terminal, Float/Split/Tab
    wezterm.lua       wezterm cli, UserVars
    tmux.lua          tmux CLI
    init.lua          Erkennung + Weiterleitung
  status/             Datensatz bauen, entprellt publizieren
  navigate.lua        Rand-Navigation über Backends
  commands.lua        :Terminal …
  health.lua
  @types/
```

Backend-Interface (klein halten): `available()`, `spawn(opts)`, `send(id, text)`,
`focus(id|dir)`, `list()`, `set_status(tbl)`, `close(id)`.

---

## 5. Phasen

1. **MVP „native":** Manager + Mappings aus `terminal.lua` übernehmen,
   Snacks-Abhängigkeit entfernen, `terminal.lua` zum Einzeiler. Tests mit
   busted gegen das Backend-Interface.
2. **WezTerm-Export (3.2) + Gegenstück `nvim_status.lua`** — größter Alltagsnutzen
   (Statusline im Tab/Right-Status), braucht kein tmux.
3. **Seamless Navigation WezTerm ↔ nvim** (inkl. Gegenstück in der WezTerm-Config).
4. **tmux-Backend** (Test unter WSL; Passthrough-Fallen).
5. **Pin to backend / adopt**, `sessions.nvim`-Anbindung, `run`-Hooks für
   testing/tasks/dap.
6. Health, Doku, CI-Anschluss (Flotten-Konventionen), README im Familien-Stil.

---

## 6. Risiken / bekannte Fallen (aus Memory)

- **Windows-nvim-TUI = zwei Prozesse:** die Pipe gehört dem `--embed`-Kind;
  `MUX_PIPE` muss aus `vim.v.servername` des laufenden Prozesses kommen, nicht
  aus dem Wrapper.
- **Shell-Quoting/PS 5.1:** `$args`-Parameter, leere `-ArgumentList`-Elemente,
  eigene Quotes → Spawn-Pfade per Dry-Run testen; Argumente als argv-Liste
  (`lib.nvim.cross.run_argv`), nie als String zusammenbauen.
- **Detach/Fokus unter Windows:** `wezterm cli` hat keinen Fokus-Zwang;
  detached Konsolen laufen nicht (siehe `windows-foreground-and-detach`).
- **OSC 1337 durch tmux:** nur mit `set -g allow-passthrough on`; sonst
  verschluckt tmux die UserVars → `health` muss das prüfen.
- **Hohe Update-Frequenz:** Status nur bei Änderung und entprellt senden,
  sonst Redraw-/Flicker-Last (vgl. `nvim_set_hl erzwingt Full-Redraw`).
- **Doppelte Wahrheit:** Segmentlogik nur in `ui.nvim`; sonst driftet die
  Statusline (vgl. ui.kit/lib-Drift-Wächter).

---

## 7. Offene Entscheidungen (für dich)

- [ ] **Name:** `terminal.nvim` ok?
- [ ] **Scope Phase 1:** nur `terminal.lua` ersetzen, oder gleich Backends?
  (Empfehlung: erst native + WezTerm-Export, tmux später — kein tmux hier.)
- [ ] **Eigenes Repo vs. Modul in `ui.nvim`:** Empfehlung eigenes Repo, weil
  Backends/CLI-Handling nichts mit UI-Rendering zu tun haben.
- [ ] **OSC-1337-Erkennung** aus `images.nvim`/`media.nvim` nach `lib.nvim`
  heben (Refactor-Voraussetzung)?
- [ ] **Pin/Adopt:** gewünscht, oder reicht „im Multiplexer starten"?
- [ ] Bleibt `Snacks.terminal` als optionales Fallback-Backend?

# Implementationsplan: `lib.nvim.output` (notify/echo/viewer) + Popup-Erweiterung

Stand: 2026-09-27 · Status: **Plan, noch nichts umgesetzt** · Grundlage: Reports
[00](./00_notify_initial_task_lib.md), [01](./01_notify_last_messge.md),
[02](./02_notify-popup-migration-analyse-2026-09-25.md),
[03](./03_notify_echo_progress.md), [04](./04_notify_output_konzept.md)

Dieser Report macht das Konzept aus Report 04 konkret ausführbar: Dateien,
Funktionssignaturen, Config-Schema, Tests, Doku-Ziele, Akzeptanzkriterien pro
Phase. Ich habe dafür den aktuellen Code gegengeprüft (`lua/lib/nvim/notify/`,
`lua/lib/nvim/progress/`, `lua/lib/nvim/bindings/usercmd/composer/`,
`lua/lib/nvim/ui/kit/viewer.lua`) — alle Datei-/Funktionsnamen unten existieren
so oder sind neu, nichts geraten.

## 1. Offene Punkte aus Report 04 — jetzt aufgelöst

| # | Frage aus Report 04 | Auflösung |
|---|---|---|
| 1 | Modulname `output` vs. `emit`/`say` | **`lib.nvim.output`** (Default bestätigt, kein Widerspruch nötig) |
| 2 | `docs/NOTES/BINDINGS` existiert nicht | Falsche Annahme im Report — lib.nvim hat bereits ein eigenes **`docs/BINDINGS.md`** (Analog zur nvim-config, siehe deren `docs/BINDINGS.md:1-7`: "Every personal plugin carries the same kind of page as its own `docs/BINDINGS.md`"). Neue Routen/Keymaps kommen dort hinein, nicht in die nvim-config |
| 3 (neu, beim Gegenchecken gefunden) | `:LibNotify last\|history\|clear` als eigener Verb-Name | **Verfeinerung:** `lua/lib/nvim_usrcmds/usrcmds.lua` registriert bereits den zentralen `:Lib <subcommand>`-Verb über `lib.nvim.bindings.usercmd.composer`, genau für diesen Fall ("ein zweiter Top-Level-Name für ein untergeordnetes Feature ist genau das Muster, das composer ersetzen soll"). Neue Befehle werden **Routen unter `:Lib notify …`**, kein neuer Top-Level-Verb. `:LibNotifyScan` (Dev-Tool, separat) bleibt unangetastet, das ist bewusst ein Opt-in-Dev-Befehl, kein Teil des `:Lib`-Verbs |

## 2. Phase P0 — `lib.nvim.notify.popup` erweitern

**Datei:** `lua/lib/nvim/notify/popup.lua`

### 2.1 Config-Schema (ersetzt die Modulkonstanten `WIDTH`/`MAX_LINES`/`TOAST_INPUT_MAX`/`ENTRY_MAX`, Zeilen 32-38)

```lua
---@class Lib.Notify.Popup.Config
---@field messages boolean
---@field max_lines integer          -- default 12
---@field width integer              -- default 38
---@field toast_max_bytes integer    -- default 4000
---@field entry_max_bytes integer    -- default 64*1024
---@field toast_min_level integer    -- default vim.log.levels.INFO
---@field timeouts table<integer,integer>  -- per-level ms, merged over LEVELS[*].timeout
---@field history_full boolean       -- default false: history entries collapsed like the toast
local config = {
  messages = true,
  max_lines = 12,
  width = 38,
  toast_max_bytes = 4000,
  entry_max_bytes = 64 * 1024,
  toast_min_level = vim.log.levels.INFO,
  timeouts = {},
  history_full = false,
}
```

`M.setup(opts)` (Zeile 256) übernimmt zusätzlich diese Felder (nicht nur
`messages`). `wrap()` (Zeile 68) und `deliver()` (Zeile 210) lesen `config.*`
statt der Konstanten; `deliver`/`create` erlauben weiterhin Overrides pro
Aufruf (`opts.max_lines`, `opts.toast_max_bytes` — analog zu `opts.timeout`,
das es schon gibt).

**`toast_min_level`-Gate:** in `deliver()` wird die History- und
`:messages`-Schreibung **immer** ausgeführt (unverändert); nur der
`show_toast`-Aufruf (Zeile 248) wird übersprungen, wenn `level <
(opts.toast_min_level or config.toast_min_level)`. Chatty Plugins wie
`lsp.nvim` (63 Erzeugungsstellen, Report 02 §3) verstopfen die Ecke damit
nicht, tauchen aber weiter in `:messages`/History auf.

### 2.2 `expand_last()` und History-Toggle

- Zusätzlicher State: `local last_entry = nil` (Referenz auf den zuletzt via
  `deliver()` angehängten Eintrag).
- `M.expand_last()`: öffnet `last_entry.message` **ungekürzt** über
  `require("lib.nvim.ui.kit.viewer").open({ lines = vim.split(last_entry.message, "\n", {plain=true}), title = last_entry.source or "notify" })`
  (Viewer existiert bereits, `lua/lib/nvim/ui/kit/viewer.lua:39`, liefert
  read-only + yankbar + `q`/`<Esc>` schließt out of the box — keine
  Neuimplementierung nötig). Kein Eintrag vorhanden → No-op (kein Fehler).
- **Toast-Hinweiszeile bei Kürzung:** `wrap()` hängt bei Truncation aktuell
  `"... (full text: the popup history)"` an (Zeile 109) — Text ändern auf
  `"... (:Lib notify last)"`, damit der Hinweis den tatsächlichen Befehl nennt.
- **History gekürzt/voll:** `M.show_history()` (Zeile 299) rendert aktuell
  `entry.message` komplett. Neu: wenn `not config.history_full`, jede
  `entry.message` vor dem Rendern durch dieselbe `wrap()`-Logik (ohne
  Toast-Breite, sondern volle Fensterbreite oder eine großzügige Konstante,
  z. B. 120 Spalten) auf `config.max_lines` kürzen und `"[+N lines, <C-s>]"`
  anhängen, `N = ursprüngliche Zeilenzahl - max_lines`.
- **`<C-s>` buffer-lokal:** in `show_history()`, nach dem bestehenden
  `q`-Keymap (Zeile 331-336), zusätzlich
  `vim.keymap.set("n", "<C-s>", function() ... end, { buffer = buf, nowait = true })`,
  das `config.history_full` toggelt und den Buffer **neu rendert** (Inhalt
  ersetzen via `nvim_buf_set_lines`, `modifiable` kurz umschalten). Das ist
  ein globaler Toggle (wirkt auf alle offenen/künftigen History-Buffer), keine
  Duplizierung der Renderlogik — beide Renderpfade (initiales Öffnen, Toggle)
  rufen dieselbe interne `render_history_lines(source)`-Funktion.
- `M.toggle_full()`: öffentliche Funktion, die denselben Toggle+Re-Render
  auslöst wie `<C-s>` — für einen optionalen globalen Keymap in der
  Installations-Spec des Nutzers (siehe P3).

### 2.3 Tests

**Datei:** `TESTS/notify_popup_spec.lua` (bestehend, erweitern) — Muster wie
Zeilen 1-60: `with_stubs` für `ui.kit.toast`/`ui.notify`.

- `toast_min_level`: `deliver(msg, DEBUG)` mit `toast_min_level = INFO` →
  `opened` (Stub-Capture) bleibt `nil`, aber `#popup.history() == 1`.
- Konfigurierbare Kappung: `popup.setup({ max_lines = 2 })`, prüfen dass
  `opened.message` (die an `toast.open` übergebenen Zeilen) `#== 2` hat.
- `expand_last()`: nach `deliver("a\nb\nc", ...)`, `expand_last()` aufrufen und
  prüfen, dass `ui.kit.viewer.open` (gestubbt) mit den vollen 3 Zeilen
  aufgerufen wird.
- `history_full`/`<C-s>`-Toggle: `show_history()` öffnet Buffer, Inhalt prüfen
  (gekürzt), `<C-s>` simulieren (`nvim_feedkeys` oder direkt
  `M.toggle_full()` + Re-Open), Inhalt erneut prüfen (voll).
- **Wichtig (Risiko aus Report 04 §7):** `popup.setup({...})` verändert
  Modul-globalen State — jeder Testblock muss ihn am Ende auf die
  Ausgangswerte zurücksetzen (`popup.setup({ max_lines = 12, ... })` o. ä.),
  sonst bluten Testfälle ineinander (dieselbe Fußangel wie `popup.clear()` am
  Dateianfang, Zeile 7).

### 2.4 `require("lib.nvim.notify").setup({ popup = true })` — globaler Default

**Datei:** `lua/lib/nvim/notify/init.lua`

- Neu: Modul-lokaler State `local default_popup = false` plus
  `function M.setup(opts) if opts.popup ~= nil then default_popup = opts.popup end end`.
- `M.create()` (Zeile 23): `local popup = create_opts and create_opts.popup` →
  `local popup = create_opts and create_opts.popup; if popup == nil then popup = default_popup end`.
  Wichtig: **zur Aufrufzeit** in `notifier.notify()` auflösen (Zeile 46), nicht
  beim `create()`-Aufruf — sonst gilt für früh erzeugte Notifier (z. B.
  Modul-Top-Level `local notify = require(...).create(...)`, das über die
  Repos hinweg der Standard-Wrapper-Stil ist, Report 02 §3) der zum
  Ladezeitpunkt gültige Default, nicht der zur Laufzeit aktuelle. Das ist
  exakt die "load-time binding umgeht später gesetzte Hooks"-Fußangel aus dem
  initialen Auftrag (Report 00, Zeile 36), nur eine Ebene höher.
- Test: `TESTS/notify_popup_spec.lua` oder neue `TESTS/notify_init_spec.lua` —
  `create()` **vor** `setup({popup=true})`, dann `notifier.info(...)` aufrufen
  → landet trotzdem im Popup-Pfad (beweist Aufrufzeit-Auflösung, nicht
  Erzeugungszeit).

### 2.5 `:Lib notify …` — Composer-Routen

**Datei:** `lua/lib/nvim_usrcmds/usrcmds.lua`, Funktion `M.lib_verb` (Zeile 44)

```lua
routes[#routes + 1] = {
  path = { "notify", "last" },
  desc = "Show the last delivered message in full (viewer)",
  run = function() require("lib.nvim.notify.popup").expand_last() end,
}
routes[#routes + 1] = {
  path = { "notify", "history" },
  args = { { name = "source", type = "STRING", optional = true } },
  desc = "Open the notify history (optionally filtered by source)",
  run = function(ctx) require("lib.nvim.notify.popup").show_history(ctx.args.source) end,
}
routes[#routes + 1] = {
  path = { "notify", "clear" },
  args = { { name = "source", type = "STRING", optional = true } },
  desc = "Clear the notify history (optionally by source)",
  run = function(ctx) require("lib.nvim.notify.popup").clear(ctx.args.source) end,
}
```

Kein neues `o.notify`-Feature-Flag nötig (anders als `o.powershell_profile`/
`o.deps`, Zeile 53/64): Notify-Verwaltung ist immer sinnvoll verfügbar, sobald
`lib.nvim_usrcmds` überhaupt geladen wird.

### 2.6 Doku

- `lua/lib/nvim/notify/README.md`: Abschnitt zu `setup({popup=true})` global,
  Kappungs-Config, `:Lib notify last|history|clear`, `<C-s>`-Toggle.
- `docs/BINDINGS.md` (lib.nvim, nicht nvim-config): neue Zeile für die drei
  `:Lib notify …`-Routen (User Commands-Sektion) und den buffer-lokalen
  `<C-s>` (im History-/Viewer-Buffer, `notify://…`-Filetype).
- Composer kann das sogar automatisch: `handle:document()` (README Zeile
  315-318) schreibt die Routen-Doku aus dem Tree — prüfen, ob `:Lib` das
  schon nutzt (falls ja, reicht die Routen-Ergänzung, die Doku zieht nach).

**Akzeptanzkriterium P0:** `luacheck`/`stylua` grün, alle Tests grün,
`:Lib notify last|history|clear` funktioniert manuell, `notify.setup({popup=true})`
schaltet bestehende `create()`-Aufrufe (z. B. in einer Testdatei simuliert)
ohne Plugin-Änderung um.

## 3. Phase P1 — `lib.nvim.echo` und `lib.nvim.output.viewer` (neu)

### 3.1 `lua/lib/nvim/echo/init.lua` (neu)

```lua
---@param text_or_chunks string|{[1]:string,[2]:string}[]
---@param opts? { level?: integer, history?: boolean }
function M.write(text_or_chunks, opts) end
```

- Baut auf demselben Fast-Event-Schedule wie `popup.write_messages`
  (`popup.lua:156-169`) — **Code-Dopplung vermeiden**: die
  `vim.in_fast_event() → vim.schedule(...)`-Reentry-Guard-Funktion aus
  `popup.lua` in ein gemeinsames internes Modul heben (Schicht 0 aus Report
  04 §2), z. B. `lua/lib/nvim/notify/internal/fast_event.lua`, von `popup.lua`
  UND `echo/init.lua` genutzt. Ohne diese Extraktion entsteht sofort die Art
  Duplikat, die Report 02 bei `sessions.nvim` (7 fast identische Wrapper)
  kritisiert — nur diesmal im lib selbst.
- `history = false` (Default für Zwischenstände) → `nvim_echo(chunks, false, {})`.
  `history = true` (Default für Endergebnis, explizit gesetzt) →
  `nvim_echo(chunks, true, {})`, plus optional Eintrag in `popup.history()`
  (gemeinsame History, Report 04 §2: "der Synergieeffekt liegt … in **einer**
  History").
- **Feature-Detection für `nvim_echo`-Optionen (`id`, `kind="progress"`,
  `status`, `percent`)** — *vor* der Umsetzung mit
  `vim.fn.has("nvim-0.11")` o. ä. gegen die tatsächlich unterstützte
  Neovim-Version prüfen (Report 04 §7: "nvim_echo-Optionen sind
  versionsabhängig"). Das ist der einzige Punkt in diesem Plan, der eine
  Versionsrecherche **vor** dem Schreiben von Code braucht, nicht danach —
  in Runde 1 von P1 zuerst `:version` / `:h nvim_echo` in der Ziel-Neovim
  prüfen, dann erst den Progress-Style (P2) darauf aufbauen.

### 3.2 `lua/lib/nvim/output/viewer.lua` (neu)

```lua
---@param title string
---@param lines string[]
---@param opts? table  -- durchgereicht an ui.kit.viewer.open
function M.show_lines(title, lines, opts) end
```

Dünner Wrapper um das **bereits vorhandene**
`require("lib.nvim.ui.kit.viewer").open({ lines = lines, title = title })`
(`lua/lib/nvim/ui/kit/viewer.lua:39`) — keine neue Fenster-/Buffer-Logik,
nur eine stabile, dump-taugliche Signatur (`title, lines` statt
`opts`-Tabelle) für die spätere `print`-Migration (P6).

### 3.3 `lua/lib/nvim/output/init.lua` (neu, die Fassade)

```lua
---@alias Lib.Output.Channel "popup"|"echo"|"vim_notify"

local channels = {}  -- registry: name -> notifier-factory

function M.register_channel(name, factory) channels[name] = factory end

---@param prefix string
---@param opts? { channel?: Lib.Output.Channel }  -- default "popup"
---@return table notifier  -- gleiche Form wie lib.nvim.notify.create: info/warn/error/debug/notify, plus dump(lines, title)
function M.create(prefix, opts) end
```

- Default-Kanal **immer explizit `"popup"`**, keine Heuristik (Entscheidung
  aus Report 04 §1: "Auto-Wahl des Kanals: Keine").
- `channels.popup` delegiert an `require("lib.nvim.notify").create(prefix, {popup=true, ...})`,
  `channels.vim_notify` an `require("lib.nvim.notify").create(prefix)`,
  `channels.echo` an einen neuen Notifier-Adapter um `lib.nvim.echo.write`.
- `notifier.dump(lines, title)` → `require("lib.nvim.output.viewer").show_lines(title, lines)`
  auf jedem Kanal identisch (das ist der Ersatz für `print`, Report 04 §2:
  "Kein Kanal `print`").
- **Headless-Fallback:** `#vim.api.nvim_list_uis() == 0` → alle Kanäle
  fallen auf `print`/`io.stderr:write` zurück (Report 04 §2, letzter Punkt).
  Wiederverwendbar: dieselbe Prüfung existiert vermutlich schon irgendwo für
  CI-Läufe — vor dem Schreiben kurz grep nach `nvim_list_uis` im Repo, um
  keine zweite Variante davon einzuführen.

### 3.4 Tests

- `TESTS/echo_spec.lua`: `history=false` vs. `true` (Stub `nvim_echo`,
  Argumente prüfen), Fast-Event-Reentry (Stub `vim.in_fast_event() = true`,
  `vim.schedule` capturen).
- `TESTS/output_spec.lua`: `create(prefix, {channel="echo"})` liefert
  `info/warn/error/debug/dump`; `register_channel` mit einem Test-Kanal;
  Default ohne `channel`-Angabe ist nachweislich `"popup"` (Stub prüfen, dass
  `notify.popup.deliver` aufgerufen wird, nicht `vim.notify` direkt).
- `TESTS/output_viewer_spec.lua`: `show_lines` ruft `ui.kit.viewer.open` mit
  den erwarteten `lines`/`title` auf (Stub, analog zu `notify_popup_spec.lua`).

### 3.5 Doku

- Neues `lua/lib/nvim/echo/README.md`, `lua/lib/nvim/output/README.md`
  (Modul-Konvention: jedes lib.nvim-Modul hat eins, siehe
  `notify/README.md`, `progress/README.md`).
- `docs/modules.md` / `docs/MODULE_AUDIT.md` (lib.nvim-weite Modulübersicht,
  existiert bereits) um `echo` und `output` ergänzen.

**Akzeptanzkriterium P1:** `require("lib.nvim.output").create("[x]", {channel="echo"}).info(...)`
zeigt eine flüchtige Cmdline-Zeile ohne History-Eintrag;
`.dump({...}, "title")` öffnet den Viewer; alles luacheck/stylua-grün,
getestet.

## 4. Phase P2 — Progress-Style `echo` + Style-Liste

**Dateien:** `lua/lib/nvim/progress/styles/echo.lua` (neu),
`lua/lib/nvim/progress/resolve_style.lua`, `lua/lib/nvim/progress/init.lua`

- `styles/echo.lua` implementiert denselben Vertrag wie `styles/statusline.lua`
  (`start(spec, opts, request_cancel) -> state`, `update(state, spec, opts) -> state`,
  `finish(state, spec, opts)`, `cancel(state, spec, opts)` — siehe
  `@types/init.lua:28-32`), rendert über `lib.nvim.echo.write(chunks, {history=false})`
  bei `update`, und einmalig `history=true` bei `finish`/`cancel` (das
  "Abschluss-Nachricht bleibt im Log"-Muster aus Report 03).
- `resolve_style.lua` (Zeile 12-43): neuer Zweig `if want == "echo" then return require(...) end`,
  analog zu `"statusline"` (Zeile 13-15) — kein Soft-Dependency-Check nötig,
  `nvim_echo` ist Core-API.
- **Style-Liste:** `lib.nvim.progress` `create(opts)` (init.lua Zeile 65)
  nimmt `opts.style` heute als **einen** Wert (`resolve_style(opts.style or "auto")`,
  Zeile 69). Für `opts.style = {"statusline", "echo"}` (Report 04 §4, letzter
  Punkt) muss `create()` **mehrere** `style_state`s parallel führen: aus
  `local style_state = nil` wird `local style_states = {}` (Liste), aus
  `style.start(...)`/`.update(...)`/`.finish(...)`/`.cancel(...)`
  (Zeilen 91, 133, 149, 164) werden Schleifen über alle aufgelösten Styles.
  **Rückwärtskompatibel:** ein String-`opts.style` wird zu einer
  Einzel-Element-Liste normalisiert, bestehende Aufrufer (`style = "notify"`
  etc.) ändern sich nicht.
- `@types/init.lua`: `Lib.Progress.Opts.style` Alias erweitern auf
  `Lib.Progress.Style|Lib.Progress.Style[]`.

### Tests

- Neue `TESTS/progress_echo_style_spec.lua` (falls noch keine `progress_*`-Specs
  existieren — beim Schreiben prüfen, ob es bereits Tests für `progress/init.lua`
  gibt und deren Konventionen übernehmen statt eine neue Struktur zu erfinden).
- Style-Liste: `create({style = {"statusline", "echo"}})`, `update(...)`
  aufrufen, prüfen dass **beide** Styles ihre `update`-Funktion mit demselben
  `spec` erhalten (zwei Stubs, zwei Call-Counts).

**Akzeptanzkriterium P2:** ein Handle mit `style = {"statusline", "echo"}`
zeigt Statusline-Badge UND eine Cmdline-Zeile für dieselbe Operation, ohne
doppelten Aufruferseitigen Code.

## 5. Phase P3 — Aktivierung in der Installations-Spec

**Datei:** `C:\Users\bartl\AppData\Local\nvim\lua\plugins\personal\init.lua`
(dort, wo lib.nvim konfiguriert wird — Stelle im Setup suchen, an der bereits
andere `lib.nvim.*`-`setup()`-Aufrufe stehen, keine neue Konvention einführen)

```lua
require("lib.nvim.notify").setup({ popup = true })
require("lib.nvim.notify.popup").setup({
  toast_min_level = vim.log.levels.INFO,
  -- max_lines/width/toast_max_bytes/entry_max_bytes: Defaults reichen erstmal
})
```

- **Offene Entscheidung, die der Nutzer selbst treffen muss (nicht mit
  Default zu lösen):** ein optionaler globaler Keymap für
  `popup.toggle_full()`/`expand_last()` zusätzlich zu `:Lib notify last`. Das
  ist eine reine Komfortfrage (der Befehl funktioniert auch ohne Taste) —
  in Runde P3 nachfragen, welche Taste (`<leader>n…`-Namespace prüfen, ob
  frei) statt eine zu raten und später revidieren zu müssen.
- Falls die Taste gewünscht wird: Eintrag in **lib.nvims** `docs/BINDINGS.md`
  (nicht nvim-config, da der Keymap `lib.nvim.bindings.keymap` durchläuft und
  von dort aus registriert würde — analog zu allen anderen lib-Aktionen,
  Report 04 §7 Punkt 3) — es sei denn, der Keymap wird in der
  Installations-Spec selbst per `vim.keymap.set` gesetzt; dann gehört er in
  die nvim-configs eigenes `docs/BINDINGS.md`. Diese Unterscheidung erst beim
  Implementieren treffen, wenn der Ort des `vim.keymap.set`-Aufrufs feststeht.

**Akzeptanzkriterium P3:** nach einem `:so` der Spec zeigen alle ~30
lib-Nutzer (Report 02 §2, Spalte `lib_notify`) Toasts, ohne dass ein Plugin
angefasst wurde — das ist der "größte Hebel" aus Report 02 §3, jetzt live.

## 6. Phase P4 — Wrapper-Repos direkt umstellen

Reihenfolge und Fundstellen **exakt wie Report 02 Abschnitt 4** (dort liegt
bereits die vollständige Datei:Zeile-Liste), hier nur die Ausführungsregel:

> Pro Repo: **den Wrapper ändern, nicht die Aufrufer** — ein Wrapper-Body,
> alle Aufrufer folgen. Reihenfolge nach Hebelwirkung (meiste Aufrufer
> zuerst): `sessions.nvim` (7 Wrapper, 20 Aufrufe) → `rules.nvim` (15,
> mehrzeilige Config-Fehler) → `mdview.nvim` (7 `nvim_echo`-Stellen,
> `ws_client.lua`) → `media.nvim` → `my.nvim` → `dap.nvim` → `sandbox.nvim`
> → `insights.nvim` → `pickers.nvim` → `diff.nvim`.

Je Repo, eine Runde (max. 1 Agent):

1. `:LibNotifyScan <repo-pfad>` vorher laufen lassen (Referenzstand).
2. Wrapper auf `require("lib.nvim.notify").create(prefix, {popup = true})`
   bzw. bei explizitem Kanalbedarf `require("lib.nvim.output").create(prefix, {channel=...})`
   umstellen (P1 muss dafür fertig sein — **P4 setzt P0-P1 voraus**, nicht
   parallelisierbar).
3. Repo-eigenen `:<Plugin> messages`-Befehl ergänzen, falls ein
   Command-Baum existiert (wie `reposcope.nvim`s `:Reposcope messages`,
   Report 00 Zeile 36) — delegiert an `popup.show_history(source)`.
4. Tests im Repo-eigenen `TESTS/`, `stylua`/`luacheck` grün.
5. `:LibNotifyScan <repo-pfad>` erneut (Verifikation: `lib_notify` steigt,
   `notify`/`echo` sinkt).
6. Commit/Push auf `main` des Repos, kein Co-Author.

**Nicht anfassen** (Report 02 §4 letzte Zeile):
`buffer-ctx.nvim/health.lua` (checkhealth), `debugging.nvim/views/debug_helper.lua:260`
(Selbsttest).

## 7. Phase P5 — Load-Time-Bindungen

Reihenfolge **wie Report 02 Abschnitt 5**: `color_my_ascii.nvim` zuerst (die
eindeutige reposcope-Fehlerklasse — 4 Stellen binden `vim.notify` beim Laden),
danach `filetree.nvim` und `sandbox.nvim` **erst auf Absicht prüfen** (dort
sind es bewusste Sicherungen des Originals für einen temporären Eingriff,
kein Bug) — vor jeder Änderung den umgebenden Code lesen, ob das Sichern
zeitlich vor oder nach einem möglichen späteren Hook passiert. `mdview.nvim`s
Fund ist der Test-Runner, ignorieren.

## 8. Phase P6 — `print`-Dumps auf `output.viewer.show_lines` umstellen

Kandidaten **wie Report 02 Abschnitt 6, erste Zeile**: `color_my_ascii`
(`debug/commands.lua`, 35 Zeilen), `replacer` (`debug.lua`, 14 Zeilen),
`lsp.nvim` (`lspdoctor/init.lua:202`), `data.nvim`, `debugging.nvim`,
`reposcope.nvim` (`usrcmds.lua`, `providers`/`queries`-Dumps).

Je Fundstelle: `print(x)` / mehrere `print(...)`-Zeilen sammeln → ein
`require("lib.nvim.output.viewer").show_lines(title, lines)`-Aufruf. Die in
Report 02 als "Einzeiler-Status, teils Debug-Rest" markierten Stellen
(`filetree/source_switcher/init.lua:410`, `fileops/usrcmds.lua:660`,
`lsp.nvim/htmx/filter_logs.lua:59`) **einzeln prüfen, nicht pauschal
migrieren** — mancher davon ist vermutlich vergessener Debug-Code und gehört
gelöscht statt migriert.

## 9. Risiken (aus Report 04 §7, mit Gegenmaßnahme)

| Risiko | Gegenmaßnahme in diesem Plan |
|---|---|
| Tests, die `vim.notify` stubben, brechen unter globalem `popup=true` | P3 aktiviert den Default erst in der Spec, nicht in lib.nvim selbst — Repo-Tests laufen weiterhin gegen `create()` ohne globalen Default, solange sie ihn nicht selbst setzen. Repos, die dennoch `vim.notify` stubben und `lib.nvim.notify` nutzen, müssen bei P4 einmalig geprüft werden |
| Toast vor erstem Redraw unsichtbar | Kein Code-Fix — dokumentieren (README), History bleibt vollständig |
| `ext_messages`-Konsumenten (noice) sehen nur `:messages` | Unverändert seit heute (`write_messages`), kein Regressionsrisiko |
| `nvim_echo`-Optionen versionsabhängig | P1 prüft die Zielversion **vor** dem Schreiben (Abschnitt 3.1) |
| Fassade darf `ui.nvim` nie hart voraussetzen | `pcall(require, ...)`-Muster aus `popup.lua:189` (`show_toast`) 1:1 übernehmen, keine neue Soft-Dependency-Technik erfinden |
| `<C-s>` buffer-lokal vs. globales Speichern | Nur `buffer = buf` in `vim.keymap.set` (Abschnitt 2.2) — betrifft nachweislich nur `notify://…`/Viewer-Buffer, dort ist Speichern ohnehin sinnlos (`nofile`) |

## 10. Reihenfolge & Agent-Takt

Strikt sequenziell, max. 1 Agent pro Runde (striktere Regel aus Report 04 §8
gilt):

```
P0 (lib.nvim, popup erweitern)
 └─ P1 (lib.nvim, echo + output-Fassade)
     └─ P2 (lib.nvim, progress-Style echo + Style-Liste)
         └─ P3 (nvim-config, Aktivierung + Tastenentscheidung mit dir)
             └─ P4 (je Wrapper-Repo, eine Runde je Repo, Reihenfolge Abschnitt 6)
                 └─ P5 (Load-Time-Bindungen, color_my_ascii zuerst)
                     └─ P6 (print-Dumps)
```

P0-P2 sind rein lib.nvim-intern und **könnten technisch parallel** entworfen
werden, laufen hier aber trotzdem nacheinander, weil P1 auf dem in P0 neu
extrahierten Fast-Event-Helper aufbaut (Abschnitt 3.1) und P2 auf dem in P1
fertigen `echo.write`. P4-P6 sind über Repos hinweg unabhängig voneinander,
aber jedes einzelne Repo bleibt eine eigene Runde (kein Multi-Repo-Batching
in einem Agent-Lauf).

**Vor dem Start von P0:** bestätigen, dass die drei aufgelösten Punkte aus
Abschnitt 1 (Modulname `output`, `docs/BINDINGS.md` statt `docs/NOTES/BINDINGS`,
`:Lib notify …`-Routen statt `:LibNotify`-Verb) so passen — das sind die
einzigen Stellen, an denen dieser Plan von Report 04 abweicht bzw. dessen
offene Punkte schließt.

# Konzept: einheitliche Ausgabe (notify / echo / viewer) + Popup-Migration

Stand: 2026-09-25 · Status: **Konzept, noch nichts umgesetzt** · Grundlage: Reports
[01](./01_notify_last_messge.md), [02](./02_notify-popup-migration-analyse-2026-09-25.md),
[03](./03_notify_echo_progress.md)

## 1. Entscheidungen (von dir getroffen)

| Frage | Entscheidung |
|---|---|
| API-Form | **Beides**: explizite Einzelmodule *und* ein Kanal-Modul obendrauf, beide teilen einen Kern |
| Auto-Wahl des Kanals | **Keine.** Kanal ist immer explizit (Default: `popup`), keine Heuristik |
| Volle Meldung bei gekürztem Toast | **Viewer** (yankbar), kein wachsender Toast |
| Taste `<C-s>` | **Buffer-lokal im Meldungs-Buffer** (History/Viewer). Globales `<C-s>` = Speichern (`lua/bindings/mappings/general.lua:21,32`) bleibt unangetastet |

Gegen "beides" spricht nichts, solange es **eine** Implementierung gibt. Dafür sorgt die
Schichtung in Abschnitt 2: Das Kanal-Modul enthält keine eigene Logik, es delegiert nur.

## 2. Architektur (Schichten, gemeinsame Bausteine)

```
Schicht 2  lib.nvim.output        Fassade: create(prefix, {channel=...}), write(channel, ...)
              |                   (keine eigene Renderlogik, nur Kanal-Registry + Defaults)
Schicht 1  lib.nvim.notify        existiert  (create/safe, vim.notify bzw. popup)
           lib.nvim.notify.popup  existiert  (Toast + History)  -> wird erweitert
           lib.nvim.echo          NEU        (flüchtig, nvim_echo ohne History, Progress-tauglich)
           lib.nvim.output.viewer NEU        (show_lines(title, lines): Dump-Ausgabe statt print)
              |
Schicht 0  gemeinsam              Level-Auflösung (resolve_log_level), Prefix-Normalisierung,
                                  Fast-Event-Schedule, Kappung/Config, Headless-Fallback
```

Regeln:

- Wer explizit will, nimmt `require("lib.nvim.notify")` / `.echo` / `.output.viewer` direkt.
- Wer eine Auswahl will, nimmt `require("lib.nvim.output").create("[p]", { channel = "echo" })`
  und bekommt dieselbe Notifier-Form (`info/warn/error/debug/notify`) plus `dump(lines, title)`.
- Kanäle sind eine Registry (`output.register_channel(name, fn)`), also erweiterbar, ohne
  die Fassade zu ändern.
- **Kein Kanal `print`.** `print` lässt sich nicht sauber abfangen und ist meist eine
  mehrzeilige Befehlsausgabe. Die Ersatzlösung ist `dump()` (Viewer). Headless (kein UI)
  fallen alle Kanäle auf `stderr`/`print` zurück, damit CLI-Läufe nichts verlieren.
- `echo` und `notify` teilen das Grundproblem (Cmdline/Fokus/more-prompt). Der Synergieeffekt
  liegt im Kern (Schicht 0) und in **einer** History, nicht in einer Heuristik.

## 3. `notify.popup` erweitern (Aufgabe aus dem Chat)

Heute sind `WIDTH`, `MAX_LINES`, `TOAST_INPUT_MAX`, `ENTRY_MAX` Modulkonstanten
(`lua/lib/nvim/notify/popup.lua:32-38`). Neu in der vorhandenen `config`-Tabelle:

```lua
require("lib.nvim.notify.popup").setup({
  messages = true,
  max_lines = 12,          -- toast lines
  width = 38,
  toast_max_bytes = 4000,  -- bytes considered when wrapping
  entry_max_bytes = 64 * 1024,
  toast_min_level = vim.log.levels.INFO, -- below: history/:messages only, no toast
  timeouts = { [vim.log.levels.ERROR] = 10000 },
  history_full = false,    -- history buffer: collapsed (max_lines/entry) vs full
})
```

- **Pro Aufruf/Notifier:** `deliver(msg, lvl, { max_lines, toast_max_bytes })` und
  `create(prefix, { popup = true, max_lines = ... })`.
- **Globaler Default:** `require("lib.nvim.notify").setup({ popup = true })`. `create()`
  liest ihn zur *Aufrufzeit*, solange `opts.popup` nicht explizit gesetzt ist. Das ist der
  Hebel für die rund 30 lib-Nutzer (Report 02, Abschnitt 3).
- **Volle Meldung:** `popup.expand_last()` öffnet die letzte Meldung ungekürzt im Viewer.
  Ein gekürzter Toast bekommt dafür die letzte Zeile `... (:LibNotify last)`.
- **`<C-s>` buffer-lokal** (nur in `notify://…` und Viewer-Buffern, `nowait`): schaltet
  gekürzt/voll um. Da der Toast nicht fokussierbar ist, führt der Weg dorthin über
  `:LibNotify last | history [source] | clear [source]`; eine globale Taste legst du bei
  Bedarf selbst in der Spec. Die History zeigt gekürzt: erste `max_lines` je Eintrag plus
  `[+N lines, <C-s>]`.
- `ui_notify_active()` bleibt: ist `ui.notify` aktiv, gibt es kein zweites Popup.

## 4. `lib.nvim.echo` (Punkt 2 deines Feedbacks)

- `echo.write(text_or_chunks, { level, history = false })`: `nvim_echo(chunks, history, {})`,
  Fast-Event-sicher (`vim.schedule`), `history = true` nur für das Endergebnis.
- Feature-Detection für die neueren `nvim_echo`-Optionen (`id`, `kind = "progress"`,
  `status`, `percent`): sind sie vorhanden, wird in place aktualisiert, sonst einfacher
  Redraw. **Vor der Umsetzung gegen die installierte Neovim-Version prüfen.**
- Neuer Progress-Style `lib/nvim/progress/styles/echo.lua` (gleicher Vier-Funktionen-Vertrag
  `start/update/finish/cancel`), Registrierung in `resolve_style.lua`.
- **Statusline-Bezug:** Der Style `statusline` existiert bereits (headless Registry), und
  `ui.nvim` liest ihn über `ui/statusline/modules/plugin_progress`. Ergänzung: `style`
  darf eine **Liste** sein (`{ "statusline", "echo" }`), ein Handle treibt mehrere Styles.
  So zeigt dieselbe Operation Statusline-Badge *und* flüchtige Cmdline-Zeile, ohne dass
  ein Plugin doppelt aufrufen muss. Optional: globales `progress.setup({ style = ... })`.

## 5. `output.viewer.show_lines` (Ersatz für `print`-Dumps)

`show_lines(title, lines, opts)` öffnet einen yankbaren Scratch-/`ui.kit.viewer`-Buffer
(`q` schließt). Ziel sind die mehrzeiligen Befehlsausgaben aus Report 02, Abschnitt 6
(color_my_ascii 35 Zeilen, replacer 14, lspdoctor, data, debugging, reposcope). Einzeiler-
`print`s werden einzeln geprüft (teils Debug-Reste, die gelöscht gehören).

## 6. Umsetzungsphasen

Jede Phase: Scan mit `:LibNotifyScan`, Tests im plugin-eigenen `TESTS/`, `stylua` und
`luacheck` grün, README/Docs mitpflegen, commit/push auf `main`, kein Co-Author.

| Phase | Inhalt | Repo |
|---|---|---|
| P0 | `popup.setup`-Erweiterung, `toast_min_level`, `notify.setup({popup})`, `expand_last`, `<C-s>`-Toggle, `:LibNotify` | lib.nvim |
| P1 | `lib.nvim.echo`, `output.viewer`, Fassade `lib.nvim.output` inkl. Kanal-Registry | lib.nvim |
| P2 | Progress-Style `echo`, Style-Liste, ggf. `progress.setup` | lib.nvim (+ ui.nvim prüfen) |
| P3 | Aktivierung in `lua/plugins/personal/init.lua`, Docs (`docs/NOTES/BINDINGS`, siehe unten) | nvim-config |
| P4 | Wrapper-Repos, je Repo eine Runde: sessions, rules, sandbox, media, my, dap, insights, mdview, diff, pickers | je Repo |
| P5 | Load-Time-Bindungen: color_my_ascii zuerst; filetree/sandbox erst auf Absicht prüfen | je Repo |
| P6 | `print`-Dumps auf `dump()` umstellen | je Repo |

## 7. Risiken

- Tests, die `vim.notify` stubben, müssen `popup = false` setzen oder `popup.deliver` stubben.
- Ein globaler Default vor dem ersten Redraw: Toast kann kurz unsichtbar sein (History bleibt).
- `ext_messages`-Konsumenten (noice) bekommen weiterhin den `:messages`-Eintrag
  (`messages = false` schaltet ab).
- `nvim_echo`-Optionen sind versionsabhängig, daher Feature-Detection und Test-Matrix.
- Die Fassade darf ui.nvim nie hart voraussetzen (soft dependency wie beim Toast).
- `<C-s>` buffer-lokal überschreibt dein globales Speichern nur in Notify-Buffern; dort ist
  Speichern sinnlos, weil `nofile`.

## 8. Offene Punkte (kleinere, ich entscheide mit Default, sofern du nichts sagst)

1. Modulname `lib.nvim.output` (Alternativen: `lib.nvim.emit`, `lib.nvim.say`). Default: `output`.
2. `docs/NOTES/BINDINGS` existiert unter `nvim/docs/NOTES/` nicht als Ordner. Ich suche die
   tatsächliche Bindings-Doku, bevor ich sie ergänze. Da nur ein Buffer-lokales `<C-s>` neu
   entsteht, ist der Eintrag klein.
3. **Agent-Limit:** In deinen Regeln stehen "max. 1" und "max. 3" gleichzeitige Agents. Ich
   nehme das strengere (1 pro Runde), bis du etwas anderes sagst.

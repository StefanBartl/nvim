# startup-probe

Misst, **wohin die Startzeit dieser Config geht**: `require`-Zeit pro Modul,
`exepath`/`executable`, `runtimepath`-Neuberechnungen von `vim.loader`,
Event-Loop-Stöße, Subprozesse, Dateisystem-Aufrufe und die Phasen der
`startup`-Policy. Gebaut für die Analyse in
`docs/ROADMAP/reports/startup-und-config-optimierung-analyse-konzept-2026-09-26.md`.

Vorher wurde so etwas jedes Mal ad hoc geschrieben und weggeworfen (die
Startup-Policy nennt den `require`-Wrapper schon). Deshalb liegt es jetzt hier.

---

## Benutzung

```bash
# alle Sonden, Bericht nach $TEMP/startup-probe.txt
nvim --headless --cmd "luafile scripts/startup-probe/probe.lua"

# nur bestimmte Sonden, anderer Ausgabeort, länger warten
PROBE=exe,rtp PROBE_OUT=/tmp/exe.txt PROBE_MS=8000 \
  nvim --headless --cmd "luafile scripts/startup-probe/probe.lua"
```

| Variable | Bedeutung | Vorgabe |
| --- | --- | --- |
| `PROBE` | Sonden, kommagetrennt | alle |
| `PROBE_MS` | Wartezeit **nach `VimEnter`** in ms | `6000` |
| `PROBE_OUT` | Berichtsdatei | `$TEMP/startup-probe.txt` |

| Sonde | Antwortet auf |
| --- | --- |
| `req` | Welches Modul kostet (exklusiv) wie viel? Welche Top-Level-`require`s blockieren lange? |
| `exe` | Wie viele PATH-Suchen, wie lange, wie viele ohne Treffer? |
| `rtp` | Wie oft berechnet `vim.loader` die `runtimepath`-Liste neu und was kostet das? |
| `stall` | Wie lange stand die Event-Loop still (Lücken > 60 ms im 10-ms-Herzschlag)? |
| `spawn` | Welche Prozesse startet der Start, was kostet der Spawn, wird blockierend gewartet? |
| `fs` | `fs_stat`, `fs_open`, `nvim_exec2` … in der Summe |
| `marks` | Wann kamen `LazyDone`, `VimEnter`, `UIEnter`? |
| `report` | Die Zeitachse aus `startup` (wie `:StartupReport`, als Text) |

---

## Warum nicht `-c "… vim.wait(…)"`

`-c`-Befehle laufen **vor** `VimEnter`. Eine Messung, die dort wartet und dann
ausgibt, sieht die `UIReady`-Phasen (`usrcmds`, `mappings`, `ui_statusline`)
und alles nach dem ersten Frame **nicht**: das Menü-Prewarm, `VeryLazy`-Plugins,
die zweite Ladewelle. Die Sonde hängt sich deshalb an `VimEnter` und schreibt
den Bericht erst `PROBE_MS` danach.

`"Config loaded in … ms"` am Ende von `init.lua` ist auch keine Antwort auf
„wann ist der Editor benutzbar": es läuft per `defer_fn(0)`, also beim ersten
Idle, und sieht weder die `UIReady`-Phasen noch die Stöße danach.

## Wie man die Zahlen liest

- **Überlappung.** Die Ladezeit eines Plugins enthält seine `require`s und
  seine `exepath`-Aufrufe; `req` und `exe` messen dasselbe von zwei Seiten.
  Als Belege für eine Ursache nehmen, nicht addieren.
- **Wrapper-Overhead.** Jede Sonde hängt einen Wrapper ein; mit allen Sonden
  sind die Summen etwa 5–10 % zu hoch. Vergleiche nur Läufe mit derselben
  Sondenmenge, für eine einzelne Frage nur diese Sonde einschalten.
- **Rauschen.** Ein Lauf schwankt um etwa ±40 ms, kalt gegen warm um Faktor
  2–3. Mehrere Läufe, Median nehmen.
- **Headless.** Kein UI, also kein `UIEnter`, kein Paint. `UIReady` (die
  Startup-Policy) feuert trotzdem, weil sie an `VimEnter` hängt.

## Bekannte Grenzen

- Die Sonde kann `vim.fn`-/`vim.api`-Aufrufe messen, die **über die Lua-Tabelle**
  gehen. Was ein Plugin vorher in einer lokalen Variable festhält
  (`local exepath = vim.fn.exepath`), sieht sie nicht; für Code, der vor
  `--cmd` lief, gilt das immer.
- Der Instruktions-Sampler (`debug.sethook` mit Zähler) sieht C-Zeit nicht und
  ist für dieses Problem ungeeignet: die Zeit steckt in `exepath` und
  `fs_stat`, nicht in Lua-Instruktionen.

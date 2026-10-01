# startup-probe

Misst, **wohin die Startzeit dieser Config geht**: `require`-Zeit pro Modul,
`exepath`/`executable`, `runtimepath`-Neuberechnungen von `vim.loader`,
Event-Loop-Stöße samt Verursacher, Prozesse, Dateisystem-Aufrufe, was
lazy.nvim wann und warum lädt, und die Phasen der `startup`-Policy. Gebaut für
die Analyse in
`docs/ROADMAP/reports/startup-und-config-optimierung-analyse-konzept-2026-09-26.md`.

Vorher wurde so etwas jedes Mal ad hoc geschrieben und weggeworfen (die
Startup-Policy nennt den `require`-Wrapper schon). Deshalb liegt es jetzt hier.

| Datei | Rolle |
| --- | --- |
| `probe.lua` | die Sonden; läuft per `--cmd` vor `init.lua`, schreibt Bericht und `<Bericht>.json` |
| `tui.lua` | startet den gemessenen Neovim **mit UI** (Pseudo-Terminal) |
| `bench.lua` | mehrere Starts, Median / Min / Max der Vergleichszahlen |

---

## Erst lesen: headless misst einen anderen Start

lazy.nvim feuert `User VeryLazy` nach `UIEnter`. Ein Headless-Neovim bekommt
nie ein `UIEnter`, also **laden alle Plugins mit `event = "VeryLazy"` nicht**,
und alles, was sie nach dem Laden tun, findet nicht statt (auch lazys Checker
startet erst dort). Gemessen am 2026-10-01 auf `STEVESPC`, Median aus je 5
Läufen. „Vorher“ ist der Stand vor den Optimierungen dieses Tages (lazy-Checker
nur bei Fälligkeit, Session-Wortlisten in `language.nvim`, `neotest` und
`sandbox.nvim` auf Abruf), „jetzt“ der Stand danach:

| | mit UI (`tui.lua`), vorher | mit UI, jetzt | headless, vorher | headless, jetzt |
| --- | ---: | ---: | ---: | ---: |
| geladene Plugins (davon per Event) | 60 (15) | 47 (14) | 50 (1) | 39 (1) |
| Stöße > 60 ms, Summe | 2538 ms | 699 ms | 562 ms | 439 ms |
| längster Stoß | 1131 ms | 407 ms | 229 ms | 171 ms |

Die Größenordnung ändert sich mit jeder Optimierung und schwankt mit der Last
der Maschine (eine ruhigere Messung am selben Tag ergab mit UI 612 ms und
351 ms). Übertragbar ist nur die Richtung: mit UI mehr Plugins und längere
Stöße als headless. Aktuelle Zahlen liefern `bench.lua 5 tui` und
`bench.lua headless`.

Headless taugt für Fragen **bis `VimEnter`** (Spec-Import, synchrone Phasen).
Für alles danach: `tui.lua`. Die Marken-Sonde schreibt einen Hinweis in den
Bericht, wenn `VeryLazy` fehlt.

---

## Benutzung

```bash
# mit UI, alle Standard-Sonden, Bericht nach $TEMP/startup-probe.txt
# (stdout umleiten, siehe „Bekannte Grenzen“; in PowerShell:
#  cmd /c "nvim --headless -l scripts/startup-probe/tui.lua > NUL")
nvim --headless -l scripts/startup-probe/tui.lua > /dev/null

# Stöße ihrem Code zuordnen (kostet Zeit, nicht mit anderen Läufen vergleichen)
PROBE=stall,where,lazy,marks nvim --headless -l scripts/startup-probe/tui.lua

# Start mit Datei-Argument: alles hinter tui.lua geht an den gemessenen Neovim
nvim --headless -l scripts/startup-probe/tui.lua README.md

# Benchmark: 5 Läufe mit UI, Median / Min / Max
nvim --headless -l scripts/startup-probe/bench.lua 5 tui

# 5 Läufe ohne UI; Laufzahl und Modus lassen sich einzeln weglassen
nvim --headless -l scripts/startup-probe/bench.lua headless

# A/B ohne Config-Änderung: weitere Argumente gehen an den gemessenen Neovim
nvim --headless -l scripts/startup-probe/bench.lua 5 tui --cmd "lua vim.g.schalter = false"

# ohne UI (nur für die Zeit bis VimEnter)
nvim --headless --cmd "luafile scripts/startup-probe/probe.lua"
```

| Variable | Bedeutung | Vorgabe |
| --- | --- | --- |
| `PROBE` | Sonden, kommagetrennt | alle außer `where` |
| `PROBE_MS` | Wartezeit **nach `VimEnter`** in ms | `6000` |
| `PROBE_OUT` | Berichtsdatei (`.json` daneben) | `$TEMP/startup-probe.txt` |

| Sonde | Antwortet auf |
| --- | --- |
| `req` | Welches Modul kostet (exklusiv) wie viel? Welche Top-Level-`require`s blockieren lange? |
| `exe` | Wie viele PATH-Suchen, wie lange, wie viele ohne Treffer, und wer hat zuerst gefragt (Datei:Zeile)? |
| `rtp` | Wie oft berechnet `vim.loader` die `runtimepath`-Liste neu und was kostet das? |
| `stall` | Wie lange stand die Event-Loop still (Lücken > 60 ms im 10-ms-Herzschlag)? Wie belegt war sie pro Sekunde, kleine Lücken eingerechnet? |
| `where` | **Wem gehört jeder Stoß?** Besitzer (Plugin) und Stack, zeitgewichtet. Nur auf Wunsch (`PROBE=…,where`). |
| `spawn` | Welche Prozesse startet der Start über `uv.spawn` (`vim.system`, lazy.nvim, direkte Aufrufe), was kostet das Spawnen, wird blockierend gewartet? Nicht gezählt: `jobstart`, `termopen`, `system()`, `:!` (C-Ebene, laufen nicht über die Lua-Bindung). |
| `fs` | `fs_stat`, `fs_open`, `nvim_exec2` … in der Summe |
| `lazy` | Welche Plugins hat lazy.nvim geladen, wodurch (Event, `require`, Dependency von …) und wie lange? |
| `marks` | Wann kamen `LazyDone`, `VimEnter`, `UIEnter`, `VeryLazy`? |
| `report` | Die Zeitachse aus `startup` (wie `:StartupReport`, als Text) |

---

## Warum nicht `-c "… vim.wait(…)"`

`-c`-Befehle laufen **vor** `VimEnter`. Eine Messung, die dort wartet und dann
ausgibt, sieht die `UIReady`-Phasen (`usrcmds`, `mappings`, `ui_statusline`)
und alles nach dem ersten Frame **nicht**. Die Sonde hängt sich deshalb an
`VimEnter` und schreibt den Bericht erst `PROBE_MS` danach.

`"Config loaded in … ms"` am Ende von `init.lua` ist auch keine Antwort auf
„wann ist der Editor benutzbar": es läuft per `defer_fn(0)`, also beim ersten
Idle, und sieht weder die `UIReady`-Phasen noch die Stöße danach.

## Wie man die Zahlen liest

- **Stoß und Belegung.** Ein Stoß ist *eine* Lücke > 60 ms. Viele kleine
  Blockaden (ein Prozess-Spawn kostet unter Windows ~15 ms Hauptthread)
  erscheinen nie als Stoß, machen den Editor aber genauso zäh: dafür steht
  „loop busy per second".
- **`where`.** Ein Zähl-Hook nimmt während eines Stoßes Stichproben des
  Lua-Stacks und rechnet die Zeit seit der vorigen Stichprobe diesem Stack zu.
  Ein blockierender C-Aufruf (`:spellgood`, `exepath`, `nvim_open_win`)
  erscheint als eine lange Stichprobe an der Stelle, an die er zurückkehrt.
  „Besitzer“ ist der innerste Frame, der weder Neovim (auch nicht dessen
  `runtime/lua`) noch lazy.nvim gehört. Eine Stichprobe zählt zu dem Stoß, in
  den ihre Mitte fällt, nie zu zweien.
- **`lazy`.** Die Zeiten enthalten die Dependencies und alles, was `config`
  nachlädt: sie überlappen.
- **Überlappung.** Die Ladezeit eines Plugins enthält seine `require`s und
  seine `exepath`-Aufrufe; `req` und `exe` messen dasselbe von zwei Seiten.
  Als Belege für eine Ursache nehmen, nicht addieren.
- **Wrapper-Overhead.** Jede Sonde hängt einen Wrapper ein; mit allen Sonden
  sind die Summen etwa 5–10 % zu hoch. Vergleiche nur Läufe mit derselben
  Sondenmenge; `bench.lua` nimmt deshalb nur `stall,marks,report`.
- **Rauschen.** Ein Lauf schwankt um etwa ±40 ms, kalt gegen warm um Faktor
  2–3. Nie Einzelläufe vergleichen: `bench.lua`.
- **Maschine.** Die Zahlen gelten für den Rechner, auf dem sie gemessen
  wurden. Der Bericht vom 2026-09-26 (`OHANA`, Neovim 0.11.4) und die
  Nachprüfung vom 2026-10-01 (`STEVESPC`, 0.12.2) sind nicht vergleichbar.

## Bekannte Grenzen

- Die Sonde kann `vim.fn`-/`vim.api`-/`vim.uv`-Aufrufe messen, die **über die
  Lua-Tabelle** gehen. Was ein Plugin vorher in einer lokalen Variable festhält
  (`local exepath = vim.fn.exepath`), sieht sie nicht; für Code, der vor
  `--cmd` lief, gilt das immer.
- `tui.lua` zeichnet in ein Pseudo-Terminal ohne echten Emulator dahinter:
  Terminal-Antworten (Farbabfragen, Bildprotokolle) kommen von Neovims
  eingebautem `:terminal`, die Zeit für das Zeichnen im echten Emulator fehlt.
  Ist stdout des Treibers eine Pipe (`| tee`, CI, Agenten-Shell), zeichnet der
  gemessene Neovim seine Oberfläche **auch** in diese Pipe (25–45 KB
  Escape-Sequenzen pro Lauf): stdout auf eine echte Datei umleiten, in bash
  `> /dev/null`, in cmd `> NUL`. **In PowerShell** machen `>` und `| Out-Null`
  weiterhin eine Pipe: dort `cmd /c "nvim --headless -l … > NUL"` (oder
  `Start-Process -RedirectStandardOutput`). In bash legt `> NUL` eine Datei
  namens `NUL` an, die `git add -A` blockiert. Die Zahlen ändert das nicht,
  `bench.lua` verwirft die Ausgabe selbst.
- `first from` der Sonde `exe` zeigt die beiden Frames oberhalb des
  `vim.fn.*`-Aufrufs. Ruft eine Hilfsfunktion `exepath`/`executable` per Tail
  Call auf (`return vim.fn.exepath(cmd)`), hinterlässt sie keinen Frame
  (LuaJIT, es gibt keinen Marker): dann fehlt der Helfer, und die Kette zeigt
  dessen Aufrufer und den Aufrufer davon.
- Ist `PROBE_OUT` nicht beschreibbar (Verzeichnis fehlt, Platte voll), beendet
  sich der gemessene Neovim mit Exit-Code 1 und bleibt nicht hängen: `tui.lua`
  reicht den Code weiter und gibt bei jedem Exit ≠ 0 die letzten Zeilen aus dem
  Pseudo-Terminal des Kindes auf stderr aus (dort steht der Grund),
  `bench.lua` meldet den Lauf als fehlgeschlagen und druckt diesen Text.
- lazys wöchentlicher Check läuft in dem einen Lauf mit, in dem er fällig wird
  (`git fetch` für jedes Remote-Plugin). lazy schreibt `last_check` gleich zu
  Beginn des Checks, die Läufe danach sind also wieder normal, auch wenn die
  Sonde Neovim mitten im Fetch beendet hat. `bench.lua` verwirft den ersten
  Lauf, fällt die Fälligkeit dorthin, merkt man nichts; ein einzelner
  Ausreißer in „max" an so einem Tag ist dieser Lauf.
- JIT-kompilierter Lua-Code ruft keine Hooks auf, `where` sieht ihn nicht.
  Seine Zeit geht, wie die eines blockierenden C-Aufrufs, an die erste
  Stichprobe danach, also an den Code, der nach der Schleife mindestens ~1000
  Lua-Instruktionen läuft. Ist die Schleife das Letzte einer Funktion, wird
  sie dem Nachfolger zugeschrieben (nicht unterschätzt). Kommt der Herzschlag
  zuerst, steht der Stoß mit „0 ms sampled“ da. Zum Prüfen den Lauf mit
  `jit.off()` in einem vorgeschalteten `--cmd` wiederholen (dann deutlich
  langsamer, der Besitzer stimmt). Beim Start ist fast alles interpretiert,
  dort kommt das selten vor.

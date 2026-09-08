# Startup-Policy

Verbindliche Regeln dafür, wann ein Config-Modul geladen wird. Umgesetzt in
[`lua/startup/init.lua`](../../lua/startup/init.lua), angewendet in
[`init.lua`](../../init.lua), zur Laufzeit prüfbar mit `:StartupReport`.

## Warum die alten Timer weg mussten

Vorher wurden Phasen mit `vim.defer_fn(fn, 10)` bzw. `50` geplant, kommentiert
als „SEHR FRÜH (10ms)" und „FRÜH (50ms)". Gemessen auf dieser Config:

```
VimEnter     gefeuert bei  2127 ms
timer(10)    gelaufen bei  4370 ms
timer(50)    gelaufen bei  4452 ms
```

Die Zahlen 10 und 50 waren bedeutungslos. `defer_fn` kann frühestens laufen,
wenn die Event-Loop idle wird — hier gut zwei Sekunden **nach** `VimEnter`. Die
Timer steuerten faktisch nur die *relative* Reihenfolge zueinander.

Das war nicht bloß ungenau, sondern kaputt:

- `autocmds/general` registriert einen `VimEnter`-Handler (Kitty-Spacing). Er
  wurde ~2 s nach `VimEnter` registriert und hat **nie** gefeuert.
- `autocmds/text` registriert `last_loc` auf `BufReadPost`. Bei `nvim datei.lua`
  war der Buffer längst gelesen — der Sprung zur letzten Cursorposition
  passierte nie.
- Keymaps standen erst nach ~4,4 s bereit.

Ein Kommentar behauptete außerdem „PHASE 3: LSP BufReadPost", während LSP
synchron geladen wurde; „PHASE 5: RPC" beschrieb Code, der dort nicht steht.

## Die Regeln

Es gibt genau **zwei** Trigger. Jede Phase muss ihren begründen, als Kommentar
direkt an der Aufrufstelle.

### `startup.now(label, fn)` — synchron

Nur wenn eine der beiden Bedingungen zutrifft:

1. **Registrierungspflicht.** Das Modul registriert Handler für Events, die
   während des Startups feuern (`VimEnter`, das erste `BufReadPost`). Wer sich
   zu spät registriert, wird stillschweigend nie aufgerufen.
2. **Erster Frame.** Das Modul beeinflusst, wie der erste Buffer gezeichnet
   wird (Optionen, Highlight-Gruppen) — sonst flackert es sichtbar.

Aktuell: `system`, `ui_open`, `my`, `autocmds`, `lsp`.

(`options` und `wkdoptions` sind zu `my` zusammengefallen, als beide nach
StefanBartl/my.nvim gewandert sind — `init.lua` benennt die Schalter dort
explizit, damit der Aufruf dokumentiert, was die Phase tut.)

### `startup.on("UIReady", label, fn)` — nach dem ersten Frame

Für alles, was der Nutzer erst *nach* dem Start auslösen kann: Keymaps,
User-Commands. Vor dem ersten Frame kann niemand tippen, also gehört nichts
davon auf den synchronen Pfad.

Aktuell: `usrcmds`, `mappings`, `menu`.

`UIReady` ist `VimEnter` + `vim.schedule` — VimEnter ist gefeuert, aber der
folgende Paint wird nicht blockiert.

> **Kein `User VeryLazy` im Config-Kern.** lazy.nvim emittiert das Event nur,
> wenn eine Plugin-Spec es abonniert; in Headless-Runs feuerte es messbar gar
> nicht. Plugin-Specs dürfen `VeryLazy` weiter nutzen — die Kern-Config nicht.

### Verboten

**Wall-Clock-Timer** (`defer_fn` mit einer Millisekundenzahl) als Phasen-Trigger.
Eine Zahl wie `10` beschreibt keine Bedingung, sie rät. Wenn eine Phase warten
soll, dann auf das Event, das den Grund benennt.

### Noch nicht genutzt

`FileType` und `CmdlineEnter` sind bewusst frei. LSP-Server starten bereits
selbst per `vim.lsp.enable` auf `FileType`; `lsp.setup()` registriert nur
Configs. Wenn `mappings` weiter wächst, ist das Aufspalten
Cmdline-spezifischer Keymaps auf `CmdlineEnter` der nächste sinnvolle Schritt.

## Prüfen

`:StartupReport` öffnet die Zeitachse als Float (`lib.nvim.ui.kit`, mit `q` /
`<Esc>` schließbar, scrollbar):

```
Windows  ·  nvim 0.12.2  ·  1620 ms since start

  system               [sync]        235.9 ms  ··················     0.8 ms
  ui_open              [sync]        236.6 ms  ··················     0.5 ms
  my                   [sync]        237.1 ms  ████████··········    50.4 ms
  autocmds             [sync]        287.5 ms  ··················     4.4 ms
  lsp                  [sync]        292.0 ms  ███████████·······    64.3 ms
  usrcmds              [UIReady]    1401.4 ms  █████·············    29.4 ms
  mappings             [UIReady]    1430.8 ms  ██████████████████   103.3 ms
  menu                 [UIReady]    1534.1 ms  █·················     6.2 ms

  TOTAL                                         259.2 ms in phase bodies
```

(Headless-Lauf mit geöffneter Datei, warmer Cache — die absoluten Zahlen sind
maschinen- und laufabhängig, die Verhältnisse sind der Punkt.)

Der Balken ist **relativ zur langsamsten Phase**, nicht zu einem festen Budget —
er beantwortet „was dominiert", nicht „ist das zu langsam". Auch die
Slow-Markierung ist ein Anteil (≥ 25 % der Gesamt-Body-Zeit), kein
Millisekunden-Schwellwert: die absoluten Zeiten schwanken zwischen kaltem und
warmem Run um Faktor 2–3.

`:StartupCheck` meldet nur Verstöße und schweigt sonst — gedacht zum Prüfen,
nicht zum Lesen.

`PENDING` bedeutet: Das Event ist nie gekommen oder war schon durch, als sich
die Phase registriert hat — die Phase läuft also nicht. Genau dieser Zustand
war vorher unsichtbar und hat die toten Autocmds verursacht. Eine Phase auf
`PENDING` ist ein Bug, kein Hinweis.

Fehler in einem Phasen-Body werden per `pcall` abgefangen, gemeldet und in der
Zeile markiert; die nachfolgenden Phasen laufen weiter.

## Aufbau

| Datei | Rolle |
| --- | --- |
| [`lua/startup/init.lua`](../../lua/startup/init.lua) | Runner: `now`, `on`, `marks`, `pending`, `failed`, `total`, `slowest` |
| [`lua/startup/report.lua`](../../lua/startup/report.lua) | Darstellung: Float via `lib.nvim.ui.kit`, `check()` |

Die Trennung ist Absicht: der Runner läuft in der allerersten Phase, die UI darf
deshalb nicht auf dem synchronen Pfad landen. `report.lua` wird erst durch
`:StartupReport` geladen.

Alles Plattform- und Infrastrukturseitige kommt aus lib.nvim statt handgerollt:
`lib.nvim.ui.kit` (Float), `lib.nvim.ui.hl` (Namespace + Gruppen, die auf
Standardgruppen linken und so dem Colorscheme folgen), `lib.nvim.bindings.usercmd`
(Kommandos mit pcall-Wrapper), `lib.nvim.notify` (präfixierte Meldungen) und
`lib.nvim.system.env` für die Host-Zeile — letzteres delegiert an
`lib.nvim.cross.platform`, weshalb WSL korrekt als WSL und nicht als Linux
erscheint.

## Die Gesamtdauer: was vor der ersten Phase liegt

Die Phasen-Policy oben ordnet an, was *nach* `lazy.setup()` passiert. Der
größere Teil des Starts liegt davor, und `:StartupReport` sieht ihn
konstruktionsbedingt nicht — er endet, wo die erste Phase beginnt.

Gemessen (2026-09-08, `nvim --headless --startuptime`, Windows, warmer Cache;
Methode: `require` von außen per `--cmd` gewrappt, Selbstzeit pro Modul, Schnitt
bei der ersten Phasenmarke):

```
vor der ersten Phase   449 Module    ~205 ms Selbstzeit
davon Config-Module     59 Module     ~23 ms
```

Das sind drei verschiedene Dinge, und nur die letzten beiden gehören dieser
Config:

1. **NvChads eigener Spec-Import.** `nvchad.icons.devicons` allein 24 ms,
   ausgelöst aus `nvchad/plugins/init.lua` beim Auswerten der Spec-Werte. Nicht
   unser Hebel, solange NvChad die Basis ist.
2. **Plugins, die eager laden.** Siehe die Regel unten.
3. **Arbeit in Spec-Dateien.** `require` in einer `opts`-*Tabelle* läuft während
   des Spec-Imports — vor dem ersten Frame und unabhängig davon, ob das Plugin
   je lädt. Hinter `opts = function() ... end` läuft es, wenn das Plugin lädt.

### Der teuerste Einzelfund war kein Plugin

`lib.nvim.system.env.get()` berechnete `is_pwsh` über
`vim.fn.executable("pwsh")`. Das durchsucht `PATH` unter Anwendung von
`PATHEXT` und kostet auf dieser Windows-Maschine **11–15 ms pro Aufruf** —
ohne Vim-seitigen Cache, der zweite Aufruf kostet dasselbe wie der erste.
Bezahlt wurde das bei jedem Start (`init.lua` publiziert die Globals) und
noch einmal von jedem Plugin, das den Snapshot aus seiner eigenen
`plugin/`-Datei liest — bei pickers.nvim mit 17 ms der größte Posten der
gesamten Spec-Import-Phase.

Gelesen hat `is_pwsh` niemand: kein Plugin der Flotte, diese Config auch nicht.
Das Feld wird in lib.nvim jetzt erst beim ersten Zugriff aufgelöst; `get()`
fällt von ~12–17 ms auf 0,09 ms.

Die Lehre ist allgemeiner als der Fund: ein *Feld* sieht billig aus, eine
`PATH`-Suche ist es nicht. Was in einem Snapshot steht, den halbe Flotte beim
Start liest, muss so billig sein wie ein Tabellenzugriff — sonst gehört es
hinter eine Funktion.

### Regel: auch `lazy = false` braucht eine Begründung

Die ursprüngliche Policy regelte die Config-Phasen und ließ die Plugin-Trigger
offen. Das war die Lücke: 29 der 116 Plugins luden beim Start, mehrere davon
ohne jeden Grund.

Ein Plugin darf `lazy = false` nur führen, wenn es **vor dem ersten Frame etwas
tun muss** — Farbschema, Statusline, etwas, das Kommandos registriert, die
sonst niemand auslösen kann. Alles, was auf einen *Buffer* wirkt, hat in
`event = { "BufReadPost", "BufNewFile" }` seinen richtigen Trigger: früher als
ein Buffer kann es ohnehin nichts tun, und bei `nvim datei.lua` feuert das
Event noch während des Starts — es geht also nichts verloren, was im ersten
Frame sichtbar gewesen wäre. Bei `nvim` ohne Argument spart es alles.

Umgestellt (2026-09-08): `todo-comments.nvim` (37 ms, zog plenary und
nvim-web-devicons mit), `vim-matchup` (15,6 ms), `git-conflict.nvim` (5,7 ms)
auf `BufReadPost`/`BufNewFile`; `vim-startuptime` auf `cmd = "StartupTime"` —
ein Startup-Profiler, der sich selbst mitmaß. Der Start-Batch fiel damit von 29
auf 16 Plugins.

Was bewusst eager bleibt: die eigenen Plugins, die User-Commands registrieren
(`plugins/personal/init.lua` begründet jedes einzeln an der Spec), NvChad,
snacks, tokyonight, treesitter. Der teuerste Eintrag ist jetzt
`runtime-analysis.nvim` mit ~45 ms — das ist der Preis der Telemetrie, siehe
`lua/config/telemetry.lua`, und eine bewusste Entscheidung, keine Panne.

### Messen, nicht raten

Absolute Zahlen schwanken zwischen kaltem und warmem Cache um Faktor 2–3;
Vergleiche sind nur *innerhalb* einer Messreihe aussagekräftig. Wer eine
Vermutung hat, misst sie:

```bash
nvim --headless --startuptime /tmp/st.txt +qa && sort -rnk2 /tmp/st.txt | head -20
```

Für die Frage „wer lädt das eigentlich" reicht `--startuptime` nicht — dort
fehlt der Aufrufer. `require` von außen wrappen (`nvim --cmd "luafile
tracker.lua"`, läuft vor `init.lua`) und im Wrapper `debug.traceback()`
mitschreiben: das nennt Modul, Selbstzeit und Verursacher in einem.

### `after/` ist hier kein Thema

`after/queries/**` und `after/syntax/checkhealth.vim` tauchen im gesamten
Startup-Trace nicht auf. Neovim liest `after/queries/` erst, wenn ein
Textobject benutzt wird, und `after/syntax/checkhealth.vim` erst bei
`:checkhealth`. Kosten am Start: null. Ob die Dateien dort *richtig* liegen,
ist eine Architekturfrage — keine Startup-Frage.

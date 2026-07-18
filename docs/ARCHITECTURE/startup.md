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

Aktuell: `system`, `options`, `wkdoptions`, `autocmds`, `lsp`.

### `startup.on("UIReady", label, fn)` — nach dem ersten Frame

Für alles, was der Nutzer erst *nach* dem Start auslösen kann: Keymaps,
User-Commands. Vor dem ersten Frame kann niemand tippen, also gehört nichts
davon auf den synchronen Pfad.

Aktuell: `usrcmds`, `mappings`.

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

`:StartupReport` zeigt pro Phase Trigger, Startzeitpunkt und Dauer:

```
system                 [sync]       ran    851.2 ms  took    45.4 ms
options                [sync]       ran    896.6 ms  took    81.2 ms
wkdoptions             [sync]       ran    977.8 ms  took    47.4 ms
autocmds               [sync]       ran   1025.3 ms  took     6.8 ms
lsp                    [sync]       ran   1032.1 ms  took   490.8 ms
usrcmds                [UIReady]    ran   6046.7 ms  took     1.7 ms
mappings               [UIReady]    ran   6048.5 ms  took   237.0 ms
```

`PENDING` bedeutet: Das Event ist nie gekommen oder war schon durch, als sich
die Phase registriert hat — die Phase läuft also nicht. Genau dieser Zustand
war vorher unsichtbar und hat die toten Autocmds verursacht. Eine Phase auf
`PENDING` ist ein Bug, kein Hinweis.

Fehler in einem Phasen-Body werden per `pcall` abgefangen, gemeldet und in der
Zeile markiert; die nachfolgenden Phasen laufen weiter.

## Offen: die Gesamtdauer

Diese Umstellung ordnet die Phasen korrekt an, sie macht den Start nicht
schneller. Die Bodies summieren sich auf ~0,9 s, der Start dauert mehrere
Sekunden — der Rest liegt vor der ersten Phase, in `lazy.setup()` und dem
Spec-Import. Das ist eine eigene Aufgabe; `:StartupReport` grenzt sie nur ein.
Messwerte schwanken zwischen Runs stark (kalter vs. warmer Cache), deshalb sind
Vergleiche nur *innerhalb* eines Runs aussagekräftig.

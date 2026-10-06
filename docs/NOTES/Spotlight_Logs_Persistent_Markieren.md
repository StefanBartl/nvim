# spotlight.nvim – Logdateien persistent markieren

Workflow: Tokens in einer Logdatei markieren, beim nächsten Öffnen sind sie
weiterhin hervorgehoben. Persistenz ist in spotlight.nvim eingebaut und
standardmäßig aktiv (`persist.enable = true`, `persist.default = true`).

## Übersicht: Usercmds & Keymaps

| Aktion                                               | Keymap         | Usercmd                              |
| ---------------------------------------------------- | -------------- | ------------------------------------ |
| Alle Vorkommen markieren/entfernen (**persistent**)  | `<leader>sK`   | `:Spotlight` / `:Spotlight toggle`   |
| Alle Vorkommen der visuellen Auswahl (n/x)           | `<leader>sK` (x) | `:'<,'>Spotlight toggle`           |
| Nur diese Stelle markieren (**nicht** persistent)    | `<leader>sk`   | `:Spotlight here`                    |
| Literal-Text hinzufügen                              |                | `:Spotlight add {text}`              |
| Einen Text entfernen                                 |                | `:Spotlight remove {text}`           |
| Alle Markierungen entfernen                          | `<leader>sC`   | `:Spotlight clear`                   |
| Liste öffnen (Swatch, Token, Anzahl)                 | `<leader>sL`   | `:Spotlight list`                    |
| Zum nächsten / vorherigen Treffer springen           | `]k` / `[k`    | `:Spotlight next` / `:Spotlight prev`|
| Trefferzeilen ins Quickfix                           | `<leader>sq`   | `:Spotlight qf`                      |
| Ganze Zeile hervorheben (Toggle)                     | `<leader>sW`   | `:Spotlight line [text]`             |
| Farben/Matches neu aufbauen (Escape-Hatch)           |                | `:Spotlight refresh`                 |
| Persistenz pro Datei an/aus/Standard/Status          |                | `:Spotlight persist on\|off\|default\|status` |
| Set speichern                                        |                | `:Spotlight sets save {name}`        |
| Set laden (ersetzt aktive Markierungen)              |                | `:Spotlight sets switch {name}`      |
| Set löschen                                          |                | `:Spotlight sets delete {name}`      |
| Alle Sets auflisten                                  |                | `:Spotlight sets list`               |
| Health-Check                                         |                | `:checkhealth spotlight`             |

## Workflow

### 1. Markieren

- Cursor auf ein Token (Request-ID, PID, …) → `<leader>sK`.
- Beliebigen Text: visuell auswählen → `<leader>sK`, oder `:Spotlight add {text}`.
- Klein `<leader>sk` nur, wenn die Markierung bewusst flüchtig sein soll: die
  Position gilt nur für den exakten Pufferzustand und wird nie auf Platte
  geschrieben.

### 2. Lesen und navigieren

- `]k` / `[k` springen durch die Treffer (`nav.scope = "auto"`: innerhalb eines
  Treffers folgt es diesem Token, sonst allen Spotlights).
- `<leader>sL` zeigt die Liste, `<leader>sq` faltet die Datei per Quickfix auf
  alle Zeilen mit dem Token.

### 3. Speichern (automatisch)

- Schreiben mit 500 ms Debounce (`persist.debounce_ms`).
- `VimLeavePre` schreibt sofort, auch bei `:qa!`.
- Absturz oder `kill -9` verliert Änderungen, die noch im Debounce-Fenster waren.

### 4. Nächster Start

- Wiederherstellung bei `VimEnter`, nicht in `setup()`.
- Sind die Farben weg: `:Spotlight refresh`.

### 5. Mehrere Untersuchungen trennen

```
:Spotlight sets save timeout-bug      " aktuelle Markierungen benennen
:Spotlight sets switch timeout-bug    " später laden, ersetzt die aktiven
:Spotlight sets list
```

Sets liegen unter einem eigenen Schlüssel (`spotlight/sets`) und werden bei
jedem `save`/`switch`/`delete` sofort geschrieben. Ein unbekannter Name bei
`switch` ist ein abgelehnter No-op, kein Datenverlust.

## Stolpersteine

- **Projektbezug:** Der Zustand ist pro **Git-Root** abgelegt
  (`lib.nvim.store.project`, Schlüssel `spotlight/state`). Logs innerhalb eines
  Git-Projekts funktionieren von jedem Unterordner aus. Für Logs außerhalb eines
  Repos ist das Verhalten ungeprüft, also einmal testen.
- **Sensible Logs:** `:Spotlight persist off` **vor** dem Markieren setzen. Die
  Ausnahme gilt für Spotlights, die *in dieser Datei erstellt* wurden (Herkunft),
  nicht rückwirkend und nicht für Treffer in anderen Dateien.
  `:Spotlight persist status` zeigt, was gilt und warum.
- **Abhängigkeit:** Ohne `lib.nvim` keine Persistenz (`:checkhealth spotlight`).
- **Groß-/Kleinschreibung:** `Error` und `error` sind getrennte Spotlights
  (`\C` fest eingebaut).
- **Auswahl vs. Cursor:** Eine visuelle Auswahl wird wörtlich genommen, ohne
  Wortgrenzen. `err` trifft dann auch in `error`.
- **Toggle entfernt:** `<leader>sK` auf einem bereits markierten Token entfernt
  es. Das gilt auch für `.`.

## Schnelltest

1. Logdatei öffnen, Cursor auf ein Token, `<leader>sK`.
2. `:Spotlight persist status` → sollte „persists“ melden.
3. `:qa`, neu starten, Datei öffnen → Markierung ist wieder da.

Geht es nicht: Ausgabe von `:checkhealth spotlight` und
`:Spotlight persist status` prüfen.

## Quelle

`spotlight.nvim`: `docs/FEATURES/PERSISTENCE.md`, `docs/WORKFLOW.md`,
`docs/commands.md`, `docs/BINDINGS.md`.

## Beispiel: Auth-Fehler in Tosca/AOS-Logs

Fall: verteilte Ausführung (DEX/AOS) scheitert nach Migration auf Windows
Server 2019, lokale Ausführung läuft. Ziel: schnell zeigen, dass der Fehler bei
der LDAP-/Token-Authentifizierung liegt und nicht im DEX-Scheduling.

### Was markieren

Pro Log 4 bis 6 Spotlights, nach Rolle gruppiert:

| Rolle                  | Token                          | Log               | Warum |
| ---------------------- | ------------------------------ | ----------------- | ----- |
| Betroffener            | `SYSsystosca`                  | Workspace, Service | Roter Faden durch alle Logs |
| Symptom                | `Failed to authenticate`       | Workspace, Service | Trifft `ldap user against workspace` und `Failed to authenticate User` |
| Fehlerklasse           | `AuthenticationException`      | Service           | Beginn und Häufigkeit der Exceptions |
| Bruchstelle            | `GetAccessTokenFromEndpoint`   | Service           | Stacktrace-Methode, bindet den Fehler an den Token-Aufruf |
| Ursache                | `400 (Bad Request)`            | Service           | Anfrage wird abgelehnt, Endpoint ist erreichbar |
| Gegenprobe             | `toscaprod.hm.com`             | Workspace         | Service Discovery klappt, das Netz ist in Ordnung |
| Rauschen (andere Farbe) | `localhost:5007`              | DEX Agent         | Startup-Fehler, bewusst als Nebenschauplatz markiert |

### Vorgehen

1. `SYSsystosca` zuerst markieren (`<leader>sK` auf dem Token), er bekommt
   Farbe 1.
2. Mehrteilige Texte per Visual-Auswahl markieren (`v`, dann `<leader>sK`).
   `400` allein würde jeden Zeitstempel und jede Bytezahl treffen.
3. `<leader>sq` mit nur `Failed to authenticate` aktiv: alle Fehlerzeilen als
   Quickfix-Liste, direkt als Belegstellen für den Report.
4. `<leader>sW` auf dem Symptom, damit lange Stacktraces zeilenweise auffallen.
5. Abschluss mit einem Set, z. B.
   `:Spotlight sets save ldap-tosca-2019-migration`.

### Vorher beachten (Kundendaten)

- Account, Hostnamen und Domain landen sonst im Cache:
  `:Spotlight persist off` **vor** dem Markieren setzen, falls die Spotlights
  nicht bleiben sollen.
- Sets enthalten die Tokens im Klartext. Bei Kundenlogs einen neutralen
  Setnamen wählen und `SYSsystosca` und Hostnamen nicht mitspeichern.
- Groß-/Kleinschreibung zählt: `SYSsystosca` trifft nicht `syssystosca`.

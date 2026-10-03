# Spike-Report: `ext_messages`-Logger neben noice / ui2 in echter TUI (2026-10-01)

Auftrag: nur testen, nichts bauen, keine Ersatz-Entscheidung. Schritt 1 des Konzepts
`WKDBooks/Development/wkdbook-myplugins/lib.nvim/ROADMAP/messages-log-and-recent-popup.md`.
Vorgänger-Report: `NOICE_ERSATZ/noice-feature-abdeckung-2026-10-01.md` (Feature-Matrix, ohne Messung).

## Methode und Grenzen

- Neovim 0.12.2, Windows 11. **Echte TUI**: versteckte Konsole (`Start-Process -WindowStyle Hidden`, 120x30,
  `nvim_list_uis() = 1`); „sichtbar" heißt: steht im `nvim__screenshot`-Dump der TUI, nicht nur im Ereignisstrom.
- Szenarien: S1 Logger allein (`-u`, keine Config) · S2 echte Config (noice aktiv) + Logger · S3/S3b `ui2` allein (+ Logger) ·
  S4 noice + ui2 + Logger · S5 Kosten (20 000 Echos) · S6 Kind-Katalog häufiger Meldungen.
- Harness: `WKDBooks/…/TOOLS/tui-spike-harness.md` (Skripte in `TOOLS/scripts/tui-spike/`), wiederholbar.
- **Nicht gemessen:** Hit-Enter-Prompts unter noice-Cmdline, `ext_cmdline`-Wechselwirkung mit noice-Cmdline-Popup,
  mehrere Wochen Dauerbetrieb (Speicher nur über Mikro-Benchmark), andere Terminals als die Konsolen-TUI, Linux/macOS.

## Ergebnis je Punkt

| # | Frage | Antwort | Beleg |
|---|---|---|---|
| 1 | Zeichnet die TUI Meldungen noch selbst, wenn ein Logger attacht? | **widerlegt (die Falle ist real)** — als einziger Listener nimmt `ext_messages` der TUI **Meldungen und die Cmdline** weg: `echo`/`echomsg`/`echoerr`/`emsg`/`vim.notify` werden geliefert, aber **nichts** gezeichnet; `cmdline_show`/`cmdline_hide` kommen ebenfalls an. | S1 |
| 2 | Wie kommt man wieder raus? | **belegt** — `vim.ui_detach(ns)` des einzigen Listeners stellt die native Anzeige **sofort** wieder her (nächste Meldung erscheint, auch mit offenem Float, kein Hänger). | S1, S2 |
| 3 | Koexistenz mit noice | **belegt** — noice rendert unverändert (mini-Stack unten rechts), der Logger bekommt **parallel jedes Event**, auch das, was noice per `skip` unterdrückt (E20, E486 sichtbar im Log, nicht auf dem Schirm). Zwei Einschränkungen siehe 4. | S2 |
| 4 | Was sieht der Logger **nicht**? | **belegt** — (a) `vim.notify`, wenn noice es besitzt (noice ersetzt `vim.notify`; kommt nur über noice, nicht als `msg_show`); ohne noice kommt es als `kind=echomsg`/`echoerr`, **Level geht verloren** (INFO → `echomsg`, ERROR → `echoerr`, WARN nicht unterscheidbar). (b) `lib.nvim.notify`-Toasts (`popup = true` → `ui.kit.toast` direkt). (c) alles, was kein `msg_show` ist: `:messages` kommt als `msg_history_show`. | S2, S6 |
| 5 | `:redir` / `:silent` / `nvim_exec2(output=true)` / `vim.fn.execute` | **belegt: unsichtbar** — keine `msg_show`-Events; `:silent! echomsg` landet nicht einmal in `:messages`. Ein Logger kann das **nicht** nachliefern (nur mit eigenem Hook um diese Aufrufe, nicht empfehlenswert). | S1 |
| 6 | Was `:Noice disable` mit angehängtem Logger macht | **belegt** — Logger wird dann **alleiniger** Listener → nichts wird gezeichnet, solange er attacht ist; nach Detach des Loggers zeigt die native Anzeige wieder. `:Noice enable` stellt den mini-Stack wieder her. **Ein Logger muss also auf `noice disable` reagieren oder die Policy prüfen**, sonst verschluckt er Meldungen. | S2 |
| 7 | Ringpuffer-Kosten | **belegt: vernachlässigbar** — No-op-Listener 1,7 µs/Event; Ring 1000/10 000 Einträge kurz: 2,2/1,9 µs, +0,23/+2,3 MB; lang (mehrzeilig): 3,9–4,1 µs, +0,34/+4,3 MB. Zustellung **synchron** (kein Event geht verloren, 2000 Echos in ~30 ms, alle da). | S5, S2 |
| 8 | noice vs. `ui2` | **belegt** — `ui2` allein: Meldungen im cmd-Fenster (Zeile 30), wächst mehrzeilig, `:messages` → Pager, `g<` erweitert; als Renderer reicht es für Meldungen, aber **kein Routing/Skip/History mit Zeit**. Rendering ist **synchron und teuer** (2000 Echos ≈ 612 ms gegenüber noice ≈ 30 ms, gedrosselt). Mit `target="msg"` kommen Meldungen als Stack unten rechts und verschwinden nach `timeout` (S3b) — das ist das nächste an „Chips" ohne Eigenbau. | S3, S3b |
| 9 | noice **und** `ui2` gleichzeitig | **widerlegt als Dauerzustand** — kein Fehler, aber **jede Meldung erscheint doppelt** (noice mini Zeile 27 + ui2 Zeile 29); `vim.notify` nur einmal (noice besitzt es). Beides zusammen also nur als Übergang, nicht als Konfiguration. | S4 |
| 10 | Mehr als zwei Listener | **belegt** — noice + ui2 + Logger gleichzeitig: kein Fehler, alle bekommen Events. | S4 |

## Kind-Katalog (S6, reale Meldungen, `ext_messages` ohne Renderer)

Für `lib.nvim.messages` (kind → Level) gemessen, nicht aus der Doku übernommen:

| Auslöser | `kind` | `history` | Bemerkung |
|---|---|---|---|
| Lua-Fehler (`:lua error()`) | `lua_error` | ja | Text beginnt mit `E5108: Lua: …` |
| `:ls`, `:set x?`, `:registers`, `:changes`, `:verbose …` | `list_cmd` | **nein** | mehrzeilig; gehören nicht in `:messages` |
| `:%s/a/X/g` (mit `report=0`) | `""` (leer) | ja | „3 substitutions on 2 lines" |
| `u` | `undo` | ja | |
| `/pat` + `n` | `search_cmd` (Echo des Musters), `search_count` (`replace_last=true`) | nein | Zähler **ersetzt** die vorige Zeile |
| `:write` | `bufwrite` ×2 | nur die zweite | erste ist Platzhalter, zweite `replace_last=true` + `history=true` |
| `vim.notify` (ohne noice) | `echomsg` / `echoerr` | ja | Level nur grob (siehe Punkt 4) |
| `nvim_echo(chunks, true, {})` | `echomsg` | ja | Highlight-Gruppen pro Chunk in `content` |
| `nvim_echo(…, {err = true})` | `echoerr` | ja | |
| `:echon 'a' \| echon 'b'` | `echo` ×2 | nein | zwei Events, **keine** Verkettung |
| `:echo`, `confirm()` | `echo` / `confirm` | nein | |
| `:messages` | (Event `msg_history_show`) | – | kein `msg_show` |

Folgerungen für das Log: `history=false`-Meldungen (`list_cmd`, `echo`, `search_*`) sind ein **Anzeige-**, kein Ereignis-Log →
Default sollte nur `history=true` aufnehmen (`kinds`-Filter für den Rest); `replace_last=true` muss den letzten Eintrag
**ersetzen**, sonst steht jede Suchzahl/jeder Schreibvorgang doppelt im Popup.

## Empfehlung: Attach-Policy

**„Nur attachen, wenn ein Renderer existiert" — bestätigt, und präzisiert:**

1. Der Logger attacht **nicht beim Laden**, sondern erst, wenn mindestens einer vorhanden ist:
   noice geladen **und** aktiv, `ui2` aktiviert, oder ein eigener Chip-Renderer (ui.nvim) aktiv. Prüfung beim
   Setup. noice feuert bei `enable()`/`disable()` **kein** Autocmd/User-Event (Quelltext `noice/init.lua:39/55` geprüft) →
   Renderer-Wechsel sind nur über einen Wrapper um `require("noice").enable/disable` (bzw. `:Noice`-Befehl) oder ein
   billiges erneutes Prüfen (z. B. vor jedem Popup-Öffnen) erkennbar.
2. Bei einem Renderer-Wechsel („noice disable") → **Logger detachen** (Punkt 6), sonst verschluckt er alles.
3. Kein Renderer ⇒ **gar nicht** attachen; Fallback: `:messages` auslesen (ohne Zeitstempel, nur `history=true`).
4. Der Logger darf **nie der erste Listener** sein, der Zeichnen verhindert (Punkt 1) — Reihenfolge ist egal, entscheidend ist die Menge.
5. `vim.notify`/`lib.nvim.notify`-Toasts nicht über den Logger, sondern direkt in den Store schreiben (`lib.nvim.messages.push`):
   das schließt die zwei Lücken aus Punkt 4 und vermeidet doppelte Einträge (Notify läuft sonst einmal über noice, einmal über den Logger).
6. Kosten sind kein Argument gegen Dauerbetrieb (Punkt 7); Ringgröße 1000 reicht (~0,3 MB).

**Nicht verifiziert:** ob ein Wrapper-Weg für 2. in der echten Config sauber greift (nicht gebaut — Auftrag war nur Messen).

Offen für die Entscheidung (nicht Teil des Spikes): Soll `lib.nvim.messages` selbst Renderer sein (dann gäbe es immer
einen, die Policy entfiele) oder weiter nur Quelle? Das hängt an Schritt 7 (noice-Ersatz) im Konzept.

## Nebenbefunde

- `ui2` mit `target="msg"` (S3b) ist eine **Zwischenlösung ohne Eigenbau**: Stack unten rechts, Timeout einstellbar, zindex 198
  (über Pickern und über ui.kit-Toasts, die auf 70 liegen — Reihenfolge prüfen, falls je kombiniert).
- Ohne jeden Listener hängt die TUI bei langen Ausgaben auf `-- More --`; das ist Neovim-Standardverhalten, aber
  Messungen brauchen dafür einen No-op-Listener als Baseline.
- Während der Läufe wurde nichts in der Config oder in Plugin-Repos verändert (Arbeitsverzeichnis `spike/work`).

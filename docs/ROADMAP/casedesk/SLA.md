# casedesk — SLA-Überwachung (Konzept)

Grundlage: `C:\repos\WKDBook-Tricentis\Workflow\SLA_ServiceLevelAgreement.md`
([Confluence](https://tricentis.atlassian.net/wiki/spaces/SUP/pages/320726887/SAP+Service+Level+Agreements+SLAs)).

Noch nicht gebaut. Fertige Features stehen in [CONCEPT.md](CONCEPT.md),
offene Punkte in [ROADMAP.md](ROADMAP.md) — dieses Dokument ist die
Vorarbeit für einen eigenen `sla.lua`-Baustein.

---

## Table of content

- [1. Warum das nicht aus dem Bestehenden fällt](#1-warum-das-nicht-aus-dem-bestehenden-fällt)
- [2. Datenlage](#2-datenlage)
- [3. Drei Uhren, nicht eine](#3-drei-uhren-nicht-eine)
- [4. Geschäftszeit-Rechnung (der einzige echte Algorithmus)](#4-geschäftszeit-rechnung-der-einzige-echte-algorithmus)
- [5. Datenmodell](#5-datenmodell)
  - [`config.sla`](#configsla)
  - [`.case.json`-Erweiterung](#casejson-erweiterung)
  - [Stream-Parser](#stream-parser)
- [6. Features](#6-features)
  - [A. Fundament](#a-fundament)
  - [B. Anzeige](#b-anzeige)
  - [C. Aktiv statt passiv](#c-aktiv-statt-passiv)
  - [D. Reporting für die Zielvereinbarung](#d-reporting-für-die-zielvereinbarung)
  - [E. Kleinigkeiten mit täglichem Nutzen](#e-kleinigkeiten-mit-täglichem-nutzen)
- [7. Modulaufbau](#7-modulaufbau)
- [8. Risiken und Fallen](#8-risiken-und-fallen)
- [9. Offene Fachfragen](#9-offene-fachfragen)
- [10. Reihenfolge](#10-reihenfolge)
- [11. Worked Example: 977392](#11-worked-example-977392)
- [Literatur und Referenzen](#literatur-und-referenzen)

---

## 1. Warum das nicht aus dem Bestehenden fällt

casedesk misst heute **die falsche Uhr**. `:Cases stale` und `:Case timeline`
leiten alles aus Datei-mtimes ab (`timeline.lua`, CONCEPT.md §8h: „derive from
what's already there instead of tracking a second copy") — also daraus, *wann
ich zuletzt getippt habe*.

Die SLA-Uhr läuft nach **SNOW-Ereignissen**: wann der Kunde geschrieben hat,
wann etwas rausging. Beide können beliebig weit auseinanderlaufen: ein Case,
an dem gestern zwei Stunden Research entstanden sind, ist für `:Cases stale`
frisch und kann trotzdem seit sechs Stunden die P2-Rückmeldefrist reißen,
weil nichts *gesendet* wurde.

Das ist keine Erweiterung von `stale`, sondern eine zweite Zeitachse. Die
CONCEPT.md-§3-Regel („der Zustand IST der Ordner") gilt hier nur zur Hälfte:
Ereignisse, die außerhalb des Ordners passiert sind, muss der Ordner
mitbekommen — entweder aus dem Activity Stream oder durch eine explizite
Eingabe.

## 2. Datenlage

Fast alles Nötige liegt bereits im Case-Ordner, es wird nur nicht ausgewertet.

| Datum | Quelle | Status |
| --- | --- | --- |
| Ticket-Erstellung | `.case.json` → `created` | vorhanden (aber: Anlagezeit des *Ordners*, nicht des Tickets — siehe §9) |
| **Priorität** | Activity Stream: `Priority` / `3 - Moderate`, `Impact` / `2 - Medium` | parsebar, aber `priority` ist in `.case.json` faktisch nie gesetzt |
| **Letzte Kundennachricht** | Stream-Block: `Comment` + Timestamp + `Customer added a memo` + `from: <Name>` | sauber strukturiert, parsebar |
| Zuweisung an mich | `Field changes` → `Assigned to` / `Stefan Bartl was Empty` | parsebar |
| Produktfehler ja/nein | — | nicht ableitbar, entscheidet aber den Rückmeldetakt bei P3/P4 |
| **Letzte gesendete Antwort** | — | **existiert nicht** |

Die letzte Zeile ist die einzige echte Lücke. `Replies/NN_Reply.md` ist ein
*Entwurf*; seine mtime sagt, wann getippt wurde, nicht wann gesendet — und
laut CONCEPT.md §8c/§8i geht bewusst nichts automatisch raus.

**Billigste Lösung mit dem größten Hebel:** ein Zeitstempel `last_reply_sent`
in `.case.json`, gesetzt durch `:Case sent` — oder, ohne neuen Befehl, durch
eine Abschlussfrage in `:Case reply check`: „rausgeschickt? [y]". Ein Feld,
ein Prompt, und die gesamte SLA-Mechanik wird exakt statt geraten.

## 3. Drei Uhren, nicht eine

| Uhr | startet neu bei | P1 | P2 | P3 | P4 |
| --- | --- | --- | --- | --- | --- |
| Erstreaktion | Ticket-Eingang | 1 h (24x7) | 2 h (24x7) | 4 h (10x5) | 1 AT (10x5) |
| **Laufende Rückmeldung** | jeder eigenen Antwort — **wiederkehrend** | stündlich | alle 6 h | 3 T / 2 W* | 1 W / 3 W* |
| Korrekturmaßnahme | Ticket-Eingang | 4 h | 3 AT | 6 KW | 6 KW |

\* erster Wert ohne Produktfehler, zweiter bei Produktfehler.

Zwei Konsequenzen:

**Die Rückmeldungs-Uhr ist die im Alltag gefährliche.** Die Erstreaktion
vergisst man nicht — man sitzt gerade am Ticket. Aber der 6-Stunden-Takt bei
einem P2, der über Nacht läuft, oder stündlich bei P1: das hält kein Mensch
im Kopf, und heute überwacht es nichts. Wenn dieses Feature nur *eine* Sache
kann, dann diese.

**Sie ist außerdem die einzige wiederkehrende.** Erstreaktion und
Korrekturmaßnahme sind Einmal-Deadlines ab Ticket-Eingang; die Rückmeldung
setzt sich mit jeder gesendeten Antwort zurück. Das Datenmodell muss beide
Formen tragen.

## 4. Geschäftszeit-Rechnung (der einzige echte Algorithmus)

24x7 vs. 10x5 ist kein Detail. Bei P1/P2 läuft die Uhr nachts und am
Wochenende weiter. Bei P3/P4 nur 08:00–18:00 CET — Restzeit muss also **in
Geschäftszeit** gerechnet werden. Sonst zeigt das Tool Freitag 17:00 bei einem
P3 „4 h übrig" statt korrekt „Montag 11:00", und man verpasst die Frist genau
deswegen.

Zwei Funktionen, alles andere fällt daraus:

```lua
--- Wie viele Sekunden Geschäftszeit liegen zwischen `from` und `to`?
---@param from integer epoch
---@param to integer epoch
---@param window Lib.Case.SlaWindow  "24x7" | { from = 8, to = 18, days = {2,3,4,5,6} }
---@return integer
function M.elapsed(from, to, window)

--- Auf welchen Zeitpunkt fällt `budget` Sekunden Geschäftszeit nach `from`?
---@return integer epoch  -- die anzeigbare, absolute Deadline
function M.deadline(from, budget, window)
```

Bei `24x7` ist beides triviale Arithmetik; bei `10x5` iteriert man tageweise
(nicht sekundenweise) über den Zeitraum. Feiertage bleiben im ersten Wurf
außen vor — als konfigurierbare Datumsliste nachrüstbar, dokumentiert als
bekannte Ungenauigkeit. Zeitbasis intern durchgehend UTC-Epoch; die
CET/CEST-Umrechnung passiert nur an der Anzeige-Kante.

## 5. Datenmodell

### `config.sla`

Die SLA-Tabelle gehört in `config.lua`, **nicht** in einen Markdown-Parser.
Das Dokument ist die Fassung für Menschen und ändert sich vielleicht einmal
im Jahr; es zu parsen wäre fragil für null Gewinn. Gegenseitiger Verweis
genügt (Kommentar im Config-Block → Pfad, Doku → `:Case sla --doc`).

```lua
---@type table<string, Lib.Case.SlaLevel>
M.sla = {
  ["1"] = { label = "Very High", window = "24x7",
            first_response = 1 * HOUR,  cadence = 1 * HOUR,   fix = 4 * HOUR },
  ["2"] = { label = "High",      window = "24x7",
            first_response = 2 * HOUR,  cadence = 6 * HOUR,   fix = 3 * WORKDAY },
  ["3"] = { label = "Medium",    window = BUSINESS,
            first_response = 4 * HOUR,  cadence = { 3 * DAY, 14 * DAY },
            fix = 6 * WEEK },
  ["4"] = { label = "Low",       window = BUSINESS,
            first_response = 1 * WORKDAY, cadence = { 7 * DAY, 21 * DAY },
            fix = 6 * WEEK },
}

M.sla_business_hours = { from = 8, to = 18, days = { 2, 3, 4, 5, 6 } }  -- CET
M.sla_warn_at = 0.25   -- Restanteil, ab dem gewarnt wird
M.sla_active_priorities = { "1", "2" }  -- nur diese lösen Notifications aus
```

`cadence` als Tabelle = `{ ohne_produktfehler, mit_produktfehler }`. Solange
„Produktfehler ja/nein" nicht erfasst ist, gilt der strengere erste Wert.

### `.case.json`-Erweiterung

Drei Felder, alle optional — ein Case ohne sie verhält sich exakt wie heute:

```jsonc
{
  "priority": "3",                        // aus dem Stream geparst
  "ticket_opened": "2026-07-29T13:06:20Z", // echter Ticket-Eingang, s. §9
  "last_reply_sent": "2026-08-05T15:12:00Z"
}
```

`:Cases doctor` bekommt davon **nichts** zu policen — die Felder sind
optional, ihr Fehlen ist kein Befund, sondern nur „SLA unbekannt". Das ist
bewusst: jede Pflicht hier wäre eine neue Fehlerquelle unter Zeitdruck
(Workflow.md §6, „die aktuelle Minimalität ist selbst das Feature").

### Stream-Parser

`sla/stream.lua` liest `Research/NN_ActivityStream.md` (die höchste Nummer)
und liefert eine Ereignisliste:

```lua
---@class Lib.Case.SlaEvent
---@field at integer          epoch (UTC)
---@field kind "customer"|"agent"|"field_change"|"assignment"
---@field actor string|nil
```

Erkennungsmuster aus dem realen Format:

- Blockbeginn: Zeile `Comment` oder `Field changes`, davor der Actor.
- Zeitstempel: **`at: <datum> <zeit> GMT` bevorzugt** — der Stream führt zwei
  Zeiten pro Eintrag (lokal `2026-08-05 08:00:13`, GMT `2026-08-05 05:58:36
  GMT`); nur die GMT-Zeile ist eindeutig. Ohne `at:`-Zeile die lokale Zeit
  als CET interpretieren und das im Ergebnis markieren.
- Kundennachricht: `Customer added a memo` + `from: <Name>`.
- Zuweisung: `Assigned to` gefolgt von `<Name> was Empty`.
- Metadaten am Ende: `Priority`/`Impact`/`State`/`Number`, jeweils Label-Zeile
  gefolgt von Wert-Zeile.

Der Parser darf **nie** hart scheitern: unbekannte Struktur → leere Liste plus
Hinweis, nicht Fehler. Ein Stream aus einer anderen SNOW-Ansicht darf keinen
Befehl abbrechen.

## 6. Features

### A. Fundament

- **Priorität automatisch ziehen.** `:Case activity` liest den Stream ohnehin
  ein — dabei `Priority` und `Impact` mitnehmen und nach `.case.json`
  schreiben. Kein Tippen, kein Pflegeaufwand; `infocard_fields` kennt das
  Feld bereits (`config.lua`).
- **`config.sla`** wie oben.
- **`sla/stream.lua`** — Ereignisse extrahieren.
- **`:Case sent`** bzw. die Abschlussfrage in `:Case reply check`.

### B. Anzeige

- **`:Case sla`** — Infocard für den aktuellen Case: Priorität, welche Uhr
  gerade läuft, Restzeit **und die Deadline als absolute Uhrzeit**.

  ```
  977392 · P3 Medium · 10x5 (08–18 CET)
    Erstreaktion      erfüllt      05.08. 16:31  (Puffer 1 h 27)
    Rückmeldung       fällig       07.08. 09:58  in 1 T 2 h
    Korrekturmaßnahme offen        09.09. 18:00  in 4 W 5 T
  ```

  „fällig heute 17:58 (in 2 h 14)" ist brauchbar, „2 h übrig" nicht — bei
  letzterem muss man selbst über die Mittagspause und den Feierabend hinweg
  rechnen und macht es falsch.

- **`:Cases sla`** — Dashboard über alle offenen Cases, **sortiert nach
  Restzeit, nicht nach Priorität**. Das ist die Frage, die man morgens hat:
  *was reißt als nächstes*. Ampel: gerissen / unter `sla_warn_at` / ok.
  Deckt zugleich den offenen ROADMAP-Punkt „Dashboard beim Start: offene
  Cases nach Liegezeit" ab — Liegezeit ist die schwächere Variante derselben
  Frage.

### C. Aktiv statt passiv

Hier liegt der eigentliche Wert bei High/Critical.

- **Statusline-Badge.** Das casedesk-Segment zeigt schon
  `case · company · N replies` und cached per Buffername
  (`ui/statusline/modules/casedesk/init.lua`). Ein `⚠ 1h58` anzuhängen kostet
  fast nichts und ist im Alltag vermutlich wirkungsvoller als jedes
  Dashboard: es steht da, ohne dass man fragt. Wichtig: nur anzeigen, wenn
  eine Uhr unter der Warnschwelle liegt — sonst ist es Dauerrauschen und
  wird nach drei Tagen nicht mehr gesehen.
- **Aktive Warnung bei P1/P2.** Timer bzw. `FocusGained`-Autocmd, der ab
  Schwelle notifyt — insbesondere für den Rückmeldetakt („letzte Rückmeldung
  5 h 48 her, nächste in 12 min"). Default **nur** `sla_active_priorities`
  und **eine** Warnung pro Schwelle, nicht wiederholt. Alarm-Müdigkeit macht
  das Feature sonst binnen einer Woche wertlos; lieber eine Warnung zu wenig
  als eine zu viel, weil eine ignorierte Warnung schlimmer ist als keine.
- **`:Cases stale` prioritätsabhängig.** Aktuell flat 7 Tage (`query.lua`).
  Für einen P2 sind 7 Tage absurd spät, für einen P4 normal. Schwelle aus
  `config.sla` ziehen — kleine Änderung, macht den bestehenden Befehl
  deutlich schärfer.

### D. Reporting für die Zielvereinbarung

- **`:Cases sla report [--year 2026]`** — Quote eingehaltener Erstreaktionen
  je Priorität, Ausreißer namentlich mit Delta. Das ist die Zahl, die im
  Gespräch gebraucht wird und die es sonst nirgends gibt.
- Ehrlichkeitsklausel gehört in die Ausgabe: die Zahl ist nur so gut wie
  `last_reply_sent` gepflegt ist. Als „meine Sicht" ausweisen, nicht als
  Wahrheit aus SNOW — sonst diskutiert man im Gespräch über die Zahl statt
  über die Arbeit.

### E. Kleinigkeiten mit täglichem Nutzen

- **SLA-Kontext in den KI-Prompt.** Priorität + verbleibende Frist in
  `templates/KiPrompt.md` — dann weiß das Modell, ob ein *Aktionsplan
  innerhalb 4 h* (P1) gefragt ist oder eine ausgearbeitete Lösung mit
  6-Wochen-Horizont (P3). Ändert die Antwortqualität real, kostet zwei Zeilen
  im Template plus zwei Tokens in `ki.build_prompt`.
- **Reply-Baustein „laufende Rückmeldung".** Bei P1 stündlich braucht es
  einen Ein-Klick-Statusupdate-Text. Neues `.md` unter
  `Workflow/Templates/Wordings/` — taucht in `:Case template` ohne
  Codeänderung auf (CONCEPT.md §8b).
- **`:Case sla --doc`** öffnet `SLA_ServiceLevelAgreement.md`.

## 7. Modulaufbau

Passend zu CONCEPT.md §4 (ein Modul, eine Frage):

```
lua/bindings/usrcmds/case/
  sla/
    init.lua      -- öffentliche API: status(case), overdue(), report()
    clock.lua     -- elapsed/deadline, Geschäftszeit-Rechnung (rein, testbar)
    stream.lua    -- Activity-Stream -> Lib.Case.SlaEvent[]
    render.lua    -- Ausgabeformate: Infocard, Dashboard-Zeile, Badge
```

`clock.lua` ist bewusst frei von Neovim-APIs — reine Zeitarithmetik, damit
sie ohne laufendes Neovim geprüft werden kann. Das ist der einzige Teil, in
dem sich ein Rechenfehler lautlos versteckt.

## 8. Risiken und Fallen

| Risiko | Gegenmaßnahme |
| --- | --- |
| **Das Dokument warnt selbst**: SLAs gelten **SAP gegenüber Tricentis**, SolEx-Kundenverträge weichen ab | Anzeige durchgehend als „SAP-SLA" labeln; nie eine Formulierung, die kundenverbindlich klingt |
| Alarm-Müdigkeit | Default nur P1/P2, eine Warnung pro Schwelle, Badge nur unter Warnschwelle |
| `last_reply_sent` wird nicht gepflegt → Zahlen wertlos | Kein eigener Schritt: Abschlussfrage in `:Case reply check`, wo man ohnehin steht. Fehlt der Wert, wird „unbekannt" gezeigt, nicht geraten |
| Zeitzone/Sommerzeit | Intern UTC-Epoch, GMT-Zeile des Streams bevorzugen, Umrechnung nur beim Rendern |
| Feiertage nicht berücksichtigt | Als bekannte Ungenauigkeit dokumentieren, konfigurierbare Datumsliste nachrüstbar |
| Stream-Format ändert sich (andere SNOW-Ansicht) | Parser scheitert nie hart: leere Liste + Hinweis, kein Abbruch |
| Falsches Gefühl von Sicherheit („das Tool warnt schon") | Report weist Datenquelle aus; `:Case sla` zeigt „Priorität unbekannt" statt Default-Annahme |
| Scope-Creep Richtung SNOW-Anbindung | Bewusst keine API (gleiche Begründung wie CONCEPT.md §8e/§8i: keine externe Abhängigkeit, keine Latenz, kein Nicht-Determinismus) |

## 9. Offene Fachfragen

1. **Wann startet die Erstreaktions-Uhr?** Ab Ticket-Erstellung bei SAP oder
   ab Zuweisung an mich? Bei 977392 wurde der Case am 05.08. um 16:26
   zugewiesen, das Ticket lief seit dem 29.07. Das entscheidet über „grün"
   oder „längst gerissen" und ist damit die wichtigste Frage im ganzen
   Dokument. **Vorschlag bis zur Klärung: beide anzeigen** (`ab Eingang` /
   `ab Zuweisung`) statt eine Annahme zu verstecken.
2. **`created` in `.case.json` ist die Ordner-Anlagezeit**, nicht der
   Ticket-Eingang. Für die SLA braucht es Letzteren — aus dem ältesten
   Stream-Ereignis ableitbar, aber nur wenn der Stream weit genug zurückreicht.
   Sonst per `:Case info` nachtragbar.
3. **Produktfehler ja/nein** entscheidet bei P3/P4 den Rückmeldetakt (3 Tage
   vs. 2 Wochen). Ein weiteres Infocard-Feld — oder bis auf Weiteres immer
   den strengeren Wert nehmen?
4. **Zählt eine Rückfrage an den Kunden als „Rückmeldung"** im Sinne des
   Takts, oder nur eine inhaltliche Statusmeldung? Betrifft, ob
   `last_reply_sent` bei *jeder* Antwort gesetzt wird.
5. Soll `:Cases sla` auch `Closed/` einbeziehen (für den Report ja, für das
   Dashboard nein)?

## 10. Reihenfolge

> **Paket 1 ist umgesetzt** (2026-08-06): `sla/clock.lua`, `sla/stream.lua`,
> `sla/init.lua`, `:Case sla`, Priorität-Auto-Parse in `:Case activity`,
> `last_reply_sent` via `m` in `:Case reply check`, Statusline-Badge.
> Details, Abweichungen von diesem Konzept und offene Punkte: siehe unten
> **„Notizen zur Umsetzung"**. Pakete 2–4 weiterhin offen.

**Paket 1 — Fundament + Sichtbarkeit** (das eigentliche „im Auge behalten"):
Priorität aus dem Stream parsen · `config.sla` · `clock.lua` + `stream.lua` ·
`:Case sla` · Statusline-Badge.

**Paket 2 — Querschnitt:** `:Cases sla` Dashboard · `:Cases stale`
prioritätsabhängig · `:Case sla --doc`.

**Paket 3 — Exaktheit:** `last_reply_sent` via `:Case reply check` ·
`:Cases sla report`.

**Paket 4 — Aktiv:** Notifications für P1/P2 · Rückmeldetakt-Wecker ·
SLA-Kontext im KI-Prompt · Wordings-Baustein.

Paket 1 ist für sich nützlich und ohne die offenen Fragen aus §9 baubar
(solange beide Startzeitpunkte angezeigt werden). Paket 4 zuletzt, weil
Warnungen erst Sinn ergeben, wenn die Zahlen dahinter stimmen.

## 11. Worked Example: 977392

Realer Fall zum Gegenrechnen (`Cases/Open/977392`):

- Priorität laut Stream: `3 - Moderate`, Impact `2 - Medium` → **P3**,
  Fenster 10x5, Erstreaktion 4 h, Rückmeldung 3 Tage (kein Produktfehler
  bestätigt), Korrektur 6 Kalenderwochen.
- `.case.json` hat **kein** `priority`-Feld — genau die Lücke aus §2/A.
- Ticket-Aktivität ab 29.07.2026 15:06 (lokal), Zuweisung an mich
  05.08.2026 16:26:34, letzte Kundennachricht 05.08.2026 05:58:36 GMT
  („Any update on this ticket please?").
- Ab Zuweisung gerechnet war die Erstreaktion mit dem `:Case`-Anlegen um
  16:29 erfüllt. Ab Ticket-Eingang gerechnet: seit einer Woche gerissen.

Dieser eine Case zeigt beide Kernprobleme — fehlende Priorität und der
uneindeutige Uhr-Start — und eignet sich als Testfall für `clock.lua`.

## Notizen zur Umsetzung (Paket 1)

Abweichungen und Präzisierungen gegenüber diesem Konzept, die erst beim
Bauen sichtbar wurden:

- **`fix_window` ist eine Auslegungsentscheidung, kein Zitat.** "Max. 4 Std."
  (P1) und "6 Kalenderwochen" (P3/P4) sind Kalenderzeit, auch wenn die
  jeweilige Priorität sonst 24x7 bzw. 10x5 nutzt; "Max. 3 Arbeitstage" (P2)
  ist Geschäftszeit, obwohl P2 sonst 24x7 ist. `config.lua` kommentiert das
  an Ort und Stelle. Betrifft nur die Korrekturmaßnahme-Uhr.
- **`M.utc()` (Stream-Zeitstempel → Epoch) ist reine Kalenderarithmetik**
  (Howard Hinnants `days_from_civil`), nicht `os.time`-basiert: Der
  naheliegende "lokale Tabelle bauen, gegen ihren eigenen UTC-Rücklauf
  diffen"-Trick lieferte auf diesem Windows-Host ganzjährig den
  Standard-Offset (CET, +1h) statt CEST (+2h) im August — `os.date("!*t",
  …)`s `isdst` kommt ungesetzt zurück, wodurch `os.time` bei der
  Rück-Interpretation fälschlich "keine Sommerzeit" annimmt. Mit Referenz
  gegen den echten Stream (977392) verifiziert.
- **`last_reply_sent` wird per Taste `m` in `:Case reply check` gesetzt**,
  nicht als eigener `:Case sent`-Befehl — spart einen Merk-Befehl, weil man
  beim Senden ohnehin dort steht.
- **`:Case sla` zeigt beide Erstreaktions-Anker parallel** (ab
  Ticket-Eingang / ab Zuweisung), wie in §9.1 vorgeschlagen — die Frage
  bleibt offen, nichts wurde stillschweigend entschieden.
- Getestet gegen den echten Stream von 977392 (`clock.lua`, `stream.lua`,
  `sla/init.lua` end-to-end, headless) — siehe Werte in §11.

## Literatur und Referenzen

- `C:\repos\WKDBook-Tricentis\Workflow\SLA_ServiceLevelAgreement.md` —
  Quelle der Fristen, inkl. des Hinweises auf abweichende SolEx-Verträge
- [Confluence: SAP Service Level Agreements (SLAs)](https://tricentis.atlassian.net/wiki/spaces/SUP/pages/320726887/SAP+Service+Level+Agreements+SLAs)
- [CONCEPT.md](CONCEPT.md) §3 (Zustand = Ordner), §4 (Modulaufbau),
  §8b (Reply-Bausteine), §8h (Zeitachse), §8i (KI-Runde)
- [ROADMAP.md](ROADMAP.md) — „Dashboard beim Start: offene Cases nach
  Liegezeit" wird von `:Cases sla` mit abgedeckt
- [Workflow.md](../../NOTES/casedesk/Workflow.md) §2 (Arbeiten am Case),
  §4 (`:Cases stale`), §6 (warum Minimalität selbst ein Feature ist)

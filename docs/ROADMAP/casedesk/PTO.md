# casedesk — `:Tricentis pto` (Konzept)

Abwesenheiten (Urlaub, Krankenstand, …) haben jedes Mal dieselben paar
Schritte, die man selten genug macht, um sie zu vergessen — und zwar
ausgerechnet dann, wenn man gestresst oder krank ist. Aktuell stehen sie
als Fließtext in den Notizen. Dieses Dokument entwirft daraus einen
Befehl.

> **Status: Konzept, nichts gebaut.** Reihenfolge und Aufwandsschätzung
> stehen in §9.

---

## Table of content

- [1. Lohnt sich das überhaupt](#1-lohnt-sich-das-überhaupt)
- [2. Der eigentliche Gewinn: die Liste, die keine Notiz führen kann](#2-der-eigentliche-gewinn-die-liste-die-keine-notiz-führen-kann)
- [3. Warum `:Tricentis` und nicht `:Case`](#3-warum-tricentis-und-nicht-case)
- [4. Datenformat: Markdown auf Platte, kein Lua-Table](#4-datenformat-markdown-auf-platte-kein-lua-table)
- [5. Pflicht und Optional](#5-pflicht-und-optional)
- [6. Der Dialog](#6-der-dialog)
- [7. Berechnete Tokens, vor allem das Rückkehrdatum](#7-berechnete-tokens-vor-allem-das-rückkehrdatum)
- [8. Was bewusst NICHT gebaut wird](#8-was-bewusst-nicht-gebaut-wird)
- [9. Reihenfolge und Aufwand](#9-reihenfolge-und-aufwand)
- [10. Offene Fragen](#10-offene-fragen)

---

## 1. Lohnt sich das überhaupt

Ehrliche Antwort vorweg, weil die Frage so gestellt wurde: **die Templates
allein lohnen sich nicht.** Zwei Mails und drei Merksätze in einen Befehl
zu gießen ist ein Snippet-Manager, und dafür gibt es `:Case template`
bereits. Wer nur das baut, hat Aufwand in etwas gesteckt, das eine
Markdown-Datei mit `yy` genauso gut kann.

Was sich lohnt, sind drei andere Dinge:

**Erstens: das Rückkehrdatum ist eine Rechnung, keine Konstante.** Die
Outlook-Antwort sagt „will return on Monday, August 30th". Dieses Datum
ist der nächste Arbeitstag nach dem letzten Abwesenheitstag — inklusive
Wochenende, und beim Formulieren rechnet man es jedes Mal neu im Kopf
nach. Falsch gerechnet heißt: der Kunde wartet einen Tag zu lang, oder man
verspricht sich selbst einen Tag zu früh. casedesk hat die
Arbeitstags-Arithmetik längst (`sla/clock.lua`, das 10x5-Fenster für
P3/P4). Das ist ein Ein-Zeilen-Aufruf gegen bestehende, getestete Logik.

**Zweitens: die Pflicht/Optional-Unterscheidung geht in Fließtext
verloren.** In der Notiz steht „Email (optional auch slack) bin krank" und
darunter ein „WICHTIG:"-Satz. Beim schnellen Drüberlesen im Krankheitsfall
sieht das gleich aus. Es ist aber nicht gleich: die Mail an den Manager
ist verpflichtend, Slack ist Höflichkeit. Eine Liste, die das strukturell
trennt statt typografisch, liest sich mit halber Aufmerksamkeit richtig —
und mit halber Aufmerksamkeit liest man sie ja gerade.

**Drittens: §2**, und das ist der eigentliche Grund.

### Der ehrliche Einwand dagegen

Der Krankenstands-Fall ist der, wo die Liste am meisten wert wäre, und der,
wo man am wenigsten wahrscheinlich Neovim aufmacht. Wer wirklich krank
ist, greift zum Handy. Das ist eine echte Einschränkung, und sie lässt sich
nicht wegdesignen — nur abmildern: wenn der ganze Vorgang **ein** Befehl
ist, dessen Ausgabe eine fertige Mail in der Zwischenablage plus drei
Zeilen Checkliste ist, dann ist das auch der Weg mit dem geringsten
Kraftaufwand. Genau deshalb sollte der Dialog so kurz wie irgend möglich
sein (§6): jede zusätzliche Rückfrage ist ein Grund mehr, es doch wieder
händisch zu machen.

## 2. Der eigentliche Gewinn: die Liste, die keine Notiz führen kann

Vor einem Urlaub ist der wichtigste Punkt keiner, der in der Notiz steht,
weil keine Notiz ihn kennen kann:

> **Welche meiner offenen Cases reißen eine Frist, während ich weg bin?**

casedesk weiß das. `:Cases sla` rechnet für jeden offenen Case aus, wann
welche Uhr abläuft; mit dem Abwesenheitszeitraum als zweitem Eingabewert
wird daraus eine gefilterte Liste: *diese* Cases brauchen vor der Abreise
eine Rückmeldung oder eine Übergabe, alle anderen nicht. Und
`Workflow/Templates/Swarming/HandOverCase` existiert bereits als
Reply-Block.

Damit wird aus der Checkliste etwas, das eine Markdown-Datei prinzipiell
nicht leisten kann:

```
Vor der Abreise (3 Cases mit Frist im Zeitraum):
  [ ] 989508  Rückmeldung fällig 25.08. 14:00   → :Case reply 989508
  [ ] 996010  Korrekturmaßnahme fällig 27.08.   → :Case reply 996010
  [ ] 1041708 Erstreaktion fällig 26.08. 09:00  → :Case reply 1041708
```

Das ist der Punkt, an dem sich der Befehl von einem Snippet-Manager
unterscheidet, und meiner Einschätzung nach der einzige, der den Aufwand
allein trägt. Alles andere in diesem Dokument ist Beiwerk, das billig
mitkommt, weil die Bausteine ohnehin da sind.

Für den Krankenstand greift das naturgemäß nicht — den plant man nicht
vor. Dort ist die Liste rein statisch, und das ist in Ordnung: sie hat
dort auch nur drei Punkte.

## 3. Warum `:Tricentis` und nicht `:Case`

`:Case` und `:Cases` sind auf `config.root` (`Cases/SAP_Support`) begrenzt.
Abwesenheit ist auf gar keinen Case begrenzt. `:Tricentis` ist der Verb
für alles, was über das ganze Arbeits-Repo reicht — und die Templates und
Checklisten gehören genau dorthin (§4), neben `Workflow/Templates/` und
`Workflow/SLA_ServiceLevelAgreement.md`.

Eine Unschärfe bleibt und soll benannt sein, weil `init.lua`s eigener
Kommentar an dieser Stelle ausdrücklich davor warnt, ein Verb still weiter
zu fassen als sein Name verspricht: `:Tricentis` ist heute als
„Cross-Repo-Werkzeuge für die Wissensbasis" beschrieben, und PTO ist keine
Wissensbasis, sondern persönliche Administration. Dagegen spricht
allerdings, dass die Checklisten als Dateien tatsächlich im Arbeits-Repo
liegen werden und damit genau so ein Repo-Artefakt sind wie die
Reply-Blocks. Konkreter Vorschlag: `:Tricentis`, und die `desc` des Verbs
minimal weiten („Werkzeuge, die über das ganze Arbeits-Repo reichen, nicht
case-gebunden") statt ein drittes Verb einzuführen, das genau einen
Unterbefehl hätte. Siehe §10.1.

```
:Tricentis pto [art]     " art: vacation|sick|… — weggelassen: kit.select
:Tricentis pto back      " die Rückkehr-Seite, §9 Paket 4
```

## 4. Datenformat: Markdown auf Platte, kein Lua-Table

Der naheliegende Weg wäre eine Tabelle in `config.lua`. Das wäre aus
demselben Grund falsch, aus dem `blocks.lua` seine Reply-Blocks von der
Platte liest statt aus Lua: „momentan nur zwei mit wenigen Punkten, das
kann sich aber erweitern" heißt, dass die Liste wachsen wird — und dann
soll eine neue Abwesenheitsart eine **neue Datei** sein, kein Lua-Edit.
Das ist in diesem Modul durchgehend so gehalten (`blocks.lua`,
`config.command_topics`, `config.stream_stammdaten_labels`) und es gibt
keinen Grund, hier davon abzuweichen.

Vorschlag: `Workflow/PTO/<art>.md` im Arbeits-Repo, entdeckt wie
`blocks.list()` es tut. Eine Datei beschreibt eine Abwesenheitsart
vollständig — Checkliste und Textbausteine zusammen, weil sie sich
zusammen ändern:

```markdown
# Sick leave

## Checklist

- [!] Email an den Manager (Hiva) — zwingend
- [ ] Slack-Nachricht ins Team — optional, aber nett
- [ ] Workday-Eintrag
- [!] Falls ein Remote-Call in den Krankenstand fällt: unbedingt dem
      Manager mitteilen

## Template: Manager

Hi Hiva,
…

## Template: Out of office

Hello,

Thank you for your email. I am currently out of the office and will
return on {return_date}. …
```

Die Namen der Beteiligten (Henrique, Hiva) stehen bewusst **in der
Datei**, nicht in `config.lua`: sie ändern sich, wenn sich das Team
ändert, und dann will man eine Textdatei anfassen, keinen Lua-Code. Was
dagegen **nicht** in die Datei gehört, ist alles, was pro Abwesenheit
anders ist — Dauer, Grund, Rückkehrdatum. Das sind Tokens (§7).

Ein angenehmer Nebeneffekt der Datei-Lösung: die Checkliste ist auch ohne
Neovim lesbar. Auf dem Handy, wenn man wirklich krank ist (§1).

## 5. Pflicht und Optional

`- [!]` gegen `- [ ]` als Markierung — bewusst innerhalb der
Markdown-Checkbox-Syntax, damit die Datei auch roh gelesen noch eine
normale Checkliste ist und in jedem Markdown-Viewer funktioniert.

In der Ausgabe werden die beiden Gruppen getrennt gerendert, nicht nur
verschieden eingefärbt: Pflichtpunkte zuerst, unter einer eigenen
Überschrift, optionale darunter. Der Grund ist derselbe wie in §1: die
Liste soll mit halber Aufmerksamkeit richtig lesbar sein, und Farbe ist
das erste, was dabei durchrutscht.

Denkbare dritte Stufe, aber erst wenn es sie wirklich gibt: bedingte
Punkte (`- [?] Nur falls …`) — der Remote-Call-Punkt im Krankenstand ist
genau so einer. Bis dahin ist er ein Pflichtpunkt mit „falls" im Text, und
das reicht.

## 6. Der Dialog

So kurz wie möglich, aus dem Grund in §1. Konkret zwei Schritte, beide mit
brauchbarem Default:

1. **Art** — `kit.select` über die gefundenen Dateien. Entfällt, wenn als
   Argument mitgegeben (`:Tricentis pto sick`).
2. **Zeitraum** — `kit.form` mit „von" (Default: heute) und „bis". Für den
   Krankenstand darf „bis" leer bleiben: man weiß es meist nicht. Dann
   entfällt das Rückkehrdatum im Template und die Out-of-office-Zeile
   ebenfalls — was richtig ist, denn eine Abwesenheitsnotiz mit erfundenem
   Rückkehrdatum ist schlechter als keine.

Mehr nicht. Kein Grund-Freitextfeld: der Grund ist die Art.

Ausgabe: ein Scratch-Buffer wie `:Tricentis cheatsheet` ihn schon
erzeugt — die gerenderte Checkliste oben, die ausgefüllten Templates
darunter, jedes unter seiner Überschrift. Der Buffer ist der Arbeitsplatz:
Templates von dort mit `yy`/Visual-Yank in Outlook oder Slack, Punkte im
Buffer abhaken. Kein zweiter Kopier-Mechanismus nötig.

## 7. Berechnete Tokens, vor allem das Rückkehrdatum

Dieselbe Substitution wie `blocks.lua`/`templates.lua` sie schon machen
(`%{(%w+)%}`), mit ein paar zusätzlichen Tokens:

| Token | Herkunft |
| --- | --- |
| `{from}` / `{to}` | aus dem Formular |
| `{return_date}` | **berechnet**: nächster Arbeitstag nach `{to}` |
| `{days}` | Arbeitstage im Zeitraum — für den Workday-Eintrag |
| `{name}`, `{today}` | existieren bereits |

`{return_date}` ist der interessante. „Nächster Arbeitstag" ist genau die
Frage, die `sla/clock.lua` für die 10x5-Fenster bereits beantwortet —
kein neuer Kalender-Code, sondern ein Aufruf gegen bereits gegen echte
Daten verifizierte Logik.

Ein echtes neues Stück gibt es trotzdem: „Monday, August 30th" ist
englische Ordinalformatierung, und die kann Lua nicht von sich aus
(`os.date` liefert „30", nicht „30th"). Das sind ~10 Zeilen mit den drei
üblichen Sonderfällen (11th/12th/13th, nicht 11st/12nd/13rd) — klein, aber
genau die Sorte Detail, die man beim Schätzen übersieht und die falsch
formatiert peinlich aussieht.

Feiertage sind bewusst außen vor: `sla/clock.lua` kennt sie auch nicht
(SLA.md führt das als offene Frage), und ein Rückkehrdatum, das auf einen
Feiertag fällt, fällt einem beim Lesen der fertigen Mail auf. Ein halb
gepflegter Feiertagskalender wäre schlechter als keiner, weil man ihm dann
glaubt.

## 8. Was bewusst NICHT gebaut wird

Dieselbe Haltung wie überall sonst im Modul — Text erzeugen, nicht
handeln:

- **Keine Mail verschicken.** Ausgabe ist Text zum Einfügen, wie `:Case
  snow` die Ticket-ID kopiert statt den Browser zu steuern und `:Case
  reply check` fragt „schon raus?" statt selbst zu senden.
- **Kein Workday, kein Slack, kein Outlook-API.** Der Workday-Eintrag ist
  ein Checklistenpunkt, keine Integration. Die Anmeldung an
  Firmensystemen zu automatisieren ist ein Vielfaches des Aufwands des
  gesamten restlichen Features, und bricht beim nächsten SSO-Update.
- **Keine Erinnerungen/Timer.** `sla/notify.lua` existiert für Fristen mit
  harten Konsequenzen. Urlaub ist keine Frist.
- **Keine Abwesenheits-Historie** in Paket 1. Als spätere Option denkbar
  (`Workflow/PTO/Log/2026-08-24_vacation.md`, um nachzusehen, was man
  letztes Mal getan hat) — aber erst, wenn der Wunsch danach real
  auftritt, nicht auf Verdacht.

## 9. Reihenfolge und Aufwand

Aufsteigend nach Aufwand, wie in ROADMAP.md üblich. Gesamteinschätzung
vorweg: **klein bis mittel**, weil fast alles an Maschinerie schon steht —
Route-Registrierung (`composer.verb`), Auswahl (`kit.select`), Formular
(`kit.form`), Datei-Entdeckung (`blocks.lua`s Muster), Token-Ersetzung
(`templates.lua`), Scratch-Buffer-Ausgabe (`ui.cheatsheet`). Genuin neu
sind: das Dateiformat samt Parser, die Ordinalformatierung, und §2.

**Paket 1 — Gerüst und statische Ausgabe.** `pto.lua` (Dateien finden,
Checkliste und Template-Abschnitte parsen), die Route, `kit.select` über
die Arten, Ausgabe als Scratch-Buffer mit getrennten Pflicht/Optional-
Gruppen. Noch ohne Zeitraum-Formular, Templates unausgefüllt. Danach ist
der Befehl bereits benutzbar und ersetzt das Nachschlagen in den Notizen.
*Klein.*

**Paket 2 — Zeitraum und berechnete Tokens.** Das Formular aus §6,
`{from}`/`{to}`/`{return_date}`/`{days}`, Ordinalformatierung, der
Sonderfall „bis unbekannt". Danach ist die Out-of-office-Mail fertig zum
Einfügen. *Klein.*

**Paket 3 — Die SLA-Liste (§2).** Offene Cases gegen den
Abwesenheitszeitraum, gerendert als eigener Checklistenblock mit
Case-Nummer, Fristart und Fälligkeit. Nutzt `query.sla_dashboard()` und
`sla.status()` unverändert. Nur für Arten, die im Voraus geplant werden —
ob das ein Flag in der Datei ist (`plan_ahead: true`) oder schlicht daran
hängt, ob ein „von" in der Zukunft liegt, ist eine Detailfrage für die
Umsetzung. *Mittel — und das Paket, das den Aufwand rechtfertigt.*

**Paket 4 — `:Tricentis pto back`.** Die Rückkehrseite hat ihre eigene,
kurze Liste: Abwesenheitsnotiz abschalten, nachsehen was in der
Zwischenzeit gerissen ist (wieder `:Cases sla`, nur rückwärts gefragt),
Übergabe-Notizen des Vertreters lesen. Fällt fast vollständig aus
Paket 1+3 heraus. *Klein.*

Paket 1 und 2 sind unabhängig nützlich. Paket 3 setzt 1 voraus.

## 10. Offene Fragen

**10.1 Verb-Zuordnung.** `:Tricentis` mit leicht geweiteter `desc`, oder
ein eigenes Verb? Empfehlung in §3: `:Tricentis`, weil ein Verb mit genau
einem Unterbefehl schlechter ist als eine leicht unscharfe Verb-Grenze.
Revidierbar, sobald ein zweiter nicht-wissensbasierter Unterbefehl
dazukommt.

**10.2 Wo genau im Arbeits-Repo?** `Workflow/PTO/` vorgeschlagen. Falls
die Notizen dazu heute woanders liegen, gewinnt der bestehende Ort — die
Dateien sollen dorthin, wo du ohnehin nachsiehst.

**10.3 Mehrere Vertretungen.** Heute ist Henrique fachlich und Hiva
eskalierend zuständig, beide fest im Text. Wenn sich das pro Abwesenheit
unterscheidet, müssten daraus Tokens mit Auswahl werden. Erst bauen, wenn
es eintritt.

**10.4 Sprache.** Die Out-of-office-Mail ist Englisch, die Checkliste
deutsch. Das ist kein Fehler, sondern korrekt — die Mail geht an Kunden,
die Liste liest nur der Autor. Nur der Vollständigkeit halber notiert,
damit es später niemand „vereinheitlicht".

## Literatur und Referenzen

- [CONCEPT.md](CONCEPT.md) — Modulaufbau, `blocks.lua` gegen
  `templates.lua`
- [SLA.md](SLA.md) — §3 (Uhr-Modell), die Arbeitstags-Arithmetik aus §7
  und die Fristenliste aus §2 kommen von dort
- [ROADMAP.md](ROADMAP.md)
- [Usercmds.md](../../NOTES/casedesk/Usercmds.md) — die `:Tricentis`-Tabelle
- `lua/bindings/usrcmds/case/blocks.lua` — das Vorbild für §4
- `lua/bindings/usrcmds/case/sla/clock.lua` — Arbeitstags-Fenster

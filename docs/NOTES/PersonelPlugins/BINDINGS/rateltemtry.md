Now the `flush` subcommand.

Now a spec, then measure it end to end.

Suite is green. Mutation-testing the new spec:

Now the docs — README and the plugin's own map.

**Ja, `v0.3.0` ist veröffentlicht** — steht als *Latest*, das Abzeichen im README liest jetzt `release: v0.3.0` statt „no releases", und `/releases/latest` löst auf. `v0.1.0` liegt weiterhin als Entwurf daneben; wenn du den nicht willst, ist er einen Handgriff los.

---

## Deine Telemetrie-Fragen — nachgemessen, nicht aus dem Kopf

Ich habe echte Läufe gegen eine temporäre Cache-Datei gefahren:

```
Sitzung 1: 3 Aufrufe, nur Timer-Flush  ->  hello=3 auf der Platte, läuft weiter
Sitzung 2: 2 Aufrufe, dann stop        ->  hello=5, sessions=2
```

**1. Live oder erst beim Stop?** — **Live.** Drei Momente schreiben ohnehin, und jeder *merged* in das, was schon da liegt (statt es zu überschreiben):

| Wann | Auslöser |
|---|---|
| alle 60 s während des Laufs | der periodische Flush (`flush_interval_ms`) |
| bei `stop` | `stop()` flusht, bevor es die Wrapper zurückbaut |
| beim Beenden von nvim | ein `VimLeavePre`-Autocommand pro Instanz |

Dein „idealerweise wäre es so, dass beim Beenden von nvim die Daten mal geschrieben werden" ist also schon gebaut — es stand nur nirgends.

**2. Nach dem Neustart?** — **Die Daten laufen weiter, der Laufzustand nicht.** Die Zahlen addieren sich in derselben Datei (`sessions` zählt hoch), auch wenn zwei nvim gleichzeitig laufen. Was du nach dem Neustart eventuell neu startest, ist die *Aufzeichnung*, nicht die *Daten* — abhängig davon, wer sie wired: `telemetry.lazy` (wrappt bei `VimEnter`), `:RATelemetry setup|full`, oder dein eigenes `t.start()`. Ein persistiertes **„aus"** gibt es (`:RATelemetry disable <ns>`), ein persistiertes „an" bewusst nicht: etwas abzuschalten ist eine Entscheidung, die man sich merkt; es einzuschalten sagt deine Config bei jedem Laden ohnehin.

**3. Dein Wunsch nach einem Usrcmd zum Zwischenspeichern** — das war die echte Lücke. `inst.flush()` gab es als API, auf der Kommandofläche nicht:

```vim
:RATelemetry flush [ns]
```

Schreibt jetzt, ohne irgendetwas zu beenden, und nennt die Datei. Der Befehl, zu dem man sonst greift, ist `stop` — der einen die Wrapper und die Sitzungskontinuität kostet, um einen Schreibvorgang zu kaufen, der ohnehin kam.

**4. Der Backup-Prompt** — hier ist die gute Nachricht, dass dein Wunsch schon erfüllt war, nur unsichtbar: der Prompt fragt nach einem *Verzeichnis*, die Dateien heißen längst `<namespace>-YYYYMMDD-HHMMSS.json`, also Datum **und** Uhrzeit im Namen, nichts wird je überschrieben. Das steht jetzt im Prompt selbst, damit niemand rätselt, ob er einen Namen wählen soll.

Dazu nennen `stop` und `flush` jetzt den Pfad, in den geschrieben wurde — „ist es gespeichert?" ist die Frage, die dieses Subsystem am häufigsten bekommt, und ein Pfad beantwortet sie billiger als ein Absatz über Flush-Intervalle.

Neues Spec mutationsgetestet, 7 von 7 gefangen (u. a. Timer feuert nie, `flush` als No-op, `flush` beendet heimlich die Aufzeichnung). CI grün auf `65c0aa5`, gepusht.

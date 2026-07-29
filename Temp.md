## docmudule

Los. Phase 1, Schritt 1: `fn.line_end` — die Daten liegen beim Scan schon vor.

`line_end` stimmt exakt mit den echten `end`-Zeilen überein. Jetzt das Kernstück — `history.lua`, pur wie `diff.lua`:

Jetzt die Typen:

Jetzt gegen echte Commits testen — nicht gegen ein Fixture:

Funktioniert. Ich prüfe die Plausibilität genauer und teste mehrere Commits:

Zweiter Fall ist verdächtig — `core.lua` hat definitiv Funktionen und der Commit ändert `dedent`/`is_array`. Ich gehe dem nach:

Bestätigt — und das ist ein echter Fund: die Änderung liegt in `S.dedent`s Rumpf (Zeilen 235–239, 249–254), aber **historische Artefakte haben kein `line_end`**. Mein Fallback `line_end or line` degradiert damit auf „nur die Deklarationszeile zählt" — für alle 92 historischen Commits praktisch nutzlos. Das repariere ich:

Jetzt findet er **`S.dedent` und `M.is_array`** — exakt die zwei Funktionen aus der Commit-Message — und flaggt ehrlich `approximate: true`. Jetzt die Tests:

`deps.impact` verträgt fehlende Felder — gut für synthetische Test-IRs. Jetzt die Tests:

Alle Tests grün beim ersten Lauf. Jetzt `history` in `init.lua` einhängen, konsistent mit `diff`/`cli`:

Alles grün. Jetzt die Doku:

CI grün. Roadmap nachziehen:

**Phase 1 steht** ([`08b4494`](https://github.com/StefanBartl/lib.nvim/commit/08b4494), CI grün).

**`fn.line_end`** — verifiziert gegen `coverage.lua`, alle fünf Spans treffen die echten `end`-Zeilen exakt.

**`history.lua`** — pur wie `diff.lua` (Text + IRs rein, Struktur raus, kein git, kein Dateisystem). Liefert `touched`, `callers`, `calling_modules` (präzise) und `impacted_modules` (transitiv).

## Ein Fund unterwegs, der eine Korrektur erzwang

Der naive Fallback für alte Artefakte (`line_end or line`) heißt effektiv „zählt nur, wenn die Änderung *exakt* auf dem `function`-Keyword landet". Gemessen an `1ce752e` — dessen Hunks bei Zeile 235–239 und 249–254 mitten im Rumpf von `S.dedent` liegen — fand das **null** der zwei Funktionen, die der Commit nachweislich ändert. Stille, die wie eine Antwort aussieht.

Jetzt wird ein fehlendes `line_end` als *Startzeile der nächsten Funktion minus eins* genähert (über- statt unterattribuiert) und setzt `Impact.approximate`. Damit meldet derselbe Commit korrekt `S.dedent` und `M.is_array`.

**Wichtig für Phase 3:** Commits ab heute werden exakt attribuiert, alle 92 davor genähert. Die UI muss das anzeigen, nicht verschweigen — steht so in der Roadmap.

## Gegen echte Commits verifiziert, nicht nur Fixtures

`fd27b90` meldet korrekt `cyclomatic_complexity` mit `M.scan_file` als einzigem Aufrufer — und attribuiert die `render/html.lua`-Änderung korrekt *nicht*, weil sie im `local JS = [[…]]`-String außerhalb jeder Lua-Funktion liegt. Fixture-Tests decken beide Grenzen inklusive, die Lücke zwischen Funktionen, alle vier Hunk-Formen, `/dev/null`-Add/Delete, den Näherungs-Fallback und fehlende IRs ab.

Nächster Schritt wäre **Phase 2**: `:LibMap impact <ref>` → Quickfix. Klein, sofort im Review-Alltag brauchbar, und beweist die Logik an echten Commits, bevor Server und UI daraufkommen. Soll ich?



###

 Q




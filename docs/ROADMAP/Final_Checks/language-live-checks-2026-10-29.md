# language.nvim — Live-Checks (Stand 2026-10-29)

Zwei Übersetzungs-Prüfungen, die nur mit echtem `trans` bzw. echtem DeepL-Schlüssel gehen und auf
der Agent-Maschine nicht möglich waren. Jeder Abschnitt gehört zu einer Task im `tasks-vault`
(Area `language.nvim`); ist ein Abschnitt durch, die Task mit `done` schließen. Ein Befund: unter
"Befunde" eine Zeile, daraus wird eine `kind: bug`-Task.

**Vorher:** language.nvim aktuell (`:Lazy update language.nvim`), Neovim neu starten,
`:checkhealth language` ohne Fehler. Doku: `docs/FEATURES/TRANSLATE.md`.

## Inhaltsverzeichnis

- [1. Shell-Engine: stdin-Pfad mit echtem `trans` unter Windows](#1-shell-engine-stdin-pfad-mit-echtem-trans-unter-windows--offen)
- [2. `translate_markdown` mit echtem DeepL-Schlüssel messen](#2-translate_markdown-mit-echtem-deepl-schlüssel-messen--offen)
- [Befunde](#befunde)

---

## 1. Shell-Engine: stdin-Pfad mit echtem `trans` unter Windows — offen

Task `language.nvim/shell-engine-stdin-pfad-mit-echtem-trans-unter-windows-verif`. Folge von
`translate-shell-text-via-stdin` (`language.nvim@aa2062d`): die shell-Engine gibt den Block auf stdin
an `trans`. Das Verhalten (Zeile für Zeile, leere Zeilen bleiben, 1:1-Zeilen bei `-b`) ist nur aus
dem translate-shell-Quelltext belegt. Laut Doku läuft ein `trans.cmd`-Shim über `cmd.exe /c`; Limit
der Engine unter Windows 6000 Bytes; pro nicht-leerer Zeile eine Anfrage, `translate.timeout_ms`
gilt je Zeile.

**Vorbereitung:**

- [ ] `trans` ist installiert: `trans -V` im Terminal liefert eine Version (translate-shell; unter
      Windows möglichst über ein `.cmd`-Shim; Installationsweg notieren: ______)
- [ ] In der Config `translate.engine = "shell"` (nur zum Test; danach zurück). Genauen Schlüssel
      für Befehl/Argumente in `docs/FEATURES/TRANSLATE.md` (Abschnitt Provider) gegenlesen. Frage
      offen: wie ist `translate.shell` zu konfigurieren, wenn `trans` nicht im PATH liegt?
- [ ] `:checkhealth language` meldet die Shell-Engine als verfügbar

**Testtext** in einen Scratch-Buffer (Deutsch, Umlaute, Leerzeile, `"` und `&`):

```text
Das ist der erste Satz mit "Anführungszeichen".

Zweite Zeile: Müll & Größe, schön gemäß Übung.
Dritte Zeile ohne Sonderzeichen.
```

**Schritte:**

- [ ] Block markieren, `:'<,'>Translate EN` (Engine "shell"; Ausgabe wie in `--output=` gewählt)
- [ ] Gleiche **Zeilenzahl** wie im Original (4 Zeilen)
- [ ] Die **Leerzeile** steht an derselben Stelle (Zeile 2)
- [ ] `"` und `&` kommen unverfälscht zurück (keine `&amp;`, keine abgeschnittene Zeile, keine
      Shell-Fehlermeldung von `cmd.exe`)
- [ ] **Umlaute** (ä ö ü ß) im Eingabetext kommen über stdin korrekt an (das Übersetzungsergebnis
      ist sinnvoll, keine Mojibake wie `Ã¼`); ebenso im Rückweg, z. B. `:Translate DE` auf einem
      englischen Text mit `"` und `&`
- [ ] Ein Block nahe an der Obergrenze (knapp unter 6000 Bytes) geht durch; darüber kommt die
      dokumentierte Ablehnung statt eines Hängers
- [ ] Zeitverhalten: ein Block mit ~20 nicht-leeren Zeilen bleibt unter dem Timeout (`timeout_ms`
      je Zeile)

### Falls rot

Notieren: Eingabe, Ausgabe wörtlich, `trans`-Version, Aufrufform (`.cmd`-Shim oder `.exe`),
Codepage der Konsole. Abweichung = **Bug-Task in language.nvim** (Tag `translate`, `windows`).

**Danach:** Task mit `done` schließen; `translate.engine` zurücksetzen.

---

## 2. `translate_markdown` mit echtem DeepL-Schlüssel messen — offen

Task `language.nvim/translate-markdown-deepl-mit-echtem-schluessel-messen-platzh` (kind: research,
Priorität 2). `translate_markdown` maskiert Inline-Code und Link-Ziele als ASCII-`{n}` und schickt
bis zu 40 Texte je Anfrage an die Engine. Mit Google und einem Fake-Provider gemessen, mit DeepL
nicht (im Spike fehlte `DEEPL_API_KEY`). `tag_handling`/`ignore_tags` ist bewusst **nicht**
eingebaut: die Annahme "`{n}` braucht keine Tags" ist zu messen. Vorbild der Messung:
`mdview.nvim/Backlog/FEATURES/2026-10-06_display-lang-spike.md`.

**Vorbereitung (Schlüssel!):** `DEEPL_API_KEY` (Free-Schlüssel) in der Umgebung des Neovim-Prozesses
setzen (User-Scope, Neovim neu starten); **kein Schlüssel in Chat, Task oder Repo** (SEC-10/SEC-15).
`:lua print(vim.env.DEEPL_API_KEY ~= nil)` muss `true` sein (den Wert nicht ausgeben).

**Messskript:** `translate_markdown` ist kein Befehl, nur Lua-API (`docs/FEATURES/TRANSLATE.md`,
"Markdown API"). Ein Wegwerf-Skript im Scratchpad reicht, nicht ins Repo:

```lua
local lines = vim.fn.readfile("TESTS/fixtures/markdown/readme_de.md")
local t0 = vim.uv.hrtime()
require("language").translate_markdown(lines, { target = "EN", engine = "deepl", cache = false,
  concurrency = 3 }, function(ok, result, info)
  print(ok, (vim.uv.hrtime() - t0) / 1e6 .. " ms", vim.inspect(info))
end)
```

**Schritte:**

- [ ] Fixture `TESTS/fixtures/markdown/readme_de.md` mit `engine = "deepl"`, `cache = false`:
      `info.failed` und `info.retries` notieren: failed ______ retries ______ (Einheiten gesamt ______)
- [ ] Ein großes Dokument (> 100 Einheiten, z. B. eine lange Feature-Doku) genauso: failed ______
      retries ______ Einheiten ______
- [ ] Kaltlauf-Zeit bei `concurrency` = 1 / 3 / 5: ______ / ______ / ______ ms (`cache = false`)
- [ ] Ein-Absatz-Änderung: Dokument einmal übersetzen (Cache an), einen Absatz ändern, erneut
      laufen lassen: Zeit ______ ms, nur die geänderte Einheit geht raus (`info.requests`)
- [ ] Spot-Check: Inline-Code und Link-Ziele im Ergebnis unversehrt (`{n}` kommt überall
      zurück)
- [ ] Zahlen in `docs/FEATURES/TRANSLATE.md` nachtragen (das ist eine Repo-Änderung, danach, nicht
      jetzt)
- [ ] **Entscheidung:** reicht `{n}`, oder bringt `tag_handling=xml` mit `ignore_tags` messbar
      weniger Fehlschläge? Wenn ja: als Option im DeepL-Provider (nicht in der Markdown-Schicht)
      als eigene Task anlegen. Entscheidung: ______

### Falls rot

Platzhalter gehen verloren (`info.failed > 0`): welche Konstruktion (Inline-Code, Link-Ziel,
Fußnote), Beispielzeile ohne Schlüssel/Kundendaten. HTTP-Fehler (456 Quota, 429): Statuscode
notieren, nicht wiederholen, bis das Free-Kontingent (500 000 Zeichen/Monat) geklärt ist.

**Danach:** Messwerte und Entscheidung in die Notizen der Task, dann `done`.

---

## Befunde

-

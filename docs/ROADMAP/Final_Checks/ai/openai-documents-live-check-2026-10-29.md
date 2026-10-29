# ai.nvim — `openai` file-Part (documents) live prüfen (Stand 2026-10-29)

Task `ai.nvim/openai-documents-live-check` (Priorität 3, Tag `needs-api-key`). Der
`openai`-Provider meldet `documents = false` (`lua/ai/providers/openai.lua:30`); `user_content()`
baut bisher nur `image_url`-Parts. Erst wenn der `file`-Part von Chat Completions gegen die echte
API geprüft ist, wird er auf `true` gesetzt, und `pdfport.nvim` bekommt sein
`openai`-Extraktions-Backend billig (`pdfport.nvim/openai-extraction-backend`, `blocked_by` auf diese
Task). Ergänzt `live-testing-plan.md` (Abschnitt 3, `openai`) in diesem Ordner; dort nichts geändert.

**Wichtig:** Stand des Repos (geprüft 2026-10-29): `documents = false`, es gibt noch **keinen**
`file`-Part im Code. Der Live-Lauf ist also entweder (a) ein Wegwerf-Skript mit direktem Request
gegen die API, oder (b) erst nach dem Bau von `user_content()` für `kind = "document"` (Teil der
Task-Akzeptanz, Bauarbeit, nicht Teil dieses Live-Checks). Empfehlung: erst (a), das Ergebnis
entscheidet, ob (b) gebaut wird. Offene Frage: Soll (b) zuerst gebaut werden, damit der Test den
echten Provider-Pfad nimmt?

**Vorher:** `OPENAI_API_KEY` in der Umgebung (laut Live-Testing-Plan gesetzt, prüfen:
`:lua print(vim.env.OPENAI_API_KEY ~= nil)`, Wert **nicht** ausgeben), Neovim neu starten,
`:Ai provider openai`, `:Ai info` zeigt `openai` mit `documents: no`. Ein **kleines PDF** (1 Seite,
bekannter Text, keine Kundendaten), z. B. selbst erzeugt, Pfad: ______. Kosten: ein Aufruf mit
kleiner Seite, Cent-Bereich; ein günstiges Modell wählen, das PDF-Eingabe kann (laut OpenAI-Doku
gegenprüfen, nicht aus dem Gedächtnis).

## 1. Form des Parts gegen die Doku prüfen

- [ ] Aktuelle OpenAI-Doku zu "file inputs" in Chat Completions lesen: Form des Parts
      `{ type = "file", file = { filename = ..., file_data = "data:application/pdf;base64,..." } }`
      stimmt? Abweichung notieren: ______
- [ ] Welche Modelle akzeptieren PDF als `file`-Part? Gewähltes Modell: ______
- [ ] `filename` ist Pflicht für den Part, `Ai.Attachment.name` ist optional und wird von keinem
      Provider gesendet: Entscheidung für den Bau: `from_file`/`from_bytes` setzt immer einen Namen,
      oder der Provider erzeugt `document.pdf`. Entscheidung: ______

## 2. Echter Aufruf mit kleinem PDF

- [ ] Request mit dem PDF-Part und dem Prompt "Gib den Text dieses Dokuments wieder" an das Modell
      schicken (Wegwerf-Skript oder, nach dem Bau, `ai.ask({ provider = "openai", attachments = {
      attachments.from_file(<pdf>) } })`)
- [ ] Die Antwort enthält Text, der den PDF-Inhalt zeigt (nicht nur eine Beschreibung der
      Datei)
- [ ] Ergebnis notieren: Modell ______, Erfolg ja/nein, bei Fehler der **API-Fehlertext
      wörtlich** (ohne Schlüssel): ______
- [ ] Optional: ein PDF mit zwei Seiten und einer Tabelle, um die Qualität einzuschätzen

## 3. Ergebnis weitergeben

- [ ] Bei **Erfolg**: `documents = true`; Tabelle in `docs/attachments.md` (Zeile 66, bisher
      "documents: no") und `doc/ai.txt` anpassen; Spec in `providers_openai_spec.lua` (Body-Form
      des `file`-Parts); `docs_examples_spec` (Capability-Tabelle) muss grün bleiben
- [ ] Bei **Misserfolg** (anderes Modell, andere Form, Datei-Upload-Endpunkt nötig): `documents`
      bleibt `false`, der Grund steht in den Notizen der Task, und
      `pdfport.nvim/openai-extraction-backend` wird auf den Rasterisierungs-Weg umgestellt (die
      `blocked_by`-Kante dort lösen)
- [ ] In beiden Fällen das Ergebnis in `pdfport.nvim/openai-extraction-backend` zurückmelden

### Falls rot

HTTP 400/422 (Form falsch oder Modell nimmt kein PDF), 401 (Schlüssel), 429/Quota: Statuscode und
Fehlertext notieren, nicht in Schleife wiederholen. Schlüssel nie in Notizen schreiben.

**Danach:** Task `ai.nvim/openai-documents-live-check` mit `done` schließen, sobald das Ergebnis
dokumentiert und an pdfport zurückgemeldet ist.

---

## Befunde

-

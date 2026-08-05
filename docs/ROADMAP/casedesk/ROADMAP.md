# casedesk — Roadmap

Nur was noch offen ist. Was schon gebaut ist, steht in
[CONCEPT.md](CONCEPT.md) (Modulaufbau, Command-Tabellen, §8a–8h) und in
[MIGRATION.md](MIGRATION.md) (Bestandsumbau + Namens-Aufräumen) — Details
und Testzahlen zu jedem fertigen Feature dort, nicht hier.

---

## Offen

- [ ] Dashboard beim Start: offene Cases nach Liegezeit
- [ ] **Danach entscheiden: reicht `:Case similar`s TF-IDF, oder braucht es
      KI?** Trade-off + Messwerte: CONCEPT.md §8e. Erst im Alltag benutzen
      (v. a. beim Anlegen eines neuen Cases: hilft der Vorschlag beim
      Brainstorming der Lösung?), dann bewerten. Zwei billigere
      Stellschrauben vor einem KI-Schritt: bessere Summaries schreiben,
      `Research/` mit einbeziehen.
- [ ] Backend-Kaskade `pickers.nvim` → `snacks.picker` → `kit.select` für
      `:Cases pickers` — **zurückgestellt**: `pickers.nvim`s
      `actions/files.lua` erwartet ein internes `Source`+`engine_mod`-Objekt
      aus seiner eigenen Config-/Engine-Auflösung, keinen trivialen „Picker
      über diese Pfad-/String-Liste"-Einstieg. `:Cases pickers` läuft
      komplett auf `kit.select`.

---

## Plugin-Check — was die eigenen Plugins beisteuern könnten

Durchgegangen: alle Repos in `C:/repos/*.nvim` bzw. der Spec aus
`lua/plugins/personal/list.lua` + `source.lua`. `language.nvim`,
`emojis.nvim` sind verdrahtet (CONCEPT.md §8c); `fileops.nvim` wurde
geprüft und passt nicht (CONCEPT.md §8d/§9) — beide nicht mehr hier.

### Hoher Nutzen — dafür lohnt sich eine echte Integration

| Plugin              | Beitrag                                                                                                                                                   |
| ------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **open.nvim**       | `:Case snow` (Ticket im Browser), Doku-Links aus Replies (`docs.tricentis.com`).             |
| **pickers.nvim**    | Case-Picker statt `kit.select`, sobald die Case-Zahl weiter wächst — inkl. Preview der `.case.json`. Selbe Einschränkung wie die Backend-Kaskade oben. |
| **sessions.nvim**   | Eine Session pro Case: Case wieder aufmachen = Buffer-Layout von letzter Woche zurück. |

### Mittlerer Nutzen

**gopath.nvim** (Sprung Research ↔ Replies ↔ Ressources), **cascade.nvim**
(durch Case-Dateien zyklen), **buffer-ctx.nvim** (Case-Kontext am Buffer),
**filetree.nvim** (Case-Ordner nach `:Case new` revealen — bereits als
optionale Integration in `ui.open_dir` verdrahtet), **markdown.nvim/
mdview.nvim** (Reply-Preview), **replacer.nvim** (Platzhalter über einen
Case ersetzen), **diff.nvim** (Reply-Drafts diffen). `pdfport.nvim` nicht
mehr hier — geprüft und verworfen für Case-Export, s. CONCEPT.md §8g
(seine API liest nur bestehende PDFs, erzeugt keine).

### Geringer / kein Bezug

`insights.nvim`, `github_stats.nvim`, `reposcope.nvim`, `sandbox.nvim`,
`dap.nvim`, `debugging.nvim`, `lsp.nvim`, `documentation.nvim`,
`color_my_ascii.nvim`, `spotlight.nvim` (Ausnahme: Log-Highlighting für
Tosca-Logfiles in `Ressources/`), `cmdlog.nvim`, `recommender.nvim`
(Ausnahme: Grundlage für "ähnliche Cases", falls TF-IDF nicht reicht).

### Abhängigkeits-Politik

casedesk hängt hart **nur** an `lib.nvim`. Jede Plugin-Integration oben ist
optional über `pcall(require, ...)` mit Fallback (siehe `ui.open_dir`'s
`filetree.nvim`-Reveal mit netrw-Fallback als Muster) — sonst wäre das Modul
auf der Workstation (remote-Modus, andere Plugin-Auswahl) kaputt.

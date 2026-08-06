# casedesk — Roadmap

Nur was noch offen ist. Was schon gebaut ist, steht in
[CONCEPT.md](CONCEPT.md) (Modulaufbau, Command-Tabellen, §8a–8i) und in
[MIGRATION.md](MIGRATION.md) (Bestandsumbau + Namens-Aufräumen) — Details
und Testzahlen zu jedem fertigen Feature dort, nicht hier.

---

## Offen

- [ ] **SLA-Überwachung** — eigenes Konzept: [SLA.md](SLA.md). Priorität aus
      dem Activity Stream, `config.sla`, Geschäftszeit-Rechnung, `:Case sla`
      / `:Cases sla`, Statusline-Badge, Warnungen für P1/P2.
- [ ] **Session pro Case** — eigenes Konzept: [SESSIONS.md](SESSIONS.md).
      Case-Nummer als Session-Name, Auto-Save bei `:Case new`, `<leader>cs`
      als einziger neuer Keymap (case-aware: speichert unter der Case-Nummer
      wenn der Buffer zu einem Case gehört, sonst `sessions.nvim`s eigenes
      Auto-Resolve), `nvim -c "Session load {nr}"` bzw. eine
      PowerShell-Wrapper-Funktion fürs schnelle Öffnen, Invalidierung über
      einen neuen `:Cases doctor`-Fund-Typ (Session existiert für einen
      nicht mehr offenen Case) statt einer eigenen Prune-Mechanik.
- [ ] Dashboard beim Start: offene Cases nach Liegezeit — wird von
      `:Cases sla` (SLA.md §6B) mit abgedeckt, dort ist die Sortierung nach
      Restfrist statt nach Liegezeit die schärfere Frage
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

- [ ] Harpoon UI Menu mit wichtisgten files anpassen für die arbeit. cool wäre, wenn ich zwei unterchiedliche hätte, eines für a´wenn ich auf der worksation bin (ein funktion die das checkt gibt es schon bzw wäre es warsch egut ein env var oder nvim var z usetzen, dass nicht jedes mal beim start oder ienen unsrcmd cheled werden muss auf welche maschine ich bin)

- [ ] Heuristrik bei der Ähnlichketbewertung; zn gewichtung: gleiche wörter im title zählen ein wenig mehr; wörter ausnehmen wie artikel (der, die das..) oder füllwörter -> ziwk das nur wörter bewerrtet wwerden, die für die beschreibhungund solution des issues relevaant sind und nicht der begleittext ->uantität vorualität

- [ ] casedesk: wenn ki weingebunden wird, dann soll immer gleidch passende refrenezen aius den tricentis docs paswend zu case gfunden werden und unter einer headline Links gesammelt. es soll agenau der abschnit und wrtlaut ausdem page zitiert werden, das brauhe ich für meine internen notizen mit den voahces, da soll der link headline abschnitt hin. Außerdem: Refrenzen zu bekannten standarwerken vorschoagen, primär auf englishc, gerne abe auhdeutsch also zb wenn es uj ceritifcaes bei tosca server geht, dann halt standard fachliteratur wie zertifikate genrelel und in windows im besinderen funktienren.. auch unter enen eigenen healine abshnitt "learning referenzen"
  - [ ] die farge nach ki einbindung sollten wir uns stellen: es gibt j a zwei variaten, einmlaml nur sprachbasiertes und heuritsik, und anderer ist die ki. ich habe in meiner nvim config C:\Users\StefanBartl\AppData\Local\nvim\lua\config\ai\ und  C:/Users/StefanBartl/AppData/Local/nvim/lua/plugins/ai/ wo ich schon mit ai konfiguriert habe. dementsprechend, ich habe auf meiner workstation und pc zugang zu meinen gemini, chat gpt und claude account, claude pro lizenz. eventuell ins konzept mitdenke

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
| **sessions.nvim**   | Eine Session pro Case: Case wieder aufmachen = Buffer-Layout von letzter Woche zurück. Konzept: [SESSIONS.md](SESSIONS.md). |

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

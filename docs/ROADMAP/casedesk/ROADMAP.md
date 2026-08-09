# casedesk — Roadmap

Nur was noch offen ist. Was schon gebaut ist, steht in
[CONCEPT.md](CONCEPT.md) (Modulaufbau, Command-Tabellen, §8a–8i) und in
[MIGRATION.md](MIGRATION.md) (Bestandsumbau + Namens-Aufräumen) — Details
und Testzahlen zu jedem fertigen Feature dort, nicht hier.

---

## Offen

Sortiert nach geschätztem Aufwand, billigste/kleinste zuerst.

- [ ] **Danach entscheiden: reicht `:Case similar`s TF-IDF, oder braucht es
      KI?** Trade-off + Messwerte: CONCEPT.md §8e. Erst im Alltag benutzen
      (v. a. beim Anlegen eines neuen Cases: hilft der Vorschlag beim
      Brainstorming der Lösung?), dann bewerten. Zwei billigere
      Stellschrauben vor einem KI-Schritt: bessere Summaries schreiben,
      `Research/` mit einbeziehen.

- [ ] **Artefakt-Extraktion (Rest)** — eigenes Konzept:
      [EXTRACTION.md](EXTRACTION.md). Paket 1 steht (`:Case versions
      [component] [nr] [--all] [--raw]` aus `ToscaSupportInfo*.txt` — Digest
      statt 1600-Zeilen-Liste, Custom-DLL-Erkennung; gegen alle vier
      analysierten Support-Infos verifiziert, kein False Positive). Offen:
      Paket 2 (Stream-Signale jenseits der SLA-Uhr: Server-Version,
      Zustandshistorie, SAP Component, Fehlercodes, KBAs), Paket 3
      (`:Case doclinks` als Versionsabgleich der Tricentis-Doku-Links),
      Paket 4 (SLA-Korrektur: Uhr pausiert bei `Awaiting User Info` — hängt
      an EXTRACTION.md §11.1s offener Fachfrage), Paket 5 (Faktenblock als
      Fundament für die KI-Anbindung).

- [ ] casedesk: wenn ki weingebunden wird, dann soll immer gleidch passende refrenezen aius den tricentis docs paswend zu case gfunden werden und unter einer headline Links gesammelt. es soll agenau der abschnit und wrtlaut ausdem page zitiert werden, das brauhe ich für meine internen notizen mit den voahces, da soll der link headline abschnitt hin. Außerdem: Refrenzen zu bekannten standarwerken vorschoagen, primär auf englishc, gerne abe auhdeutsch also zb wenn es uj ceritifcaes bei tosca server geht, dann halt standard fachliteratur wie zertifikate genrelel und in windows im besinderen funktienren.. auch unter enen eigenen healine abshnitt "learning referenzen"
  - [ ] die farge nach ki einbindung sollten wir uns stellen: es gibt j a zwei variaten, einmlaml nur sprachbasiertes und heuritsik, und anderer ist die ki. ich habe in meiner nvim config C:\Users\StefanBartl\AppData\Local\nvim\lua\config\ai\ und  C:/Users/StefanBartl/AppData/Local/nvim/lua/plugins/ai/ wo ich schon mit ai konfiguriert habe. dementsprechend, ich habe auf meiner workstation und pc zugang zu meinen gemini, chat gpt und claude account, claude pro lizenz. eventuell ins konzept mitdenke
  - → **Teilantwort in [EXTRACTION.md](EXTRACTION.md) §7:** kein
    Entweder-oder. Was deterministisch parsebar ist (Versionen, Fristen,
    Priorität, Zustände), gehört als Faktenblock in den Prompt statt in die
    Verantwortung des Modells — und dient danach als Widerspruchsprüfung
    für dessen Antwort. Die im Stream **bereits zitierten** Doku-Links sind
    zudem eine Referenzsammlung ohne jeden KI-Aufruf; erst darüber hinaus
    neue Quellen zu finden, ist die eigentliche KI-Aufgabe.

- [ ] ai soll WKDBook-Tricentis/Notes als wissensspeicher verwendne, einerseits - das wkdbboolk-tricentis Notes sind meine notizen aus der onboarding phase VOR ALLEM AUS KURSEN DER TRICENTIS academy "level-up", tricentis confluesnce und tosca official  documenation - das wasa darin steht hat hohen semantischen wert, nur referenzen aus der offiziellen tosca doc und gleichwertiges steht im wert für case solkutions als Quelle darüber -

## Plugin-Check — was die eigenen Plugins beisteuern könnten

Durchgegangen: alle Repos in `C:/repos/*.nvim` bzw. der Spec aus
`lua/plugins/personal/list.lua` + `source.lua`. `language.nvim`,
`emojis.nvim` sind verdrahtet (CONCEPT.md §8c); `fileops.nvim` wurde
geprüft und passt nicht (CONCEPT.md §8d/§9) — beide nicht mehr hier.

### Hoher Nutzen — dafür lohnt sich eine echte Integration

| Plugin              | Beitrag                                                                                                                                                   |
| ------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **open.nvim**       | `:Case snow` (Ticket im Browser), Doku-Links aus Replies (`docs.tricentis.com`).             |
| **pickers.nvim**    | Case-Picker statt `kit.select`, sobald die Case-Zahl weiter wächst — inkl. Preview der `.case.json`. Verworfen: `pickers.nvim`s `actions/files.lua` erwartet ein internes `Source`+`engine_mod`-Objekt aus seiner eigenen Config-/Engine-Auflösung, keinen trivialen "Picker über diese Pfad-/String-Liste"-Einstieg — bräuchte eine neue, generische API in `pickers.nvim` selbst. `:Cases pickers` läuft komplett auf `kit.select`. |
| **sessions.nvim**   | Eine Session pro Case: Case wieder aufmachen = Buffer-Layout von letzter Woche zurück. Konzept: [SESSIONS.md](SESSIONS.md). |

### Mittlerer Nutzen

**buffer-ctx.nvim** (Case-Kontext am Buffer),
**filetree.nvim** (Case-Ordner nach `:Case new` revealen — bereits als
optionale Integration in `ui.open_dir` verdrahtet), **markdown.nvim/
mdview.nvim** (Reply-Preview), **replacer.nvim** (Platzhalter über einen
Case ersetzen), **diff.nvim** (Reply-Drafts diffen). `pdfport.nvim` nicht
mehr hier — geprüft und verworfen für Case-Export, s. CONCEPT.md §8g
(seine API liest nur bestehende PDFs, erzeugt keine).

### Abhängigkeits-Politik

casedesk hängt hart **nur** an `lib.nvim`. Jede Plugin-Integration oben ist
optional über `pcall(require, ...)` mit Fallback (siehe `ui.open_dir`'s
`filetree.nvim`-Reveal mit netrw-Fallback als Muster) — sonst wäre das Modul
auf der Workstation (remote-Modus, andere Plugin-Auswahl) kaputt.

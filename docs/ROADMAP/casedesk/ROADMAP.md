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

- [ ] **KI-Anbindung** — hängt an einem eigenen `ai.nvim`-Plugin (noch
      nicht gebaut; Config-Grundlage existiert bereits:
      `lua/config/ai/`, `lua/plugins/ai/`, Zugang zu Gemini/ChatGPT/Claude
      Pro). Sobald das steht, drei casedesk-Features darauf aufbauen:
      - **Doku-Referenzen sammeln**: zu jedem Case passende
        Tricentis-Doku-Links automatisch finden, mit Zitat des genauen
        Abschnitts/Wortlauts (für interne Notizen), unter einer Headline
        "Links" gesammelt. Teilantwort schon in
        [EXTRACTION.md](EXTRACTION.md) §7: die im Activity Stream
        bereits zitierten Links sind eine Referenzsammlung ganz ohne
        KI-Aufruf (EXTRACTION.md Paket 2/5) — erst darüber hinaus neue
        Quellen zu finden, ist die eigentliche KI-Aufgabe.
      - **Standardwerke per Websuche**: zu technischen Themen des Cases
        (z. B. Zertifikate bei Tosca Server) Referenzen zu bekannter
        Fachliteratur vorschlagen — primär Englisch, gerne auch Deutsch —
        unter einer eigenen Headline "Learning Referenzen".
        `$REPOS_DIR/Literatur` als zuerst durchssuchende Literaturliste implemeniteren, aber als user condif in der spec, also man soll das als user angebn könenn lksiten die man dursucht dafür. zusatz: weventuell kann man nauch eine literaliuste mit kurzen beschreibungen und keywords anlegen, die dann verewndet werden können, dazu bräuchte es einen parserer/buw attaher der infos zum auswerten für die ki bzw köbnbte mnan auch prüfen, ob wen man keywords verewndet auch ohne ki nur mit heuristik sinnvollerer matrchingfs schaffen lkönnte1
      - **WKDBook-Tricentis/Notes als Wissensspeicher**: die eigenen
        Onboarding-Notizen (Tricentis-Academy-Kurse "Level-Up",
        Tricentis-Confluence, offizielle Tosca-Doku) haben hohen
        semantischen Wert — nur Referenzen aus der offiziellen Tosca-Doku
        und Gleichwertigem zählen als Quelle für Case-Lösungen.

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

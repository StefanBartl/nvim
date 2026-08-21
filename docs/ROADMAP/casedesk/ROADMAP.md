# casedesk — Roadmap

## Praxis-Feedback

- Nach anlegen des cases und aufrufen der ai in casedesk, soll diese nicht nur vorschläge / solutions formulieren, sondern diese acuh mit Referenzen zu echten docs / tricentis docs belegen. https://docs.tricentis.com/tosca-2026.1/en-us/content/resources/webhelp/cover_web.htm (korrekte Version wählen für case!)
- Es solte eine option geben, Case ki logs oder so ähnlich, mitdenn man die logdatein im assets ordner auswhlen kann (selectionlist mit tab oder pickers.nvim) und dan wird eine analyse der logdateien erstellt in /Research abgelegt

- KB-Artikel: Als Standard such tool verwenden wir `https://tricentis.atlassian.net/issues?wildcardFlag=true&filter=40563` - das ist eineJira jql search; Es wäre natürkcih super, wenn beim case new auch zumindest eine liste mit passenden jql such strings mit ausgegeben wird für research, idealrweiße würde aber dieses auch mit ai automatisch durcucht werden können

## Offen

Sortiert nach geschätztem Aufwand, billigste/kleinste zuerst.

- [ ] **KI-Checklisten im Copy-Paste-Roundtrip** — zwei zusätzliche
      Abschnitte in `templates/KiPrompt.md`s Antwortformat ("Was haben wir
      dem Kunden vorgeschlagen?" / "Was hat er zurückgemeldet, und wie?"),
      plus die passende Ablage in `:Case ki import` (`ki.lua`s `DIGIT_KEY`
      um zwei Einträge erweitern, Ablageort vermutlich `Notes.md` — analog
      zum bestehenden "Internal Notes"-Abschnitt). Anders als die
      KI-Anbindung unten hängt das an NICHTS Neuem: der bestehende
      Copy-Paste-KI-Workflow (`:Case ki` / `:Case ki import`) trägt das
      schon, kein `ai.nvim` nötig. Zurückgestellt, weil im Wunschzettel
      selbst nur ein vages "wäre nice", kein ausgearbeitetes Format — erst
      konkretisieren (welche Headline, welcher Ablageort, wie oft
      aktualisiert über die Laufzeit eines Cases) bevor implementiert wird.

- [ ] **Danach entscheiden: reicht `:Case similar`s TF-IDF, oder braucht es
      KI?** Trade-off + Messwerte: CONCEPT.md §8e. Erst im Alltag benutzen
      (v. a. beim Anlegen eines neuen Cases: hilft der Vorschlag beim
      Brainstorming der Lösung?), dann bewerten. Zwei billigere
      Stellschrauben vor einem KI-Schritt: bessere Summaries schreiben,
      `Research/` mit einbeziehen.

- [ ] **Zweite Activity-Stream-Quelle: SAP Resolve (Rest)** — Konzept +
      Paket 6a stehen: [EXTRACTION.md §13](EXTRACTION.md#13-zweite-quelle-sap-resolve-analyse-noch-nicht-gebaut).
      `sla/stream.lua` erkennt SAP Resolves Tampermonkey-Export jetzt
      selbst (`stream_format.lua`) und leitet `customer`/`states` daraus
      ab — `:Case activity`/`:Case sla` funktionieren für diese Quelle
      bereits, ohne jede Änderung an `sla/init.lua`. Offen: Paket 6b
      (`extract/stream.lua` — Anhänge, `last_reply_sent_at`; `M.kbas`/
      `M.doc_links` brauchen nichts, funktionieren schon) und Paket 6c
      (Priorität/SNOW-Nummer fehlen im Export komplett — Tampermonkey-
      Script erweitern oder `:Case activity` fragt aktiv nach).

- [ ] **KI-Anbindung** — hängt an einem eigenen `ai.nvim`-Plugin (noch
      nicht gebaut; Config-Grundlage existiert bereits:
      `lua/config/ai/`, `lua/plugins/ai/`, Zugang zu Gemini/ChatGPT/Claude
      Pro). Artefakt-Extraktion ist als Fundament dafür bereits komplett
      fertig (alle 5 Pakete, s. [EXTRACTION.md](EXTRACTION.md)) —
      `:Case ki`s Prompt bekommt schon einen `{facts}`-Faktenblock
      (Priorität, SAP Component, Versionen, SLA-Status, Doku-Link-
      Versionsabgleich) und `:Case ki import` prüft Antworten schon gegen
      diese Fakten. Sobald `ai.nvim` steht, weitere Features darauf
      aufbauen:
      - **Doku-Referenzen sammeln**: zu jedem Case passende
        Tricentis-Doku-Links automatisch finden, mit Zitat des genauen
        Abschnitts/Wortlauts (für interne Notizen), unter einer Headline
        "Links" gesammelt. Der Faktenblock aggregiert bereits die im Case
        zitierten Links nach Version (`extract/doclinks.lua`s
        `all_links`) — was noch fehlt, ist die Zitat-mit-Kontext-Sammlung
        pro einzelnem Link, ein eigenständig größeres Stück (Textauszüge
        um jeden Fund extrahieren). Erst darüber hinaus neue Quellen zu
        finden, ist die eigentliche KI-Aufgabe.
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

## Erledigt

Chronologisch, neueste zuerst. Details und Erkenntnisse: [HANDOVER.md](HANDOVER.md).

- [x] **`:Case insert` kann Assets** (2026-08-19) — zwei neue Felder in
      `ui.INSERT_FIELDS`: `asset` (Markdown-Link relativ zum Puffer, in dem
      geschrieben wird) und `asset-path` (absoluter Pfad für Teams/Explorer/
      Shell). Beide öffnen einen zweiten Picker über `assets/` — dieselbe
      Dateiliste wie `:Case attachments`. Außerhalb des Case-Ordners fällt
      `asset` auf den absoluten Pfad zurück.

- [x] **CLI-Befehls-Index** (2026-08-19) — `:Tricentis commands [topic]`
      und `:Tricentis cheatsheet [topic]`: jeder Shell-Codeblock aus jeder
      `.md` des Arbeits-Repos als durchsuchbarer Index bzw. als gruppierter
      Puffer. Neu: `commands.lua`; dazu `config.command_topics`,
      `ui.commands`/`ui.cheatsheet`, zwei Routen in `init.lua`.
      Dokumentiert in `docs/NOTES/casedesk/Usercmds.md` und
      `case/docs/FEATURES.md`.
- [x] **`:Tricentis links` lesbar gemacht** (2026-08-19) — `links.dedupe`
      (810 → 600 Zeilen, `×N` statt Wiederholungen), Anzeige-URL ohne
      Schema/Query, Mittel-Kürzung statt Rechts-Kürzung, Filter für
      Platzhalter-URLs aus Fließtext. Dabei gefunden: `strdisplaywidth`
      rechnet `'showbreak'` mit und taugt nicht zur Spaltenausrichtung —
      `strwidth` verwenden.

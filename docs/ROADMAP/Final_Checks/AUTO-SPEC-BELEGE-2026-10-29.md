# Spec-Belege für Live-Check-Kästchen (2026-10-29)

Claude hat am 2026-10-29 alle Dateien in `Final_Checks/` durchgesehen. Wo eine bestehende Spec
genau das Verhalten eines offenen Kästchens prüft, wurde die Spec auf STEVESPC (privat)
ausgeführt und das Kästchen bei grünem Lauf abgehakt. Solche Kästchen tragen am Zeilenende den Vermerk
`_(auto 2026-10-29: <repo>/TESTS/<spec> grün)_` und sind so von Handprüfungen zu unterscheiden.

Regeln dabei:

- Ein Kästchen wurde nur abgehakt, wenn eine Spec das Verhalten des Kästchens prüft, also nicht nur einen passenden Dateinamen hat.
- Nie abgehakt: Optik, Gefühl, Latenz-Urteil, echte Tasten-Modifier, echte Accounts/Keys/Netz, andere Rechner und Entscheidungen.
- „Danach: Task schließen“ wurde ebenfalls nie abgehakt.
- Teilweise belegte Kästchen bleiben offen. Sie tragen den Vermerk `… grün, nur teilweise: <was fehlt>`.
- Ausgelassen: testing.nvim und tasks-web (andere Session).
- Rote Specs: **keine**. Alle gelaufenen Specs (über 100 Dateien) waren grün.

## Abgehakt pro Datei

| Datei | abgehakt |
|---|---|
| Checks-Blocker_0610.md | 204 |
| BINDINGS-RUNTIME-CHECKLIST.md | 140 (85 + 55 nach den Nachtrag-Specs, siehe unten) |
| terminal.nvim.md | 17 |
| PLUGIN_ROADMAPS_TESTPLAN.md | 18 |
| gitsuite-live-checks-2026-10-22.md | 15 |
| bild-viewport-zen-live-tests-2026-10-20.md | 6 |
| lsp.nvim-live-checks-2026-10-29.md | 5 |
| markdown.nvim-live-checks-2026-10-29.md | 3 |
| casedesk-live-checks-2026-10-29.md | 2 |
| image-redact-live-tests-2026-10-21.md | 2 |
| wkd-live-tests-2026-09-29.md | 2 |
| mdview.nvim-live-checks-2026-10-29.md | 1 |
| Running-Tasks_Checklist.md | 1 |
| ui.nvim.md | 1 |
| **Summe** | **362** |

Keine Spec-Belege: language, nvim-config, tasks-apps, ai/openai-documents, ai/live-testing-plan,
media/live-testing-plan, docmap, docmap-desktop, github_stats, filetree, filetree-trash-batch, gopath,
hover, images-tmux. Dort geht es um echte Programme, Accounts, Optik, andere Systeme, oder die
Specs decken das Kästchen nur teilweise.

## Befunde

- **Spec-Lücke Keymaps:** spotlight, ui.nvim, casedesk, sessions und cmdlog prüfen bei Keymaps nur,
  ob sie registriert sind, und lösen sie nie aus. Mit feedkeys-Specs wären viele Bindings-Kästchen
  belegbar.
- **Wiring-Lücken:** ai.nvim Completion-Tasten (`<Tab>`, `<C-]>`) und lsp.nvim `:Lsp restart`/`:Lsp stop`
  sind nur als Funktionen getestet, nicht als Taste bzw. Befehl. Eine kleine Wiring-Spec würde reichen.
- **Bug (bekannt, in Spec dokumentiert):** `:Cascade cycle remove` schneidet einen Wert mit Leerzeichen
  nach dem ersten Wort ab (BUG-Kommentar in `cascade.nvim/TESTS/usrcmds_spec.lua`).
- **casedesk `--sep=pipe`:** im Code (`lua/casedesk/clipboard.lua`), aber ohne Spec. Eine Zeile in
  `clipboard_spec` würde das Kästchen in `casedesk-live-checks` belegen.
- **Veraltete Kästchentexte:**
  - Checks-Blocker K8/K12: Die Checkliste landet laut Spec in `Notes.md`, nicht mehr in
    `Research/00_Research.md`.
  - Checks-Blocker G4: `trans` bekommt den Text laut `translate_providers_spec` per stdin. Die Task
    `translate-shell-text-via-stdin` ist vermutlich erledigt.
- **markdown.nvim:** Die Raster-Zeilen hängen am Puffer, nicht am Fenster. Ob zwei Fenster mit
  unterschiedlicher Breite je ein passendes Raster bekommen, ist ungeprüft und lohnt die Handprüfung.
- **image-redact `u`/`2u`:** abgehakt (redact_spec grün im echten Redact-Fenster); die alte Handnotiz
  „funktioniert nicht“ stammt aus dem Fenster vor dem Umbau auf Zen (21.10.). Am 2026-10-30 mit
  der echten Config geprüft: `u`/`w` gehören im Redact-Fenster Redact, `gs`/`gy`/`<BS>` sind dort ungebunden.
- **docmap Junction-Traceback:** `docmap.nvim/TESTS/out_dir_links_spec.lua` zeigt die saubere
  Verweigerung über `cli.run`. Mit dem gebauten Binary ist das noch nicht geprüft, das Kästchen ist offen.

## Nachtrag: Specs, die Tasten wirklich drücken (2026-10-29)

Die Lücke "Specs prüfen nur die Registrierung" wurde in einer zweiten Runde geschlossen. Die neuen
Specs lösen jede Taste per `nvim_feedkeys(..., "mx")` aus und prüfen die Wirkung; jede wurde
sabotage-verifiziert (Mapping kaputt oder vertauscht, Spec wird rot):

| Repo | Commit | Abgedeckt |
|---|---|---|
| spotlight.nvim | `70846b0`, `20da506` | alle 8 Keymaps |
| ui.nvim | `2e01e56`, `6a739fd` | Tabs, Buffer schließen/pinnen/sortieren, Theme, Sticky |
| casedesk.nvim | `98c1db8`, `6ea6f72` | `cf`/`cF`/`cg`/`cG`/`cm` bis zur Picker-Grenze, `--sep=pipe` |
| sessions.nvim | `fbde5e6` | alle `<leader>h*` |
| cmdlog.nvim | `840d8a6` | jeder `:Cmdlog`-Unterbefehl getippt, Katalog-Tasten |
| ai.nvim | `b50f894` | `<Tab>`/`<C-]>`; **fand einen echten Bug** (accept unter textlock, E565) |
| lsp.nvim | `4930484`, `5c6a455`, `f277bdf` | `:Lsp stop`/`restart` gehen an den Supervisor; K12-Waiver |
| cascade.nvim | `22cad85` | **Fix** `:Cascade cycle remove` mit Leerzeichen-Wert |
| nvim | `e29f968a6`, `e5813f7a4` | `:BindingsRuntimeChecklistDrift` (tote/neue Einträge, zählt Doppelte) |

**Bewusst offen geblieben** (Spec deckt die Aussage des Kästchens nicht): `<leader>bq` (Flash),
`<C-\><C-a>` (Trigger), `:Lsp stop`/`restart` (echter Neustart gegen Stub-Supervisor, `stop` ohne Namen).

## Offene Produkt-Befunde aus dem Review (als Tasks im Vault)

- `spotlight.nvim/back-jump-mid-line`: `[k` mitten in der Zeile überspringt das Vorkommen links vom
  Cursor (`z`-Flag der Rückwärtssuche).
- `ai.nvim/completion-tab-fallback-snippet-und-fremde-imap`: der `<Tab>`-Fallback ersetzt Neovims
  Snippet-Sprung und fremde `imap <Tab>`.
- `ai.nvim/completion-accept-dot-repeat`: Dot-Repeat lässt den angenommenen Text weg.
- `cascade.nvim/cycle-remove-first-vs-last-gruppe`: Doku sagt "first group", Code entfernt die letzte.

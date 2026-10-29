# lsp.nvim — Live-Checks (Stand 2026-10-29)

Zwei Tasks von lsp.nvim, die nur in einem echten Terminal mit echtem Neovim 0.12 prüfbar sind.
Ist ein Abschnitt durch, die Task mit `done` schließen (oder Bescheid geben). Ein Befund: unter
"Befunde" eine Zeile, daraus wird eine `kind: bug`-Task.

**Vorher:** lsp.nvim aktuell (`:Lazy update lsp.nvim`, mindestens Stand `d344a60`), Neovim **0.12**
(`:version`), Neovim neu starten, `:checkhealth lsp` ohne Fehler.

---

## 1. Lspsaga-Ersatz: A1 bis A11 im echten Fenster — offen

Task `lsp.nvim/live-check-lspsaga-replacements`. Die elf Prüfungen mit Testdatei, Schritten und
erwartetem Ergebnis stehen **bereits vollständig** in
[`lspsaga-vs-lsp.nvim-Feature-Gap.md`](lspsaga-vs-lsp.nvim-Feature-Gap.md), Abschnitt "Abschluss:
deine Prüfungen im echten Terminal" (Tabelle A1 bis A11, ca. 20 min). Dort durcharbeiten; hier nur
die Reihenfolge und der Abschluss.

- [ ] A1 `lsa` im echten fzf-Fenster (Diff-Vorschau, keine fzf-lua-Warnung, gewählte Aktion wird
      angewendet)
- [ ] A2 `gra` im Visual-Mode listet Aktionen passend zur Selektion (z. B. "Extract function")
- [ ] A3 `l` im Visual-Mode wartet nicht auf `timeoutlen`
- [ ] A4 gitsigns-Hunk-Aktionen in `lsa` (auch auf einer gelöschten Zeile am Dateianfang/-ende)
- [ ] A5 Peek: übernommener Buffer ist gelistet (`<C-o>`/`<C-v>`/`<C-x>`/`<C-t>`, dann `:ls`)
- [ ] A6 Implementations-Marker (`1 impl`) aktualisiert sich, keine Marker auf der falschen Zeile
      beim Tippen im Insert-Mode
- [ ] A7 Winbar-Trenner `›` sauber zwischen den Chips (kein Zeichensalat)
- [ ] A8 Type Hierarchy: Go (`lsh`/`lsH`, Picker mit Sub-/Supertypen) und TS (Klartext-Meldung,
      die die möglichen Server nennt)
- [ ] A9 `gra` über zwei Hunks stagt beide; Cursor in einem mehrzeiligen Hunk stagt den ganzen Hunk
- [ ] A10 `:LspRestartHere` / `:LspStopHere` auf `.txt` und Lua-Datei im Repo; keine Winbar auf
      `.txt`; N/N zählt nur echte Server
- [ ] A11 `lsc` in einer Lua-Datei dieser Config (documentation.nvim mit
      `opts.callhierarchy = true`): "scanning"-Meldung einmal, dann das fzf-lua-Fenster

### Falls rot

- Fällt A1 oder A2 durch: Fallback `code_actions.picker = "native"` in `init.lua`, Befund melden.
- Jeder durchgefallene Punkt wird eine `kind: bug`-Task mit `refs:` auf die A-Nummer.

### Danach

- [ ] Stand-Spalte in `lspsaga-vs-lsp.nvim-Feature-Gap.md` bzw. den Report auf das beschneiden,
      was noch offen ist (Akzeptanz der Task)
- [ ] Task `lsp.nvim/live-check-lspsaga-replacements` mit `done` schließen

---

## 2. `gx` auf einem Env-Link in einer echten Neovim-0.12-Sitzung — offen

Task `lsp.nvim/gx-on-an-env-link-in-a-real-neovim-0-12-session-hand-check`. Code:
`lsp.nvim@d344a60` (`core/env_links_server.lua`, mit Specs abgedeckt). Hintergrund:
`lsp.nvim/docs/configuration.md`, Abschnitt `languages.env_links`. Der letzte Schritt, dass `gx`
das Ziel in einer echten Terminal-Sitzung wirklich öffnet, wurde nie gesehen.

**Wie es funktioniert:** der In-Process-Client von lsp.nvim beantwortet
`textDocument/documentLink`, das `gx` in Neovim 0.12 bei den angehängten Clients erfragt. Pro
Env-Link (`$VAR/...`, `${VAR}/...`, `~/...`), dessen Ziel als Datei oder Ordner **existiert**, gibt
es einen Eintrag. Ohne Eintrag fällt `gx` auf `<cfile>` zurück.

**Testdatei** (neue, leere `.md`, z. B. im Scratch-Ordner; die Pfade müssen zu existierenden Dateien
auf deiner Maschine passen, `$REPOS_DIR` ist gesetzt):

```markdown
[Datei mit Variable]($REPOS_DIR/tasks-vault/HEREDOC.md)

[Datei mit Klammern](${REPOS_DIR}/tasks-vault/HEREDOC.md)

[Ordner]($REPOS_DIR/tasks-vault)

[Datei mit Anker]($REPOS_DIR/tasks-vault/HEREDOC.md#irgendwas)

[Fehlende Datei]($REPOS_DIR/tasks-vault/gibt-es-nicht.md)

[Undefinierte Variable]($GIBT_ES_NICHT_X/foo.md)

`[im Code]($REPOS_DIR/tasks-vault/HEREDOC.md)`
```

### Vorbereitung

- [ ] `:version` zeigt Neovim 0.12
- [ ] Datei öffnen, `:lua =vim.tbl_map(function(c) return c.name end, vim.lsp.get_clients({bufnr=0}))`
      listet neben marksman den In-Process-Client von lsp.nvim (Name steht im Ergebnis; falls
      keiner angehängt: Befund, `languages.env_links` prüfen, steht auf `true` als Default)

### Schritte

- [ ] `gx` auf dem ersten Link (Cursor auf der Zieladresse): die Datei öffnet sich (im Programm,
      das dein System für `.md` nutzt bzw. wie `vim.ui.open` es tut)
- [ ] `gx` auf dem Link mit `${REPOS_DIR}`: dasselbe
- [ ] `gx` auf dem Ordner-Link: der Ordner öffnet sich (Explorer)
- [ ] `gx` auf dem Link mit `#anker`: die Datei öffnet sich **am Anfang** (Anker gehört nicht zur
      URI, laut Doku; `gd` ist der Weg zur Überschrift)
- [ ] `gx` auf dem Link zur fehlenden Datei: **kein** Öffnen über den Client (kein Eintrag),
      `gx` fällt auf `<cfile>` zurück; Verhalten notieren (Fehlermeldung oder nichts)
- [ ] `gx` auf der undefinierten Variable: kein Eintrag, kein Fehler vom Client
- [ ] `gx` auf dem Link im Code-Span: kein Eintrag vom Client
- [ ] Mit `languages.env_links = false` (Neovim neu starten): `gx` auf dem ersten Link öffnet nicht
      mehr das Ziel (Gegenprobe), danach wieder auf `true`

### Falls rot

- `gx` tut auf dem ersten Link nichts oder öffnet etwas Falsches: notieren, was geöffnet wurde (oder
  die Fehlermeldung), `:lua =vim.lsp.get_clients({bufnr=0})[1].server_capabilities.documentLinkProvider`
  für den Client, Neovim-Version. Verdacht, wenn der Client nicht angehängt ist oder das Ziel mit
  Windows-Pfaden (`E:/repos/...`) nicht passt.
- Befund als `kind: bug`-Task festhalten.

### Danach

- [ ] Task `lsp.nvim/gx-on-an-env-link-in-a-real-neovim-0-12-session-hand-check` mit `done`
      schließen (oder Ergebnis in die Notizen)

### Offene Fragen

- Die Task hat keinen Inhalt außer dem Titel und einem Satz (Abschnitte Kontext/Akzeptanz/Notizen
  sind leer); Schritte stammen aus `docs/configuration.md`. Die Testdatei-Ziele
  (`tasks-vault/HEREDOC.md`) sind eine Annahme, dass sie existieren.
- Welches Programm soll `gx` für `.md` öffnen? Die Erwartung "öffnet die Datei" gilt hier für das
  System-Standardprogramm.

---

## Befunde

<!-- eine Zeile pro Befund: Abschnitt, was passiert ist, was erwartet war -->

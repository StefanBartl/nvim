Das Handover liegt im Vault, der Symlink in `docs/ROADMAP/handovers` ist angelegt und committet.

- **Original:** `tasks-vault/lib.nvim/handovers/session-stand-2026-10-15_HANDOVER.md` (Vault-Commit `069b8dc`)
- **Symlink:** `$NVIM_CONFIG_DIR/docs/ROADMAP/handovers/session-stand-2026-10-15_HANDOVER.md` zeigt auf das Original und ist als Link eingecheckt (nvim-config `96a2ec97`). Dort liegen weiter fremde uncommittete Änderungen, die ich nicht angefasst habe.

**Was noch offen ist** (Details und Task-IDs stehen im Handover):

**Ohne Rückfrage angehbar**
- **lib.nvim:** `hooks-pattern` (nächste laut `next`), `portable-path`, ein neuer XS-Bug (`fs.write.atomic` und Symlink als Ziel), `table-format-partial-crlf-block`, die Windows-Flakes (`run_argv_spec`, `git_run_spec`), `spawn_command` ruft `on_exit` vor `handle:close()`, `review-reste-der-contract-fs-json-module…`, `keymaps = false` mit gemeinsamer Normalisierung. Dazu viele Bausteine ohne Prio (`list lib.nvim --status=open`).
- **gitsuite.nvim `plugins-breaking-classifier`:** Die Rohdaten des Korpus müssen neu gezogen werden.
- **docmap-desktop `wkdbooks-project-fails`:** Braucht die Desktop-App zum Reproduzieren.
- **language.nvim:** Hauptthread-Yielding, `segment/mask` blockiert die Hauptschleife, `translate-shell-text-via-stdin` (braucht ein echtes `trans`), `path-scope`, `rate-limit`.
- **lsp.nvim `conformance-findings`**, **testing.nvim** `security-model-d8-controls`, `m1-fleet-parity`, `m1-runner`, **ALL** `interactive-confirm-sweep` (L).
- **Kleinere Tasks:** ai.nvim (zwei Completion-Bugs, `openai-base-url`), pdfport `rasterize-timeout`, filetree `sibling-navigation`, github_stats `fetch-spawn-throttle`, markdown.nvim `hover-config-passthrough`, mdview `linkhover-…` (neu).

**Braucht dich**
- `hover.nvim` Mausrad-Zoom (actor=pair, du bestätigst die Tasten).
- `docmap-desktop/rules-api-catalog-and-run` (erst klären, ob es mit der laufenden rules.nvim-Arbeit kollidiert).
- `documentation.nvim/repo-named-paths-outside-root` (Sicherheitsentscheidung).
- `lib.nvim` help-float-Entscheidung.
- `testing.nvim/cache-affected-remaining-limits` (zwei Entscheidungen: Lese-Ledger, State-Warn bei `soft`).
- **Handchecks:** `gx` auf einen Env-Link in einem echten Neovim 0.12 und `live-check-lspsaga-replacements`.

**Bewusst nicht gemacht** (im Handover mit Begründung)
- filetree: Symlink und Ziel bleiben zwei Kandidaten.
- pdfport: Ghostscript fragt nur den PATH.
- language.nvim: Adressen mit Nicht-ASCII-Zeichen werden nur bis zum ersten solchen Zeichen verglichen.
- Fremde `check`-Befunde im Vault (u. a. `event-stream-and-cooldown` liegt als `done` noch in `ROADMAP/tasks/`).

**Bekannte Umgebungsprobleme:** Im lib.nvim-Worktree scheitern `telemetry_wrap_spec` und `git_spec` an Pfad bzw. Branchname, im Haupt-Checkout ist die Suite grün. `run_all_tests.sh` über alle Repos dauert über 20 Minuten.

Die Arbeitsregeln für den nächsten Chat stehen ebenfalls im Handover (u. a. nie Prozesse per Namen beenden, Backslashes nie durch Heredocs, nur eigene Dateien im ai.nvim-Checkout committen).

**Commits dieses Chats seit dem letzten Stand**
- `069b8dc` (tasks-vault): Handover-Datei. ✅ (reine Doku)
- `96a2ec97` (nvim-config): Symlink auf das Handover. ✅ (reine Doku)

Alle früheren Code-Commits des Chats haben ihren Haken durch das Review mit hohem Reasoning, keiner einen Stern.

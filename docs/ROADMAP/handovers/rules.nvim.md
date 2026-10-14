Das Handover ist aktualisiert und gepusht. Das Original liegt im Vault (`3df0a5f`), der Symlink steht in `$NVIM_CONFIG_DIR/docs/ROADMAP/handovers/`. Die Symlinks sind im nvim-config-Repo noch untracked, wie die älteren Handover-Links dort auch.

Datei: `rules-authoring-stand-2026-10-14_HANDOVER.md`

## Zum Reinkopieren in den nächsten Chat

> **Weiter mit rules.nvim Rules-Authoring.** Lies zuerst `$NVIM_CONFIG_DIR/docs/ROADMAP/handovers/rules-authoring-stand-2026-10-14_HANDOVER.md` (Original: `tasks-vault/rules.nvim/handovers/`).
>
> **Stand:**
> - Die lib-Extraktion aus tasks.nvim ist fertig (`lib.nvim`: `json.canonical`, `contract.{errors,doc,api,ops,host}`, `fs.*`, Host-Template).
> - rules.nvim liest jetzt eine Regel pro Datei neben dem alten Format. Dazu gibt es Layouts, einen Katalog-Generator (`:Rules catalog [--check]`, `scripts/ruleset.lua catalog|migrate`) und einen Byte-genauen Konverter.
> - Alle bisherigen Commits sind per ultracode reviewt (66 Funde behoben, danach ein Regressions-Review).
> - Suiten: rules.nvim 334 Specs grün, lib.nvim grün bis auf zwei bekannte Windows-Fehler.
>
> **Offen:**
> 1. **Meine Entscheidung steht aus:** `migrate --write` auf die echten Regelwerke `wkdbook-Lua` und `wkdbook-native`? Das sind 571 Dateien, die sofort nach `main` gehen, nur auf sauberem WKDBooks-Stand. Danach schließt der Task `rules.nvim/loader-katalog-migration` (Status `doing`) mit `done`.
> 2. **Die 598 Migrationsnotizen:** in den Layouts lassen oder in den Vault verschieben?
> 3. **Neuer Task:** `lib.nvim/restluecken-der-review-fixes-contract-api-echo-tasks-nvim-ko` (`contract.api`-Echo, Kopien in tasks.nvim, Runtimepath-Escape).
> 4. **Alter Task:** `lib.nvim/review-reste-der-contract-fs-json-module-entscheidungen-und`.
> 5. **Danach im Plan `rules.nvim/rules-authoring`:** `engine-rules-export`, `engine-rules-ops`, `engine-waiver-ops`, `nvim-befehle-new-set-retire`, dann `rules-desktop/*`. Die Entscheidung `rules-desktop/appkit-extraktion-entscheiden` schaltet zwei weitere Tasks frei.
>
> **Übersicht:** `nvim --headless -u NONE -l $REPOS_DIR/tasks.nvim/scripts/tasks.lua plan --plan=rules.nvim/rules-authoring --vault=$REPOS_DIR/tasks-vault`
>
> **Hinweis:** Auf diesem Windows-Host geht `scripts/test.sh` nicht. Die Befehle für die Specs stehen im Handover. Maximal 1 Agent gleichzeitig.

Die vollständige Commit-Liste des Chats (Repo, Inhalt, Review-Haken) steht im Handover.

| Repo | Commit | Inhalt | Review |
| --- | --- | --- | --- |
| tasks-vault | `3df0a5f` | Handover Stand 2026-10-14 | ✅ |

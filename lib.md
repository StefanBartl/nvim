Es gibt dazu noch keine Tasks. Ich lege sie an: vier für offene Restarbeit und eine für den CI-Race.

Jetzt der Nachtrag im Handover, mit den Task-IDs statt Fließtext.

Vor dem Commit läuft der Vault-`check`. Dann committe und pushe ich auf `main`.

Der `check` meldet 28 Befunde, darunter 9 Fehler. Ich prüfe, ob einer davon bei meinen neuen Tasks liegt.

Meine neuen Dateien sind sauber, die übrigen Befunde gehören zu fremden Tasks. `debugging.nvim/health-recent-popup-requirements` hängt aber an `messages-status` und könnte meine neue debugging-Task duplizieren — das prüfe ich jetzt.

Das ist genau die Task, die auf `messages.status()` gewartet hat. Meine neue Task ist ein Duplikat. Ich entferne sie, entsperre die bestehende und nenne den Hinweis im Handover.

Jetzt passe ich das Handover an: Die gestrichene Task fliegt raus, der Hinweis auf die bestehende kommt rein.

Das Handover ist aktualisiert und als `c27630c` auf `main` im `tasks-vault`. Ich habe die bestehende Datei [session-stand-2026-10-15_HANDOVER.md](E:/repos/tasks-vault/lib.nvim/handovers/session-stand-2026-10-15_HANDOVER.md) um einen Abschnitt "Nachtrag 2026-10-16" ergänzt, statt eine neue anzulegen. Er enthält:
- die gelieferten und gereviewten Bausteine,
- die Review-Fixes mit Commit-IDs,
- die Co-Author-Abweichung bei `97ce134` und `3dbfd62`,
- die Task-IDs für die offene Restarbeit,
- die Stolperfallen dieser Runde.

Die offene Restarbeit steht als Tasks, nicht als Fließtext. Neu angelegt habe ich vier:
- `lib.nvim/scoring-name-delta-pruefung-nur-an-einer-stelle`
- `lib.nvim/window-matches-split-kopierte-matches-im-ledger-behandeln`
- `lib.nvim/ci-verified-publish-race-bei-zwei-schnell-aufeinanderfolgend`
- `documentation.nvim/lang-registry-auf-lib-nvim-registry-umstellen`

Die fünfte Task, den `messages.status()`-Verbraucher in debugging.nvim, gab es schon als `debugging.nvim/health-recent-popup-requirements`. Sie wartete auf `messages-status`, das längst fertig ist. Ich habe meine Dublette gelöscht und den Blocker bei der bestehenden Task entfernt, sie ist jetzt `open`.

`check` ist für meine Dateien sauber. Die übrigen Befunde im Vault sind fremd und von mir nicht angefasst. Dazu gehören zwei `duplicate-id` bei `lib.nvim/best-target-window` und `lib.nvim/buffer-jump-fallback-chain`, also fertige Tasks, die noch in `ROADMAP/tasks/` liegen.

Commits dieses Chats:

| Commit | Repo | Beschreibung | Review |
|---|---|---|---|
| a9986c1 | lib.nvim | `lib.lua.scoring` | ✅ (Review "high") |
| 3c9b7de | lib.nvim | `window.matches` | ✅ (Review "high") |
| 68378c1 | lib.nvim | `messages.status()` | ✅ (Review "high") |
| 4569147 | lib.nvim | `keymap.cheatsheet` | ✅ (Review "high") |
| b7e1498 | lib.nvim | `lib.nvim.registry` und composer-Umstellung | ✅ (Review "high") |
| 4bf4aa7 | lib.nvim | Review-Fixes für die fünf Commits oben | ✅ (Review "high") |
| 97ce134 | lib.nvim | Fixes aus dem Review von `4bf4aa7` | ✅ (Review "high") |
| 3dbfd62 | lib.nvim | stylua-Formatierung der Specs aus `97ce134` | ✅ (Review "high") |
| 36bed5d | lib.nvim | Fixes aus dem Review von `97ce134` (Retry-Toleranz, Doku, Test) | Fix-Commit, nicht erneut reviewt |
| 217c624, 177bbc0 | tasks-vault | Tasks auf done | ✅ (reine Doku) |
| c27630c | tasks-vault | Handover-Nachtrag, vier neue Tasks, `health-recent-popup-requirements` entsperrt | ✅ (reine Doku) |

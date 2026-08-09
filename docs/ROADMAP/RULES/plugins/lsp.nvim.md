# lsp.nvim

## Zweck
Nicht feststellbar — das Repository ist praktisch leer. `E:\repos\lsp.nvim` enthält außerhalb von
`.git` und `.claude` nur eine leere `README.md` (0 Byte, verifiziert per Read). Es gibt keinen
`lua/`-Ordner, keine Plugin-Quelldateien, keine `docs/`. Ein Worktree unter
`E:\repos\lsp.nvim\.claude\worktrees\lsp-nvim-plugin-concept-0bfd66\` enthält ebenfalls nur eine
leere `README.md`. Der Git-Log zeigt einen einzigen Commit (`8d05306 init`) auf `main` sowie einen
Branch `claude/lsp-nvim-plugin-concept-0bfd66`, dessen Name ("plugin-concept") darauf hindeutet,
dass hier lediglich eine Konzept-/Ideenphase begonnen, aber nie mit Inhalt gefüllt wurde.

## Nicht-standard Patterns / Algorithmen
Keine besonderen Patterns gefunden — es gibt keinen Code zu analysieren.

## Abgeleitete Guidelines
Keine ableitbar — kein Quellcode vorhanden. Einzige Beobachtung: der Name und die vom Nutzer
vorgegebene Einordnung ("nicht in der aktiven Plugin-Liste, evtl. superseded/experimentell")
passen zum Befund — dies ist ein reines Namens-/Konzept-Reservat ohne Implementierung, kein
funktionsfähiges oder auch nur begonnenes Plugin.

## Keybindings-Audit
Keine eigenen Keymaps — es existiert kein Code.

## Ideen für andere Plugins
Keine ableitbar aus diesem Repo. Falls der Nutzer die ursprüngliche Absicht hinter `lsp.nvim`
wiederaufnehmen möchte, lohnt sich ein Blick auf den Branch `claude/lsp-nvim-plugin-concept-
0bfd66` bzw. dessen Commit-Historie (lokal unter `E:\repos\lsp.nvim\.git`) — falls dort in einer
früheren Session Konzept-Notizen andiskutiert wurden, die nicht in die Working-Tree-Dateien
übernommen wurden. Aus dem aktuellen Zustand allein lässt sich aber nicht rekonstruieren, was
das Plugin leisten sollte (LSP-Erweiterung? LSP-Client-Wrapper? Diagnostics-UI?) — dafür wäre eine
Rücksprache mit dem Nutzer nötig, bevor hier irgendetwas implementiert wird.

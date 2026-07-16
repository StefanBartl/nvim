# language.nvim — offene Punkte

1. **Buffer-Highlights für Spell-Issues** (`spell/ui/highlights.lua`) — ursprünglich
   geplant, nie gebaut. Sichtbarkeit läuft aktuell ausschließlich über
   `vim.diagnostic` (Virtual Text/Underline je nach `vim.diagnostic.config()`).
   Kein eigenes, vom Plugin gesetztes `nvim_buf_set_extmark`-Underline direkt
   im Buffer (opt-in, unabhängig von der Diagnostics-Config des Users).

2. **Kein `custom`-Provider-Escape-Hatch für Spell** — Translate hat
   `translate.custom = { cmd, parse }` (beliebiges CLI einhängen); Spell hat
   kein Äquivalent. Wer einen eigenen Spellchecker (nicht typos/cspell/
   codespell/native) einbinden will, kann das aktuell nicht ohne einen neuen
   Provider-Modul-Eintrag in `spell/core/collect.lua`s `CLI_MODULES`-Tabelle.

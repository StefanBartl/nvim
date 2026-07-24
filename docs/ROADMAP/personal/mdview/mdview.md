# `mdview.nvim`
:MDView blanklines
## FINISH

- Alle features durchgehjen und die perform,anteste, ideale DEFAULT config zusammenstellen

---

## Workflow Doc

Szenario: In nvim eine markdown file offen, dann `MDViewStart`:
  1. Was passiert dann genau?
  2. Was passiert, damit die file das erste Mal im Browser aufgebaut wird?
  3. Was assiert, wenn sich die Datei ändert? Wie wird gesynced (Prozess)?
  4. Welche Protkolle machen wann was?

Zusätzlich anhand von praxis use cases die jeweiligen Prozesse beschreiben, also zb.: Welcher Prozess läuft bei den einzelnen usercommands ab?

---

## Bugs

`:MDView detach`: Startet, aber erst nach 5-10 Minuten

---

## Notes

`:MDView standalone` öffnet den Browser über den Go-Binary-eigenen `rundll32`-Aufruf (unabhängig von Neovim), während `:MDView detach` das über Neovims jobstart innerhalb eines headless, komplett `stdio`-losen Kindprozesses macht.
  - :MDView standalone öffnet den Browser direkt aus dem Go-Relay-Binary heraus (rundll32.exe url.dll,FileProtocolHandler), völlig unabhängig von Neovim — ein einziger, schneller Prozessaufruf.
  - :MDView detach / mdview-bg.ps1 laufen dagegen komplett über Neovims eigenes jobstart(), ausgeführt in einer headless, komplett stdio-losen, detachten Neovim-Instanz: erst der /health-Poll (curl per jobstart, alle 200ms bis zu 10s), dann der initiale Push, dann erst der jobstart-Aufruf für den Browser-Opener selbst. Drei separate, verkettete Kindprozess-Spawns statt einem.

---


# nvim-treesitter — User-Commands

`nvim-treesitter` selbst hat keine eigenen Usercmds mehr (moderner
`main`-Branch, deprecated `:TSInstall`/`:TSUpdate`-Style-Commands entfallen
bis auf `:TSUpdate` als `build`-Hook in der Plugin-Spec). Der folgende Befehl
ist **[custom]** — gebaut mit `lib.nvim.usercmd.create` im `config`-Block von
[lua/plugins/treesitter.lua](../../../../../lua/plugins/treesitter.lua),
Backend `lib.nvim.treesitter.parser_policy` (`lib.nvim`-Repo,
`E:\repos\lib.nvim\lua\lib\nvim\treesitter\parser_policy\`).

Hintergrund: siehe [Autocmds/Treesitter.md § Parser-Install-Policy](../Autocmds/Treesitter.md#parser-install-policy-2026-08-01).

## `:TSParserPolicy [off|prompt|auto|reset]`

| Aufruf | Effekt |
|---|---|
| `:TSParserPolicy` | Zeigt aktuellen Modus + die "Nie für X"-Liste. |
| `:TSParserPolicy off` | Kein Prompt, kein Auto-Install — fehlender Parser bleibt unbemerkt (altes Verhalten). |
| `:TSParserPolicy prompt` | **Default.** Beim Öffnen eines Buffers mit fehlendem, aber installierbarem Parser: Auswahl-Prompt (`lib.nvim.ui.kit`) Yes / No / Never for `<lang>`. |
| `:TSParserPolicy auto` | Installiert fehlende Parser sofort, ohne zu fragen — nur eine kurze `notify.info`. |
| `:TSParserPolicy reset` | Löscht die "Nie für X"-Liste (Speicher + Disk-Cache). |

Tab-Completion listet alle vier Argumente.

## Persistenz

Eine "Never for `<lang>`"-Antwort im `prompt`-Modus wird über
`lib.nvim.cache.disk` unter `stdpath("cache")` gespeichert und übersteht
einen Neovim-Neustart — dieselbe Sprache fragt danach nie wieder. Eine
einfache "No"-Antwort wird **nicht** gemerkt: beim nächsten Öffnen eines
Buffers dieser Sprache erscheint der Prompt erneut. Der Modus selbst
(`off`/`prompt`/`auto`) ist **nicht** persistent — jeder Neustart beginnt
wieder beim in `plugins/treesitter.lua` konfigurierten Default (`"prompt"`).

## Warum "Cache" hier trotzdem dauerhaft ist

`lib.nvim.cache` hat zwei Backends: `cache.memory` (rein session-lokal, weg
nach Neustart) und `cache.disk` (eine JSON-Datei unter `stdpath("cache")`,
ohne TTL-Angabe unbegrenzt gültig). `parser_policy` nutzt **disk**, ohne
`ttl_seconds` — "Cache" beschreibt hier nur, *wo* die Datei liegt (ein
Verzeichnis, das man jederzeit gefahrlos löschen kann, ohne dass Neovim
kaputtgeht), nicht dass der Inhalt automatisch verschwindet.

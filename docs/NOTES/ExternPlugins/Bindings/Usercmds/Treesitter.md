# nvim-treesitter — User-Commands

Zwei Sätze: fünf **[default]**-Commands aus dem Plugin selbst, und ein
**[custom]** dieser Config.

## [default] Aus `plugin/nvim-treesitter.lua`

Der moderne `main`-Branch hat die alte Command-Sammlung stark eingedampft —
`:TSBufEnable`, `:TSModuleInfo`, `:TSConfigInfo` und der Rest sind weg —, aber
er ist nicht leer. Fünf Commands registriert das Plugin weiterhin, direkt aus
seinem `plugin/`-Verzeichnis, also sobald lazy.nvim es lädt:

| Command | Argumente | Wirkung |
|---|---|---|
| `:TSInstall[!] {lang}…` | `nargs='+'`, `bang`, Completion: verfügbare Parser | `install.install(langs, { force = <bang>, summary = true })`. Diese Config ruft dasselbe automatisch auf, siehe `:TSParserPolicy` unten. |
| `:TSInstallFromGrammar[!] {lang}…` | wie oben | Wie `:TSInstall`, aber `generate = true` — erzeugt den Parser aus der `grammar.js`, statt einen fertigen zu holen. Braucht eine Toolchain. |
| `:TSUpdate [{lang}…]` | `nargs='*'`, Completion: installierte Parser | `install.update(langs, { summary = true })`. Ohne Argument alle. Steht zusätzlich als `build`-Hook in der Plugin-Spec. |
| `:TSUninstall {lang}…` | `nargs='+'`, Completion: installierte Parser | Parser entfernen. |
| `:TSLog` | keine | `require("nvim-treesitter.log").show()` — das Installations-/Update-Log. Der erste Blick, wenn ein Parser nicht ankommt. |

Alle fünf haben `bar = true`, lassen sich also mit `|` verketten.

Frühere Fassungen dieses Blattes sagten, nvim-treesitter habe „keine eigenen
Usercmds mehr". Das stimmte für den Umfang der Streichung, nicht für das
Ergebnis, und `:Bindings check` hat den Unterschied gefunden: `:TSLog`,
`:TSInstallFromGrammar` und `:TSUninstall` standen als undokumentierte
Live-Commands im Bericht. `:TSInstall` und `:TSUpdate` nicht — die zwei kamen
in der Prosa dieses Blattes vor, und eine Erwähnung reicht der
Undokumentiert-Richtung. Sie wurden dort allerdings als *entfallen*
beschrieben; die Erwähnung hat einen Befund unterdrückt, der berechtigt
gewesen wäre.

## [custom] `:TSParserPolicy`

Gebaut mit `lib.nvim.bindings.usercmd.create` im `config`-Block von
[lua/plugins/treesitter.lua](../../../../../lua/plugins/treesitter.lua),
Backend `lib.nvim.treesitter.parser_policy` (`lib.nvim`-Repo,
`E:\repos\lib.nvim\lua\lib\nvim\treesitter\parser_policy\`).

Hintergrund: siehe [Autocmds/Treesitter.md § Parser-Install-Policy](../Autocmds/Treesitter.md#parser-install-policy-2026-08-01).

### `:TSParserPolicy [off|prompt|auto|reset]`

| Aufruf | Effekt |
|---|---|
| `:TSParserPolicy` | Zeigt aktuellen Modus + die "Nie für X"-Liste. |
| `:TSParserPolicy off` | Kein Prompt, kein Auto-Install — fehlender Parser bleibt unbemerkt (altes Verhalten). |
| `:TSParserPolicy prompt` | **Default.** Beim Öffnen eines Buffers mit fehlendem, aber installierbarem Parser: Auswahl-Prompt (`lib.nvim.ui.kit`) Yes / No / Never for `<lang>`. |
| `:TSParserPolicy auto` | Installiert fehlende Parser sofort, ohne zu fragen — nur eine kurze `notify.info`. |
| `:TSParserPolicy reset` | Löscht die "Nie für X"-Liste (Speicher + Disk-Cache). |

Tab-Completion listet alle vier Argumente.

### Persistenz

Eine "Never for `<lang>`"-Antwort im `prompt`-Modus wird über
`lib.nvim.cache.disk` unter `stdpath("cache")` gespeichert und übersteht
einen Neovim-Neustart — dieselbe Sprache fragt danach nie wieder. Eine
einfache "No"-Antwort wird **nicht** gemerkt: beim nächsten Öffnen eines
Buffers dieser Sprache erscheint der Prompt erneut. Der Modus selbst
(`off`/`prompt`/`auto`) ist **nicht** persistent — jeder Neustart beginnt
wieder beim in `plugins/treesitter.lua` konfigurierten Default (`"prompt"`).

### Warum "Cache" hier trotzdem dauerhaft ist

`lib.nvim.cache` hat zwei Backends: `cache.memory` (rein session-lokal, weg
nach Neustart) und `cache.disk` (eine JSON-Datei unter `stdpath("cache")`,
ohne TTL-Angabe unbegrenzt gültig). `parser_policy` nutzt **disk**, ohne
`ttl_seconds` — "Cache" beschreibt hier nur, *wo* die Datei liegt (ein
Verzeichnis, das man jederzeit gefahrlos löschen kann, ohne dass Neovim
kaputtgeht), nicht dass der Inhalt automatisch verschwindet.

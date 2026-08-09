# language.nvim

## Zweck
Sprachwerkzeuge für Neovim in einem Plugin: Rechtschreib-/Grammatikprüfung mit direkter Aktion
sowie Textübersetzung, mit einem einheitlichen Scope-Modell (buffer/visible/cwd/path/selection)
und durchgehend asynchron (`E:\repos\language.nvim\README.md:3-6`). Baut bewusst auf `lib.nvim`
als geteilte Dependency; Übersetzung braucht laut README kein externes Neovim-Plugin, nur `curl`
(Google-Engine, keyless, ohne Konfiguration nutzbar).

## Nicht-standard Patterns / Algorithmen

- `E:\repos\language.nvim\lua\language\spell\core\regions.lua:1-107` — Rechtschreibprüfung wird
  über Tree-sitter-`@spell`/`@nospell`-Capture-Ranges der aktiven Highlights-Query eingeschränkt,
  statt den ganzen Puffer zu scannen — Code-Identifier werden so übersprungen, nur Kommentare/
  Strings/Prosa geprüft. Explizit **fail-open**: fehlt Parser, Query oder `@spell`-Capture, gibt
  `M.build` `nil` zurück und der Aufrufer behandelt dann *alles* als prüfbar (Zeile 9-11) —
  bewusste Entscheidung gegen false negatives (lieber zu viel als zu wenig prüfen).
- `E:\repos\language.nvim\lua\language\translate\providers\google.lua:1-13` — nutzt den
  inoffiziellen, aber etablierten keyless `gtx`-Endpoint (`translate.googleapis.com/translate_a/
  single?client=gtx`) statt des fragilen privaten Apps-Script-Relays des Referenzprojekts
  (uga-rosa/translate.nvim). Request wird als argv-Liste über `language.util.job` gebaut
  (Zeile 9-10: "the payload is never shell-interpolated") — Schutz vor Shell-Injection bei
  beliebigem zu übersetzendem Text.
- `E:\repos\language.nvim\lua\language\bindings\usrcmds\init.lua:6-19` — `:Translate`/
  `:TranslateReplace`/`:Spellcheck` deklarieren `args`/`flags` nur für die Composer-Completion,
  das eigentliche Dispatching läuft komplett am gebundenen `ctx.args`/`ctx.flags` vorbei direkt
  gegen `ctx.raw` (Composer's unveränderte `nvim_create_user_command`-Callback-Opts). Grund
  (Zeile 10-19): die reale Grammatik klassifiziert Tokens nach Form in beliebiger Reihenfolge
  (Scope-Wort, `path=<p>`, `--flag[=value]`, nackter Sprachcode) statt nach festen Positional-
  Slots — inkl. Dual-Prefix `--nocode`/`-nocode` und stillem Verwerfen unbekannter Flags
  (`dispatch_translate`, Zeile 115-161), was aus einer strikten Composer-Bindung verloren ginge.
- `E:\repos\language.nvim\lua\language\translate\providers\google.lua:36-53` — Response-Parsing
  behandelt die verschachtelte, undokumentierte JSON-Struktur der gtx-API defensiv: jede Ebene
  wird auf `type(...) == "table"` geprüft, bevor weiter indiziert wird, statt der API blind zu
  vertrauen.

## Abgeleitete Guidelines

1. Bei Textanalyse-Features (Spellcheck, Linting) über Tree-sitter-Capture-Regionen filtern, wenn
   verfügbar — aber immer fail-open (alles prüfen), wenn Parser/Query fehlen, nie fail-closed.
2. Inoffizielle/undokumentierte externe APIs (wie gtx) sind akzeptabel, wenn sie nachweislich
   stabil und etabliert sind (von anderen bekannten Tools genutzt) — dann aber die
   Response-Struktur defensiv mit `type()`-Checks auf jeder Ebene parsen, nie ungeprüft indizieren.
3. Externe Prozessaufrufe mit nutzergeneriertem Inhalt (Text, Pfade) immer als argv-Liste bauen,
   nie als interpolierter Shell-String — verhindert Command-/Argument-Injection.
4. Wenn eine Kommando-Grammatik Tokens nach *Form* statt nach *Position* klassifiziert (Flags,
   `key=value`, freie Wörter in beliebiger Reihenfolge), das declarative Schema (für Completion)
   und die Dispatch-Logik (gegen die rohen Args) bewusst entkoppeln, statt die Grammatik in ein
   starres Positional-Modell zu zwingen.

## Keybindings-Audit
Aus `E:\repos\language.nvim\lua\language\bindings\keymaps\init.lua:1-67`, alle optional/config-
driven:

- `cfg.spell.keymaps.panel` → `language.spell.run()` (Toggle Spell-Session im aktuellen Buffer).
  - Count: nein — sinnvoller Anwendungsfall wäre z.B. Count = Sprache aus einer Liste wählen
    (`2<leader>...` → zweite konfigurierte Sprache), aktuell nicht unterstützt.
  - Autocompletion: n.a. (Keymap).
  - Fehlend: keine.
- `cfg.translate.keymaps.operator` → Operator-Pending-Mapping, übersetzt die von einer Motion
  überstrichene Textmenge (`expr = true`).
  - Count: teilweise — als Operator-Pending-Mapping erbt es implizit die Count-Semantik der
    nachfolgenden Motion (`3<leader>tww` → 3 Wörter), das ist die native Vim-Operator-Semantik
    und funktioniert automatisch richtig, ohne dass der Code `vim.v.count` selbst lesen muss.
  - Autocompletion: n.a.
  - Fehlend: keine Möglichkeit, die Zielsprache direkt aus der Motion-Mapping heraus zu wählen
    (immer Default-Sprache) — ein zweites Mapping pro Sprache oder ein Prompt wäre denkbar.
- `cfg.translate.keymaps.visual` → übersetzt die aktuelle Visual-Selektion.
  - Count: n.a. — Visual-Mode-Mapping, Count hat hier keine natürliche Bedeutung.
  - Autocompletion/Fehlend: wie oben.
- `cfg.thesaurus.keymap` → ersetzt das Wort unter dem Cursor durch ein Synonym.
  - Count: nein — `3<leader>th` könnte plausibel "das 3. vorgeschlagene Synonym direkt einsetzen"
    bedeuten (ähnlich wie bei `z=`/Rechtschreibvorschlägen); aktuell nicht implementiert, wäre
    aber eine naheliegende Erweiterung, da `language.thesaurus` bereits eine Auswahlliste hat.
  - Autocompletion: n.a.
  - Fehlend: Count-basierte Direktauswahl (siehe oben).

`:Translate`/`:TranslateReplace`/`:Spellcheck` (usrcmds) bieten volle Tab-Completion für Sprachen,
Scopes und Flags via Composer-Typregistrierung (`SPELL_LANG`, `TRANSLATE_LANG`, …,
`usrcmds/init.lua:51-79`) — Pflicht erfüllt.

## Ideen für andere Plugins
- Ein eigenständiges "Thesaurus-Picker"-Plugin/-Modul mit Count-getriebener Direktauswahl
  (`3<leader>th` = 3. Synonym sofort einsetzen, ohne Menü) — Muster ließe sich generisch für jede
  "Wort unter Cursor durch Alternative N ersetzen"-Funktion (Rechtschreibkorrektur, Thesaurus,
  Übersetzung) in lib.nvim bereitstellen.
- Ein generisches "Fail-open Tree-sitter-Region-Filter"-Modul in lib.nvim, das `regions.lua`s
  Muster (Capture-Name → Byte-Ranges → Fail-open bei fehlender Query) für beliebige Capture-Namen
  (`@spell`, `@nospell`, aber auch z.B. `@comment`, `@string`) verallgemeinert — mehrere Plugins
  (Spellcheck, evtl. künftige Linter) könnten das brauchen.

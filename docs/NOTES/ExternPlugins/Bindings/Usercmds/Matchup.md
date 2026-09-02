# vim-matchup — User-Commands

**Repo:** `andymass/vim-matchup` — der Stamm `Matchup` löst normalisiert auf
`vim-matchup` auf.

Alle sechs Commands sind **[default]**, alle in Vimscript geschrieben, und
diese Config registriert keinen eigenen. Der Spec ist `lazy = false`
([lua/plugins/editing.lua](../../../../../lua/plugins/editing.lua)), die
Commands existieren also ab dem Start.

Konfiguriert wird über `vim.g.matchup_*` im `init`-Block, nicht über die
Commands: `matchup_matchparen_deferred = 1` (kein verzögertes Aufblitzen) und
`matchup_matchparen_offscreen = { method = "status" }` (ein Off-Screen-Match
wird in der Statuszeile gezeigt statt als Popup).

## [default] Die zwei aus `plugin/matchup.vim`

Das ist die Gruppe, die man tatsächlich benutzt — und die zwei Namen sind
nicht zufällig bekannt: **vim-matchup ersetzt Neovims eingebautes
`matchparen`-Plugin und übernimmt dessen zwei Commands.** Wer `:NoMatchParen`
tippt, schaltet also match-up ab, nicht Neovims Original.

| Command | Wirkung |
|---|---|
| `:NoMatchParen` | `matchup#matchparen#toggle(0)` — das Hervorheben des zugehörigen Klammer-/Keyword-Partners abschalten. |
| `:DoMatchParen` | `matchup#matchparen#toggle(1)` — wieder einschalten. |

## [default] Die vier Diagnose-Commands

Aus `autoload/matchup.vim` und `autoload/matchup/perf.vim`. Für die Frage
„warum hebt es hier nichts hervor" und „warum ist es langsam" — nicht für den
Alltag.

| Command | Quelle | Wirkung |
|---|---|---|
| `:MatchupWhereAmI[!]` | `autoload/matchup.vim` | Zeigt den umgebenden Block an, in dem der Cursor gerade steht (`nargs = ?`, mit `!` ausführlicher). |
| `:MatchupReload` | `autoload/matchup.vim` | `matchup#misc#reload()` — lädt die Match-Definitionen neu, nachdem eine `b:match_words`-Regel geändert wurde. Hat mit `<plug>(matchup-reload)` auch ein Plug-Mapping, das diese Config nicht bindet. |
| `:MatchupShowTimes` | `autoload/matchup/perf.vim` | `matchup#perf#show_times()` — die gesammelten Laufzeiten. Nur sinnvoll, wenn das Perf-Tracking läuft. |
| `:MatchupClearTimes` | `autoload/matchup/perf.vim` | Setzt `g:matchup#perf#times` zurück. |

## Keymaps sind hier nicht dokumentiert

vim-matchup bringt eine ganze Reihe mit (`%`, `g%`, `[%`, `]%`, `z%` plus die
Textobjekte `i%`/`a%`), die diese Config unangetastet lässt. Sie gehören in
ein `Keymaps/Matchup.md`, das es noch nicht gibt — dieses Blatt beantwortet
nur die Usercmd-Seite.

## Herkunftsnotiz

Diese sechs sind Vimscript, kein Lua. Für `:Bindings check` heißt das, dass
ihre Herkunft nicht aus dem Callback kommt, sondern aus der `script_id` —
einer Zahl, die zwischen zwei Sessions wechselt. Seit die Eigentümerspalte
sie über `vim.fn.getscriptinfo` in einen Pfad auflöst, standen sie als
`vim-matchup` im Bericht statt als drei verschiedene `script_id`-Werte, und
erst dadurch waren sie als *eine* Gruppe erkennbar.

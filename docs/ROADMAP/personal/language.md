# language.nvim — offene Punkte

Beide zuvor offenen Punkte sind umgesetzt (plugin main, `github.com/
StefanBartl/language.nvim`):

1. ~~Buffer-Highlights für Spell-Issues~~ → `spell/ui/highlights.lua`, opt-in
   via `spell.highlights = { enable = true, style = "underline"|"undercurl" }`,
   markiert Issues per `nvim_buf_set_extmark` direkt im Buffer (eigene
   Highlight-Groups `LanguageSpellHighlight`/`LanguageGrammarHighlight`),
   unabhängig von `vim.diagnostic.config()`.

2. ~~Kein `custom`-Provider-Escape-Hatch für Spell~~ → `spell.providers.custom
   = { cmd = fun(scope,cfg)->argv, parse = fun(out,base)->issues }`, in
   `spell/core/collect.lua`s `CLI_MODULES` registriert; aktivieren über
   `"custom"` in `spell.providers.cwd`. Mirrort `translate.custom`.

Keine weiteren offenen Punkte bekannt.

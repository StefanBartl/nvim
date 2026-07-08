# `markdown.nvim`

## mögliche Features

1. Referenz Feature: Wenn man in den Mardkwon headlines etwas verändert, werden alle Refrenzen in markdown links / toc autopamtisch upgedatet, sodass diese immer stimmen. Was wäre dazu nötig? Wieviel Performance würde das kosten?
2. Die plug keymaps: Plug ist nicht notwendig, besser wäre wenn es `whichkey` imlementierung gibt und das reicht - die nvim_create_keymap() reciht hier vollkomemn aus.
3. 
4. [ ] DoppelklickRechts auf markdown headline -> fold/unfold toggle

### Exra

5. [ ] nivm/lua/config/menu -> neuer eintrag wenn auf mardkown headline: Fold/unfold diese headline, fold/unfold alle darunter, usw... wenn das möglich wäre, dass man menu als dependency nmmt und kdann kann man ies ientreöäge hinzufügen, geren. wenne snur so geht, dass diese in der nvim cuser configi implementiert weren, dann dort

## Bugs & Generell fixes

1. tableview toggle sollt emit `q` bzw `Escape im Normal Mode` geschlossen werden können (`lib.nvim.windows.nice_quit` ?).
2. `   Info  21:31:47 notify.info [markdown_nvim.handler] Handler: No recognized target under cursor` - diese message bei doppel rechtsklick mit der maus  unterdrücken. nur wenn es probleme gibt, dann message ausgeebn.
3. !!! `C-f` funktoinert nicht korrekt


---

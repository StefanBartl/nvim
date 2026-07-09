# `markdown.nvim`

## Bugs

### Workstation (auf PC checken, wenn es da funkt, Workstation debugging)

- [ ] `:Markdown` usrcmd funkltinert nicht mehr ganzm zb render wird nicht angezeigt und auch nicht ausführbar
- [ ]  ml, doppelklick.. soll url öffnen, funktioniert aber nicht
- [ ] `leader [` funkt nicht


## mögliche Features

1. !!! Images ? !!!
2. Referenz Feature: Wenn man in den Mardkwon headlines etwas verändert, werden alle Refrenzen in markdown links / toc autopamtisch upgedatet, sodass diese immer stimmen. Was wäre dazu nötig? Wieviel Performance würde das kosten?
3. Die plug keymaps: Plug ist nicht notwendig, besser wäre wenn es `whichkey` imlementierung gibt und das reicht - die nvim_create_keymap() reciht hier vollkomemn aus.
4. 
5. [ ] DoppelklickRechts auf markdown headline -> fold/unfold toggle
6. Wenn sich ein Markdown Link Url nicht ausgeht in einer Zeile, dann wird ein langer Unterstrich angezeigt:

  ```markdown
  Dies ist nur text um die Zeile brechen zu lassen[Dieser KB-Artikel](https://support-hub.tricentis.com/open?id=kb_article_view&sysparm_article=KB0011252&sys_kb_id=eafc32943b29fe14bef83fc5e4e45ade&spa=1) beschreibt, wie Sie die Support-Info und Logdateien von Tosca Commander, TBox, Workspace, der Migration, dem Flexera-Lizenzserver und dem Installationsprozess des Tricentis-Lizenzservers sammeln.
  ```

  Es wäre toll, wenn man das schöner machen könnte! [Screenshot](./MATERIALS/ML_Link_Thing.png)

### Exra

5. [ ] nivm/lua/config/menu -> neuer eintrag wenn auf mardkown headline: Fold/unfold diese headline, fold/unfold alle darunter, usw... wenn das möglich wäre, dass man menu als dependency nmmt und kdann kann man ies ientreöäge hinzufügen, geren. wenne snur so geht, dass diese in der nvim cuser configi implementiert weren, dann dort

## Bugs & Generell fixes

1. tableview
  1. toggle sollt emit `q` bzw `Escape im Normal Mode` geschlossen werden können (`lib.nvim.windows.nice_quit` ?).
  2. tableview open browser und open browser nice funkltioeren nicht (workstation)
3. `   Info  21:31:47 notify.info [markdown_nvim.handler] Handler: No recognized target under cursor` - diese message bei doppel rechtsklick mit der maus  unterdrücken. nur wenn es probleme gibt, dann message ausgeebn.
4. !!! `C-f` funktoinert nicht korrekt


---

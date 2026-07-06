# `markdown.nvim`

## mögliche Features

1. Referenz Feature: Wenn man in den Mardkwon headlines etwas verändert, werden alle Refrenzen in in markdown links korrigiert, sodass diese immer stimmen

## Bugs & Generell fixes

1. tableview toggle sollt emit `q` bzw `Escape im Normal Mode` geschlossen werden können.
2. `   Info  21:31:47 notify.info [markdown_nvim.handler] Handler: No recognized target under cursor` - diese message bei doppel rechtsklick mit der maus  unterdrücken. nur wenn es probleme gibt, dann message ausgeebn. Es kommt vom DoubleMouseKLick


- [ ] `C-p` und `C-f` funktionreen, aber...:
  - [ ]  wenn möglich sollne sie wenn der cursor auf die nöchste/vorige healdine gesetzt wird, dann sollte die columb beibehalten sein, also wenn ich in der 10 col bin und `C-p` ausführe, dann will ich auf der vorigen headline auch auf col 10 sein bzw auf der nähest möglichen col
  - [ ] es soll auch zur level 1 headline gesprungen werden können. momentan ist bei der ersten level 2 headline schluss



---

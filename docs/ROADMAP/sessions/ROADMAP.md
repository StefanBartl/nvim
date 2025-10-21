# Roadmap für das Sessions-Modul

- `last`-file sollte nicht ständig noise in `git` machen, dass es geändert wurde. Eine Lösung wäre, dass `last` eine grundsätzlich nicht im git index upgedatete file ist, sondern immer lokal bleibt, während sessions, die auf anderen Geräten verwendet werden sollen, mit Labels abgespeichert werden.

---

## Misc

:1. Wenn `nvim +SessionLoad` ausgeführt wird, dann funktoinert etwas mit der ERkennung der File nicht. Beispiel: Es wird eine Markdown Datei geladen, es wird auch Marksman LSP geladen, aber ich habe keinen Zugriff auf filetype spezialisierte Usercommands oder Keymaps wie zb.: `leader toc`. Man muss zuerste den Buffer schließen und wieder öffnen, damit diese ausgefphrt werden. Ich vermute, dass dies so ist, da bei erneuten öffnen der Datei etwas spezifisches in neovim initialisiert oder zugewiesen  wird, dass bei der momentan `nvim +SessionLoad`-Funktion nicht geschieht. Wichtig: Wenn ich nvim alleine ausfphre und dann `SessionLoad` ausführe, dann gibt es das Problem nicht, d.h. es besteht nur wenn man aus der CLI die Session ladet.


## usercommands

1. Es existieren zwei usercommands Dateien: `sessions/commands` und `sessions/usercmds`.

---

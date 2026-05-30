
## Fuzzy Finder

1. `/` und `\` sollten im fuzzy finder nichts aussmachen (sonst kann ich keine pfade copy pasten ohne sie anzupdasse)

## Folder zum dursuchen suchen

`leader fb` bzw `FindFiles [?FolderPath] [?Picker]`

1. -> Bei Übergabe von `FolderPath` in diesem folder bzw bei `.` im aktuellen CWD fuzzy find ausführen
3. -> Picker auswahl (Default Teöescope, fzf/telescope wählbar)
2. -> Wenn kein FolderPath übergeben wird, scannt es denn Filetree und man kann einen folder wählen der dann verwendet wird. Eventuell kann man hier mit dem telescope file tree arbeiten (wenn dieser einen gewähten folder zurückgibt), ansonsten muss man mit buffer arbeiten oder anders

**LÖSUNG:** [Hier](../../lua/lsp/languages/documentation/markdown_words/README.md)

---

## Markdown

### Markdown sollte im gesamten projekt Wörter für die Verfollständigung finden

---

## Replacer

1. Sollte mit "" oder '' funktnionerne

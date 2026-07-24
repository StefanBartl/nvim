

Checkliste fürs Grep in anderen Repos:

- Suche nach cmd.exe, /c start, /C start in Kombination mit einer dynamisch gebauten URL/Pfad-Variable.
- Betroffen ist jeder Aufruf der Form {"cmd.exe","/c","start", ..., url} (egal ob als String oder argv-Liste).
- Fix A (System-Default-Browser/-Handler): explorer.exe <url> statt cmd.exe /c start — kein Shell-Tokenizing dazwischen.
- Fix B (wenn ein spezifisches Programm über start <token> ausgewählt werden muss, explorer.exe also nicht reicht): Sonderzeichen & | < > ^ im Argument mit ^ escapen, bevor es an cmd.exe geht.
- Sogar Neovim selbst hat diesen Bug in vim.ui.open() auf nativem Windows (runtime/lua/vim/ui.lua) — für dieses Repo per config/ui_open.lua gepatcht.

---



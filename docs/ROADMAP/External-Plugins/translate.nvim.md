# translate.nvim workflow integration
=====================================

Features:
 Translate selected text and replace in buffer
 Usercommand :TranslateReplace
 Keymaps for quick visual translation

Setup:
1. Install plugin with Lazy in plugins/workflow.lua
2. All submodules loaded automatically via config/translate/init.lua
3. Use <leader>tr in visual mode to translate selection to English

---

## Bugs

- Wenn man `:TranslateReplace LANG` ausführt, dann wird zwar übersetzt und replaced, aber der letzte char jeder übersetzten Zeile wird dann in die nächste Zeile geschrieben, was ständige Formatierungen nach der Benutzung obligatorisch macht.
- in der replace datei, lass das filter modul weg, dies wird nicht mehr benötigt

## Usercommand

- Wenn man kein argument übergibt, wird ein error geworfen. Es sollte aber der gesamte Buffer übersetzt werden


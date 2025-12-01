# translate.nvim workflow integration
=====================================

Features:
- Translate selected text and replace in buffer
- Usercommand :TranslateReplace
- Keymaps for quick visual translation

Setup:
1. Install plugin with Lazy in plugins/workflow.lua
2. All submodules loaded automatically via config/translate/init.lua
3. Use <leader>tr in visual mode to translate selection to English

---

## --nocode

Hat keine messbare Auswirkung. Ob un nocode oder nicht verwendet wird, die Formatierung in Codeblöcken wird verändert. Das sollte nicht sein.
- Herausfinden, warum ohne `nocode` Codeschnipsel und Codeblöcke nicht übersetzt werden. Wahrscheinlich, da ein KI dafür verwendet wird.
- `nocode` fixen, sodass die Formatierung nicht verändert wird.

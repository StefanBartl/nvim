# `lib.nvim`

1. Personal Plugins auf `utils`-Folder durchsuchen -> Eventuell Funktionen für die lib dabei?
  1. `lib.nvim/lua/nvim/neotree/**` Folder (filetree.nvim)
2. einen der `window`-Helfer tatsächlich in `hover_select` oder einen deiner Picker einbauen

nein, abe in lib.nvim/lua/lib/nvim/system kannst du eine README.md erstellen, indem ebv und rpc pipe module erklärt werden, auf englisch natürlich. in der lib.nvim/README.md kkann dann auf diese datei verweisen werdn mit einem amrkdown link. so einen README.md markdown link können wir auch für lib.nvim/lua/lib/nvim/window/README.md in der lib.nvim/README.md  machen bzw eigentlich fpr lib.nvimUlua/lib/nvim/notify/README.md oder weitere modul readme.md, die in den subdirs existiteren

## Neue Features implmentieren

- alle Cross-Plattform!

1. kanst du in lib.nvim crross eine fnktion einbauen, die geanu das macht, also alles auf ` /` separatoren sanitized? Diese sollte dann in `filetree.nvim` `utils/path -> slashify` bereits liegen bzw erstzen.
2. Alle neuen featurews in die `docs/lib.txt` `vimdoc` sowie die `@types/all_functions` sowie die `init.lua` eintragen

- Alle Module/Funktionen in die `docs/lib.txt` `vimdoc` sowie die `@types/all_functions` sowie die `init.lua` eintragen

---

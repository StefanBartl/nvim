# `lib.nvim`

1. Personal Plugins auf `utils`-Folder durchsuchen -> Eventuell Funktionen für die lib dabei?
  1. `lib.nvim/lua/nvim/neotree/**` Folder (filetree.nvim)
2. einen der `window`-Helfer tatsächlich in `hover_select` oder einen deiner Picker einbauen

nein, abe in lib.nvim/lua/lib/nvim/system kannst du eine README.md erstellen, indem ebv und rpc pipe module erklärt werden, auf englisch natürlich. in der lib.nvim/README.md kkann dann auf diese datei verweisen werdn mit einem amrkdown link. so einen README.md markdown link können wir auch für lib.nvim/lua/lib/nvim/window/README.md in der lib.nvim/README.md  machen bzw eigentlich fpr lib.nvimUlua/lib/nvim/notify/README.md oder weitere modul readme.md, die in den subdirs existiteren

## Neue Features implmentieren

> alle Cross-Plattform!

> Alle neuen features in die `docs/lib.txt` `vimdoc` sowie die `@types/all_functions` sowie die `init.lua` eintragen

1. kanst du in lib.nvim cross eine funktion einbauen, die geanu das macht, also alles auf ` /` separatoren sanitized? Diese sollte dann in `filetree.nvim` `utils/path -> slashify` bereits liegen bzw erstzen.
2. `nvim.window`
  1. `popup`: Ein popup window Modul, dass
    1. bestimmte eigenschaften mitbringt wie `nice_quit`, usw... (features überlegen, nvim.window durchsuchen)
    2. Optionen via Argumente in der Konstruktorfunkton, also zb.:
    ```lua
    {
       type = "note", --Notiz popup
       title = "SOME TITLE", -- optional
       message = "some note"
    }

  -- oder

    {
      type = "select",  -- lib.nvim -> `hover_select` kann hier verwendet werden
      message = "some",
      selection = { "jo", "nein", "geht gar nicht", "gehjt schon" },
    }

  -- oder

    {
      type = "prompt",  -- fragt etwas und man kann dann entweder ja oder enin wählen oder etwas schreiben
      question = "some",
      answer_type = "", -- ja / ein, "text" für textangben
    }

  -- usw.....

    ```

Solche feature Module - gibt es da mehr sinnvolle? Wenn man überegt: Beim bauen von nvim plugins benötigt man oft...
 - windows mit bestimmten optionen immer wieder
 - popup windows die nur kurz in der ui sind und rasch wieder geschlssen werden (wie oben)
 - 

---

# `lib.nvim`

1. Personal Plugins auf `utils`-Folder durchsuchen -> Eventuell Funktionen für die lib dabei?
  1. `lib.nvim/lua/nvim/neotree/**` Folder (filetree.nvim)
2. einen der `window`-Helfer tatsächlich in `hover_select` oder einen deiner Picker einbauen

nein, abe in lib.nvim/lua/lib/nvim/system kannst du eine README.md erstellen, indem ebv und rpc pipe module erklärt werden, auf englisch natürlich. in der lib.nvim/README.md kkann dann auf diese datei verweisen werdn mit einem amrkdown link. so einen README.md markdown link können wir auch für lib.nvim/lua/lib/nvim/window/README.md in der lib.nvim/README.md  machen bzw eigentlich fpr lib.nvimUlua/lib/nvim/notify/README.md oder weitere modul readme.md, die in den subdirs existiteren

- Varianten für schönerer UI: Versfchiedene Lasyoput-Sets konfigurioeren, indem viele verscheidneen Windows / UI obnjelkte wie popus oder hover oder selcts usw... aufeineander abgestimmt sind. Presets unterscheiden sich in Farben, Stärke dret Rahmen, usw....

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

## select mit buttons

Das "i-Tüpferl" wäre, wenn wir "buttons" zeichnen würden, die man dann mit hjkl / pfeiltasten erreichen kann und mit enter bestätigen. Aber nur, wenn das cool hinbiegbar ist. DWenn das geht, dann klönnte man eine userconfig machen, im schon bestehdne  confirmations key, "type =" bei dem der user wählen könnte. Wenn das geht, wäre es super, diese confirmation variatne in lib.nvim.nvim.windows oder so anzulegen. Wenn das sehr sehr aufwendig ist, dann lass es und ich verscuhe ses dann extra in einen löib.nvim chat das zu erstellen und dann im filetree.nvim einzubinden

Gute Nachricht: die Navigation existiert schon. Der Chooser ist bereits eine navigierbare Liste — j/k bzw. Pfeiltasten zum Bewegen, Enter zum Bestätigen, Esc/q zum Abbrechen (h/l sind bewusst blockiert). Was du im Screenshot siehst, ist die durchklickbare Auswahl.

Was fehlt, wären horizontale Buttons (nebeneinander, mit h/l dazwischen) — das ist eine echte, eigenständige lib.nvim-UI-Komponente (Layout-Mathematik, Fokus/Highlight pro Button, eigene Keymaps, Theming, Tests). Das ist genau die „sehr aufwendige" Kategorie, die du selbst erwähnt hast. Wie von dir vorgeschlagen: das lasse ich hier bewusst raus und du machst es in einem fokussierten lib.nvim-Chat.

Wenn diese Komponente in lib.nvim existiert, ist das Einbinden in filetree trivial: ein confirmations.type = "list" | "buttons" würde dann zwischen dem heutigen hover_select-Float und der neuen Button-Variante umschalten. Ich helfe gern beim Einbinden, sobald die Komponente steht.

---


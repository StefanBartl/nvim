# Neues UI Modul

> alle Cross-Platform!
> Alle neuen features in die `docs/lib.txt` `vimdoc` sowie die `@types/all_functions` sowie die `init.lua` eintragen

--> Varianten für schönerer UI: Versfchiedene Layput-Sets konfigurioeren, indem viele verscheidneen Windows / UI obnjelkte wie popus oder hover oder selcts usw... aufeineander abgestimmt sind. Presets unterscheiden sich in Farben, Stärke dret Rahmen, usw....

1. `nvim.window`
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

### select mit buttons

Das "i-Tüpferl" wäre, wenn wir "buttons" zeichnen würden, die man dann mit hjkl / pfeiltasten erreichen kann und mit enter bestätigen. Aber nur, wenn das cool hinbiegbar ist. DWenn das geht, dann klönnte man eine userconfig machen, im schon bestehdne  confirmations key, "type =" bei dem der user wählen könnte. Wenn das geht, wäre es super, diese confirmation variatne in lib.nvim.nvim.windows oder so anzulegen. Wenn das sehr sehr aufwendig ist, dann lass es und ich verscuhe ses dann extra in einen löib.nvim chat das zu erstellen und dann im filetree.nvim einzubinden

Gute Nachricht: die Navigation existiert schon. Der Chooser ist bereits eine navigierbare Liste — j/k bzw. Pfeiltasten zum Bewegen, Enter zum Bestätigen, Esc/q zum Abbrechen (h/l sind bewusst blockiert). Was du im Screenshot siehst, ist die durchklickbare Auswahl.

Was fehlt, wären horizontale Buttons (nebeneinander, mit h/l dazwischen) — das ist eine echte, eigenständige lib.nvim-UI-Komponente (Layout-Mathematik, Fokus/Highlight pro Button, eigene Keymaps, Theming, Tests). Das ist genau die „sehr aufwendige" Kategorie, die du selbst erwähnt hast. Wie von dir vorgeschlagen: das lasse ich hier bewusst raus und du machst es in einem fokussierten lib.nvim-Chat.

Wenn diese Komponente in lib.nvim existiert, ist das Einbinden in filetree trivial: ein confirmations.type = "list" | "buttons" würde dann zwischen dem heutigen hover_select-Float und der neuen Button-Variante umschalten. Ich helfe gern beim Einbinden, sobald die Komponente steht.

### INFO

-> Es gibt bereits ein "hover_select" modul in der libh.nvim. dies lassen wir jedenfall smal so, denn es wird ca 10x in meine anderen pokugins verwendet. aber es kann auch als ideengeber fungieren, vor allem ist natrürlicjh auch sinn, wenn es das neue modul gibt, hover_seldct furch diesess dann zu erstzen... also das sollte man mitdenken
Das ganze soll dann  zu einen möglichsdt inovativen, leicht zu verwendentetn, aber durchaus vuielseitigen Modul werden. Popups, hovers, confirtmation windows, usw...

Sinn der sache unter danderem,, dass ich und andere devs zb.:  ein gewünschtes preset aussuchen und dann alle möglichen UI sachen daraus zu bauen, zb. wenn man Picker UI baut, wie telescope, dann breaucht man 3 winows, alle mit unterschiedlichen größwn und formwen und auzfgaben und es ict gar nicht ewo leicht, diese 3 fenster so anzuordcen, dass sie auch wirlich dann gut aussehen und funkltnieren,  keine zwischenabstände zwischen ihnen usw...

Presets sollen lei cht anzulegen sein auch cvom, user, also das bnrauhen wir auch ein system, wo wird den usrer viele opiuonen geben, farben, hihghlights usw auch selbst zu wähjlen, wenn sie kein preset haben wollen

Ich dneke cdu kannst dr ungefähr vorstellen um was es geht!

### TASK

Erstelle ein Konzewpt für diese mopdul

---



Momemtan mus ich `:TSInstall [all?/parser?]` für Treesitter bzw. `:MasonInstall[All?] [lsp?/formatter?]` ausführen, wenn ich eineneue nvim installation aufsetzte bzw einzeln nachinstallieren, wenn ich ein Dokument  öffnen, und der entsprechenede Tool noch nicht installiert ist.
Meine Idee ist, entweder als eigenes Plugin oder in `lsp.nvim` ein feature einführen, dass beim öffnen einer neuen nvim instanz bzw bei einen neuen Filesystem-Root (wenn man über die Befehlszeile oder `filetree.nvim` ein neus `cwd` setzt) setzt, dass dann ein asynchroner Prozess startet und - ähnlich wie der FS-Cache von `gopath.nvim` - das filesystem durchgeht, dann aer alle fileendungen notiert, checkt ob dafür bereits ein parser besteht.

Je nach konfiguration pasiert dan folgendes:
  - Wenn `autodetect_fext = true,`:
      Der user kann explizit `:* show` ausführen, um eien Liste der noch nciht insatllierten parser für existierende Files des CWD auflisten bzw `:Ü install [all?/tool?]` alle noch nicht installierten oder bestimmte einzelne installieren
  - Wenn `autodetect_fext = true, autoinstall_parser,`:
      dann wird nach dem detektieren gleich im Hintergrund nicht installierte auch gleich installiert
  - Wenn `notify_by_detection` bzw `notify_by_install` nicht false sind, dann werden immer summarys ausgegebn als notify

Benefit: Man hat eine Übersicht und man braucht sich nicht mehr um diese Tools kümmern, außer es würde bei ener installation eines tools etwas nicht passen, dann muss man sowieso manuell nachgehen.

Wäre das mit Mason so üerhaupt möglich? man msste das selbst auchstumm stchalten, dami das nicht interferiert.
Wenn mühsman, wäre das ein weiteres Argument dafür, Mason selsbt nachzubauen bzw mit einen eigenen, modernen zu ersetzten.


# Tipps zum systematischen Testen

:MyHlSet enable_breadcrumbs true aktivieren.

Optional Nerd-Font-Separator setzen:
:MyHlSet breadcrumbs_separator ""
:MyHlSet breadcrumbs_nerd_hex f0058

Reihenfolge der Provider variieren, um Unterschiede zu sehen:
:MyHlSet breadcrumbs_ctx.providers_order '["ts_symbol","container","lsp_func","lang_extra","word"]'

Container-Join ändern: :MyHlSet breadcrumbs_ctx.container_join "::"

Fallbacks gezielt ein-/ausschalten:
:MyHlSet breadcrumbs_ctx.fallback_object_when_empty true
:MyHlSet breadcrumbs_ctx.fallback_word_when_empty true

Tiefe begrenzen/erhöhen: :MyHlSet breadcrumbs_ctx.container_max_depth 1

In Floats/Picker/Explorer sollte die Winbar per winbar_skip unterdrückt sein; normale Files verwenden.

Diese Snippets decken typische Knoten und Heuristiken ab, die der Kontext-Builder nutzt (Funktionen, Methoden, Klassen, Member-Expressions, Tabellen-/Objektfelder, Receiver). Dadurch lassen sich alle Pfade der Pipeline gut überprüfen.

# Breadcrumbs-Kontext (`breadcrumbs_ctx`)

Zielsetzung

1. Wenn normalerweise nur der Pfad angezeigt würde (kein Symbol-Kontext), soll als Fallback ein „nützliches“ Objekt/Container unter dem Cursor (z. B. Table/Owner/Klasse) ermittelt und angezeigt werden.
2. Modularer, erweiterbarer Kontext-Aufbau: pro Sprache kleine Provider-Funktionen.
3. Alles ist zur Laufzeit per Konfiguration toggelbar.

---

## Überblick

Die Winbar zeigt links den (Repo-)relativen Pfad und rechts optional einen Kontextteil. Der Kontext wird aus mehreren Quellen („Providern“) in einer festen Reihenfolge aufgebaut. Jeder Provider ist einzeln aktivierbar und ressourcenschonend implementiert. So erhält man zuverlässige, kompakte Hinweise wie:

```
src/module/util.lua ⟩ M.format()
app/models/user.ts ⟩ User.fullName()
pkg/a.py ⟩ A.m()
```

Wenn kein Symbol ermittelbar ist, greifen abgestufte Fallbacks (Objekt/Owner unter dem Cursor, schließlich das Wort unter dem Cursor), sodass der Kontext möglichst nie leer bleibt.

---

## Schnellstart

Aktivierung

```
:MyHlSet enable_breadcrumbs true
```

Nerd-Font-Separator bevorzugen

```
:MyHlSet breadcrumbs_separator ""
:MyHlSet breadcrumbs_nerd_hex f0058
```

Kontext-Provider feinsteuern

```
:MyHlSet breadcrumbs_ctx.use_treesitter_symbol true
:MyHlSet breadcrumbs_ctx.use_container_chain true
:MyHlSet breadcrumbs_ctx.fallback_object_when_empty true
:MyHlSet breadcrumbs_ctx.fallback_word_when_empty true
:MyHlSet breadcrumbs_ctx.providers_order '["ts_symbol","container","lsp_func","lang_extra","word"]'
:MyHlSet breadcrumbs_ctx.container_join "."
:MyHlSet breadcrumbs_ctx.container_max_depth 2
```

Hinweise

* Änderungen wirken sofort; ein Reload der Datei ist nicht nötig.
* Der Separator kann direkt (String) oder via Nerd-Font-Glyph (Hex-Codepoint) gesetzt werden. Wenn die Glyphe nicht einspaltig darstellbar ist, wird automatisch auf „⟶/›“ zurückgefallen.

---

## Funktionsweise (Provider-Pipeline)

Standardreihenfolge (konfigurierbar über `providers_order`):

1. `lsp_func`
   Bevorzugt `b:lsp_current_function` (falls vorhanden). Sehr schnell; liefert die aktuelle Funktion/Methode.

2. `ts_symbol`
   Erzeugt eine semantische Symbolkette via Tree-sitter (z. B. Klasse → Methode()). Funktioniert ohne LSP und ist robust gegen Sprachenmix.

3. `container`
   Präfixiert bei Bedarf eine Owner/Container-Kette (z. B. `Module.Class`) vor das Symbol (joinbar mit `container_join`). Tiefe begrenzt durch `container_max_depth`.

4. `lang_extra`
   Sprachspezifischer Fallback, falls noch kein Kontext gefunden wurde (z. B. linke Seite einer Member-Expression, empfangender Typ bei Go-Methoden, Tabellenname in Lua-Zuweisungen).

5. `word`
   Letzter Fallback: das Wort unter dem Cursor (außer im Insert-Modus), um völlige Leere zu vermeiden.

Jeder Schritt kann per Flag ein-/ausgeschaltet werden; die Reihenfolge ist frei definierbar.

---

## Konfiguration

### Felder in `cfg.highlight`

```lua
-- Place inside your config table:
breadcrumbs_ctx = {
  -- Prefer LSP function name first (b:lsp_current_function) for quick, low-cost context.
  prefer_lsp_function        = true,

  -- Build a semantic symbol path via Tree-sitter (e.g., Class → method()).
  use_treesitter_symbol      = true,

  -- Prepend an owner/container (e.g., Module.Class) to the symbol when detectable.
  use_container_chain        = true,

  -- If no symbol was found, try to use a useful object/owner under the cursor as fallback.
  fallback_object_when_empty = true,

  -- Final fallback: use the plain <cword> (outside Insert mode) to avoid empty context.
  fallback_word_when_empty   = true,

  -- Enable lightweight, language-specific heuristics (Lua/JS/TS/Python/Go).
  use_lang_specific          = true,

  -- Join string between container and symbol (e.g., ".", "::", " · ").
  container_join             = ".",

  -- Maximum number of container segments to collect (keeps chains compact).
  container_max_depth        = 2,

  -- Provider order: tried in sequence until context is produced.
  -- Supported entries: "lsp_func", "ts_symbol", "container", "lang_extra", "word".
  providers_order            = { "lsp_func", "ts_symbol", "container", "lang_extra", "word" },
}
```

### Separator

* `breadcrumbs_separator`
  Direkter Separator-String, der unverändert verwendet wird (inkl. Leerzeichen, z. B. „ ⟩ “). Hat Vorrang vor Nerd-Font.

* `breadcrumbs_nerd_hex`
  Bevorzugte Nerd-Font-Glyphe als Hex-Codepoint (z. B. `f0058`). Wird nur akzeptiert, wenn die Anzeige genau eine Zelle breit ist; sonst Fallback: „ ⟶ “ (breit) oder „ › “ (schmal).

Weitere relevante Felder:

* `enable_breadcrumbs`
  Schaltet die Winbar-Breadcrumbs an/aus.
* `breadcrumbs_max_len`
  Maximale Länge; bei Überschreitung wird die Mitte ellipsisiert.
* `winbar_skip`
  Regeln, wann die Winbar unterdrückt wird (Floating-Fenster, bestimmte Filetypes/Buftypes, minimale Fensterhöhe).

---

## Sprachabdeckung (aktuell)

* Lua
  Container/Owner aus Funktionsnamen (`M.fn`, `obj:method`), `dot_index_expression`, Tabellenzuweisungen (linke Seite).

* JavaScript/TypeScript (+React)
  Klassenname als Container, linke Seite von `member_expression` als Owner.

* Python
  Klassenname als Container rund um Methoden, linke Seite von `attribute` als Owner.

* Go
  Receiver-Typ als Container bei Methoden (`func (t *T) M()` → `T.M()`).

Die Erkennung ist heuristisch und bewusst flach gehalten (Performance, geringe Fehleranfälligkeit). Für sehr komplexe Ketten kann `container_max_depth` erhöht werden.

---

## Performance

* LSP-Feld (`lsp_func`) ist praktisch kostenlos.
* Tree-sitter-Abfragen sind auf den Knoten unter dem Cursor und wenige Ahnen beschränkt.
* Die Berechnung läuft nur bei sichtbaren Fenster-Events (BufEnter, CursorMoved, WinScrolled) und wird in Floating-/Spezialfenstern gemäß `winbar_skip` unterdrückt.
* Für sehr große Dateien greifen globale Schranken der Highlights (z. B. Deaktivierung teurer Features), der Breadcrumbs-Kontext selbst bleibt leichtgewichtig.

---

## Erweiterbarkeit

Neue Sprachen lassen sich modular ergänzen:

1. In der Container-Ermittlung einen neuen Filetype-Zweig anlegen und geeignete Tree-sitter-Knotentypen auswerten (z. B. Klasse/Modul/Member-Owner).
2. Optional in `lang_extra` weitere Fallback-Heuristiken ergänzen (z. B. linke Seite einer Member-Expression, Namespaces, Module).
3. Die `providers_order` kann jederzeit angepasst werden (auch live per `:MyHlSet`).

Beispiel für Live-Änderung der Reihenfolge:

```
:MyHlSet breadcrumbs_ctx.providers_order '["ts_symbol","container","lsp_func","lang_extra","word"]'
```

---

## Troubleshooting

* Kontext bleibt leer
  `fallback_object_when_empty` und `fallback_word_when_empty` aktivieren. Sicherstellen, dass `winbar_skip` den aktuellen Buffer nicht unterdrückt.
* Glyphen sehen verschoben aus
  `breadcrumbs_separator` statt Nerd-Font verwenden oder eine einspaltige Nerd-Font-Glyphe wählen; der Code akzeptiert Nerd-Glyphen nur, wenn `strdisplaywidth == 1`.
* Konflikte mit anderen Winbar-Plugins
  Die zuletzt schreibende Komponente gewinnt. Entweder die andere Quelle deaktivieren oder die Events so priorisieren, dass die gewünschte Winbar zuletzt gesetzt wird.

---

## Praxis-Tipps

* Sofortige Vorschau der Änderungen:
  `:MyHlSet …` verwenden; ein `:luafile %` ist nicht nötig.
* Für minimalistische Setups die Provider-Reihenfolge verkürzen, z. B.:
  `["ts_symbol","container"]` oder `["lsp_func","word"]`.
* In großen Projekten `container_max_depth` auf `1` setzen, um Ketten kurz zu halten.

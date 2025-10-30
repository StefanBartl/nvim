Die Installation erfolgt durch Hinzufügen einer Plugin-Spezifikation in der Lazy-Konfiguration

```lua
-- File: lua/plugins/unicode.lua
-- or add to existing plugin configuration file

---@type LazySpec
return {
  "chrisbra/unicode.vim",
  -- Optional: lazy loading configuration
  cmd = {
    "UnicodeName",
    "UnicodeSearch",
    "UnicodeTable",
    "Digraphs",
  },
  keys = {
    { "ga", desc = "Show Unicode character info" },
  },
  -- Optional: configuration function
  config = function()
    -- Custom keymaps or settings can be added here
    -- vim.g.Unicode_no_default_mappings = 1  -- Disable default mappings if needed
  end,
}
```

Nach dem Hinzufügen der Datei führt man im Neovim folgende Schritte aus:

1. Neovim neu laden oder `:source` auf die Konfigurationsdatei ausführen
2. `:Lazy sync` ausführen, um das Plugin zu installieren

Falls man eine zentrale Plugin-Datei verwendet, kann man die Spezifikation auch dort einfügen:

```lua
-- In existing lua/plugins/init.lua or similar
{
  "chrisbra/unicode.vim",
  cmd = { "UnicodeName", "UnicodeSearch", "UnicodeTable", "Digraphs" },
  keys = {
    { "ga", desc = "Show Unicode character info" },
  },
}
```

Wichtige Befehle nach der Installation:

- `ga` - Zeigt Informationen über das Zeichen unter dem Cursor
- `:UnicodeName` - Sucht nach Unicode-Zeichen anhand des Namens
- `:UnicodeSearch` - Durchsucht Unicode-Zeichen
- `:UnicodeTable` - Zeigt eine Unicode-Tabelle
- `:Digraphs` - Zeigt verfügbare Digraphen

Die `cmd` und `keys` Optionen bewirken Lazy-Loading, das Plugin wird erst beim ersten Aufruf eines Commands oder Keymaps geladen. Dies kann die Startzeit von Neovim reduzieren. Falls man das Plugin sofort benötigt, kann man diese Optionen weglassen oder `lazy = false` setzen.

## Hier sind praktische Anwendungsbeispiele für jeden Befehl:

## UnicodeName

Sucht nach Unicode-Zeichen anhand des Namens und fügt das gefundene Zeichen ein:

```
:UnicodeName Copyright
```

Ergebnis: Zeigt eine Liste mit passenden Zeichen, man kann dann auswählen und das Zeichen (©) wird eingefügt.

```
:UnicodeName Greek Small Letter Alpha
```

Ergebnis: Fügt α ein.

Man kann auch Teile des Namens verwenden:

```
:UnicodeName arrow right
```

Zeigt alle Pfeil-nach-rechts-Varianten: →, ⇒, ➝, ➞, etc.

## UnicodeSearch

Durchsucht Unicode-Zeichen mit erweiterten Suchkriterien:

```
:UnicodeSearch! alpha
```

Findet alle Zeichen, die "alpha" im Namen enthalten (α, ɑ, Α, etc.).

```
:UnicodeSearch /0x21
```

Sucht nach Unicode-Codepoint (findet ! mit U+0021).

```
:UnicodeSearch dec:169
```

Sucht nach dezimalem Wert (findet ©).

## UnicodeTable

Zeigt eine browsbare Tabelle mit Unicode-Zeichen:

```
:UnicodeTable
```

Öffnet eine interaktive Tabelle, in der man navigieren kann. Man kann dann:
- Mit `/` suchen
- Mit Enter ein Zeichen auswählen und einfügen
- Die Tabelle nach Blöcken filtern

```
:UnicodeTable Greek
```

Zeigt direkt den griechischen Unicode-Block (Α, Β, Γ, Δ, etc.).

## Digraphs

Zeigt alle verfügbaren Digraphen-Kombinationen:

```
:Digraphs
```

Öffnet eine Liste aller Digraphen. Digraphen können im Insert-Mode mit `Ctrl-K` + zwei Zeichen eingegeben werden.

Praktische Beispiele für Digraphen im Insert-Mode:
- `Ctrl-K` + `C` + `o` → ©
- `Ctrl-K` + `1` + `2` → ½
- `Ctrl-K` + `-` + `:` → ÷
- `Ctrl-K` + `*` + `X` → ×
- `Ctrl-K` + `a` + `*` → α

```
:Digraphs alpha
```

Filtert die Liste nach "alpha" und zeigt nur relevante Digraphen.

Der `ga` Befehl im Normal-Mode über einem Zeichen zeigt zusätzlich:
- Den Unicode-Namen
- Den Codepoint (hex, decimal, octal)
- Den HTML-Entity-Code
- Den Digraph (falls vorhanden)

Beispiel: Cursor auf © platzieren und `ga` drücken zeigt:
```
<©> 169, Hex 00a9, Octal 251, Digr Co
Copyright Sign
```

# vim.t.bufs – Tab-lokale Bufferverwaltung in Neovim

## Table of content

  - [Einordnung und Motivation](#einordnung-und-motivation)
  - [Was ist `vim.t.bufs`?](#was-ist-vimtbufs)
  - [Abgrenzung zu Neovim-internen Bufferlisten](#abgrenzung-zu-neovim-internen-bufferlisten)
  - [Wie wird `vim.t.bufs` gepflegt?](#wie-wird-vimtbufs-gepflegt)
  - [Typische Annahmen über `vim.t.bufs`](#typische-annahmen-ber-vimtbufs)
  - [Preview-Buffer als Sonderfall](#preview-buffer-als-sonderfall)
  - [Warum Validierung notwendig ist](#warum-validierung-notwendig-ist)
  - [Verantwortlichkeiten und Designgrenzen](#verantwortlichkeiten-und-designgrenzen)
  - [Zusammenfassung](#zusammenfassung)
  - [Weiterführende Hinweise](#weiterfhrende-hinweise)

---

## Einordnung und Motivation

`vim.t.bufs` ist eine von NvChad eingeführte, tab-lokale Datenstruktur zur Verwaltung jener Buffer, die in einer bestimmten Tabpage als „relevant“ gelten. Sie dient primär als Datenquelle für die Tabline (`tabufline`), kann aber auch von anderen Komponenten genutzt werden, die eine stabile, kontextbezogene Bufferliste benötigen.

Neovim selbst stellt zwar umfangreiche Buffer-APIs bereit (`:ls`, `nvim_list_bufs()`, `buflisted`, `bufloaded`), kennt jedoch kein eingebautes Konzept einer tab-lokalen Bufferliste. `vim.t.bufs` schließt genau diese Lücke.

---

## Was ist `vim.t.bufs`?

`vim.t.bufs` ist:

• eine Lua-Tabelle
• tab-lokal (`vim.t` = Tabpage-Scoped Variable)
• explizit gepflegt durch Autocommands
• **keine** direkte Spiegelung von `nvim_list_bufs()`

Typischerweise enthält sie ausschließlich Buffer-IDs (`bufnr`), zum Beispiel:

```lua
---@type integer[]
vim.t.bufs = { 3, 7, 12 }
```

Diese Liste repräsentiert die Buffer, die:

• in diesem Tab geöffnet wurden
• für die Tabline sichtbar sein sollen
• nicht explizit ausgeschlossen wurden (z. B. unbenannte, unmodifizierte Buffer)

---

## Abgrenzung zu Neovim-internen Bufferlisten

Neovim kennt global alle Buffer:

```lua
vim.api.nvim_list_bufs()
```

Diese Liste enthält **alles**, unter anderem:

• unlisted Buffer (`:set nobuflisted`)
• temporäre Preview-Buffer
• Plugin-interne Scratch-Buffer
• bereits geladene, aber nicht sichtbare Buffer

`vim.t.bufs` hingegen ist:

• gefiltert
• kontextbezogen (pro Tab)
• semantisch höherwertig

Man kann sich `vim.t.bufs` als „Arbeitsmenge“ vorstellen, nicht als technische Vollmenge.

---

## Wie wird `vim.t.bufs` gepflegt?

In NvChad geschieht die Pflege typischerweise über Autocommands wie:

• `BufAdd`
• `BufEnter`
• `BufDelete`
• `TabEnter`

Dabei werden Buffer-IDs:

• hinzugefügt, wenn ein Buffer im Tab relevant wird
• entfernt, wenn ein Buffer geschlossen oder ausgeschlossen wird

Wichtig ist:

`BufAdd` feuert **sehr früh** im Lebenszyklus eines Buffers.

Zu diesem Zeitpunkt kann ein Buffer:

• noch keinen Namen haben
• kurz darauf wieder gelöscht werden
• von Plugins nur für Previews erzeugt worden sein

---

## Typische Annahmen über `vim.t.bufs`

Viele Teile von `tabufline` gehen implizit davon aus, dass:

• Einträge in `vim.t.bufs` valide Buffer-IDs sind
• `nvim_buf_get_name(buf)` gefahrlos aufgerufen werden kann
• Buffer nicht „verschwinden“, während man sie verarbeitet

Diese Annahmen sind im Normalfall korrekt, können aber bei:

• Preview-Fenstern
• asynchronen Plugin-Operationen
• schnellen Open/Close-Zyklen

kurzzeitig verletzt werden.

---

## Preview-Buffer als Sonderfall

Plugins wie:

• Neo-tree
• Telescope
• FZF-lua
• mini.files

erzeugen häufig Buffer, die:

• unlisted sind
• nur wenige Millisekunden existieren
• nie als „echte Dateien“ gedacht sind

Trotzdem kann `BufAdd` ausgelöst werden, bevor:

• der Buffer als unlisted markiert ist
• der Buffer wieder gelöscht wird

In diesem Zeitfenster kann ein solcher Buffer:

• in `vim.t.bufs` landen
• beim nächsten Zugriff bereits invalid sein

---

## Warum Validierung notwendig ist

Die Neovim-API ist in diesem Punkt strikt:

```lua
vim.api.nvim_buf_get_name(bufnr)
```

wirft einen **hart abbrechenden Fehler**, wenn `bufnr` invalid ist.

Daher ist folgende Annahme unsicher:

```lua
bufs[1] existiert → bufs[1] ist gültig
```

Die sichere Variante lautet:

```lua
if #bufs > 0 and vim.api.nvim_buf_is_valid(bufs[1]) then
  -- safe access
end
```

Diese Validierung ist keine logische Korrektur der Architektur, sondern eine Laufzeitabsicherung gegen kurzlebige Zustände.

---

## Verantwortlichkeiten und Designgrenzen

`vim.t.bufs` ist kein Neovim-Kernkonzept, sondern:

• eine Konvention
• eine Hilfsstruktur
• eine Implementierungsentscheidung von NvChad

Daher gilt:

• Plugins können sich nicht zuverlässig darauf einstellen
• perfekte Synchronität ist nicht erzwingbar
• defensive Programmierung ist notwendig

Langfristige Verbesserungen könnten sein:

• spätere Hooks als `BufAdd`
• explizites Filtern von Preview-Buffer-Typen
• zentrale Validierungsfunktionen für `vim.t.bufs`

---

## Zusammenfassung

• `vim.t.bufs` ist eine tab-lokale, kuratierte Bufferliste
• sie ist bewusst **nicht identisch** mit Neovims globaler Bufferliste
• Preview- und temporäre Buffer können kurzzeitig hineinrutschen
• frühe Autocommands wie `BufAdd` machen Validierung notwendig
• robuste Nutzung erfordert immer `nvim_buf_is_valid()`

`vim.t.bufs` ist damit weniger eine absolute Wahrheit als ein „best effort“-Abbild des aktuellen Arbeitskontexts eines Tabs.

---

## Weiterführende Hinweise

• `:h vim.t`
• `:h BufAdd`
• `:h nvim_buf_is_valid()`
• `:h buflisted`
• NvChad `tabufline` Implementation

---

# Coaching-/Lecture-Workflow mit mdview.nvim + markdown.nvim

> Persönliche Notiz, kein offizieller Roadmap-Teil. Szenario: 1:1-Call mit
> Coach, Screen-Share **nur des Browser-Tabs** mit der mdview-Preview, während
> du selbst in Neovim arbeitest (schreibst, springst zwischen Dateien,
> formatierst Tabellen, navigierst Überschriften) — der Coach sieht immer die
> gerenderte Markdown-Seite, nie dein Terminal/deine Config.

---

## 1. Einmaliges Setup (vor dem ersten Call)

### mdview.nvim config

```lua
require("mdview").setup({
  scroll_sync = true,
  scroll_sync_mode = "top",       -- "top": Zeile bleibt oben stabil beim Reden —
                                   -- ruhiger für einen passiven Zuschauer als
                                   -- "cursor" (Mirror), das bei jedem Scrollen
                                   -- springt. "cursor" ist eher was für dich
                                   -- allein (Editor-Gefühl).
  browser = {
    behavior        = "reuse",    -- EIN Tab folgt jedem Buffer-Wechsel — du
                                   -- musst das Sharing im Call nie neu wählen.
    focus           = "nvim",     -- Preview-Tab holt sich nie den Fokus/Vordergrund
                                   -- — du kannst weiterschreiben, ohne dass der
                                   -- Browser dich unterbricht.
    theme           = "github",   -- helles Theme liest sich über komprimiertes
                                   -- Video-Codec meist klarer als ein dunkles.
    external_links  = "new_tab",  -- ein Klick des Coaches auf einen Link verliert
                                   -- nie die geteilte Preview.
    cursor_marker   = "caret",    -- zeigt live, wo genau du gerade bist — du musst
                                   -- nicht mehr sagen "schau mal Zeile X".
    browser_autostart = true,
    require_display    = true,
  },
  experimental = {
    click_navigate = true,        -- relative Links im Preview öffnen die Zieldatei
                                   -- in nvim — nützlich, wenn der Coach selbst
                                   -- durch verlinkte Notizen klickt.
    reverse_scroll = false,       -- opt-in: siehe Abschnitt 4 (Kontrolle abgeben).
  },
})
```

Für maximale Privatsphäre beim Screen-Sharing (kein Verlauf/Lesezeichen/andere
Tabs sichtbar, falls der Browser mal in den Vordergrund kommt):
`browser.open_mode = "isolated"` + `browser.browser = "firefox"` (o. ä.) —
spawnt ein Wegwerf-Profil, das beim `:MDViewStop` auch zuverlässig wieder
zugeht (`browser.browser_autoclose`).

### Keymaps (mdview.nvim liefert bewusst keine mit)

```lua
local map = vim.keymap.set
map("n", "<leader>ms", "<cmd>MDViewStart<cr>",      { desc = "mdview: start" })
map("n", "<leader>mq", "<cmd>MDViewStop<cr>",       { desc = "mdview: stop" })
map("n", "<leader>mo", "<cmd>MDViewOpen<cr>",       { desc = "mdview: re-open tab" })
map("n", "<leader>mt", "<cmd>MDViewToggle<cr>",     { desc = "mdview: toggle" })
map("n", "<leader>mT", "<cmd>MDViewTheme<cr>",      { desc = "mdview: theme" })
map("n", "<leader>ml", "<cmd>MDViewShowWebLogs<cr>",{ desc = "mdview: web logs (debug vor dem Call)" })
```

### Relevante bestehende markdown.nvim-Keymaps (schon aktiv, nichts zu tun)

| Key | Aktion | Warum im Call nützlich |
|---|---|---|
| `<C-f>` / `<C-p>`, `]]` / `[[` | Heading vor/zurück | Schnell zum besprochenen Abschnitt springen, Preview folgt via scroll_sync |
| `{count}<leader>toc` | TOC einfügen/aktualisieren | Vor dem Call schnell eine Gliederung erzeugen |
| `<leader>tvt` / `<leader>tvx` | Tabellen-Float (Markdown/Box-Style) | Für dich selbst — sauberer lesen als Rohtext, ohne dass es der Coach sieht |
| `ma` / `mj` / `mi` | Link/Anchor/Bild öffnen | Schnell zwischen verwandten Notizen springen |
| `<leader>[` | Selektion/Wort in Link wrappen | Spontan während des Gesprächs verlinken |

---

## 2. Vor dem Call

1. Kurzer Trockenlauf: `:MDViewStart`, Theme/Lesbarkeit prüfen (`:MDViewTheme`),
   dann `:MDViewStop`.
2. Browserfenster in gewünschter Größe/Position vorplatzieren, **dann** erst
   den Screen-Share starten — und dabei explizit **nur das Browserfenster**
   teilen, nicht den ganzen Bildschirm/Desktop. `focus = "nvim"` sorgt dafür,
   dass es während des Calls nicht ungewollt in den Vordergrund springt.
3. Bei Reise/ohne Display: `:MDViewPreviewTab` als Fallback — read-only
   Treesitter-Preview direkt in einem nvim-Tab, komplett ohne Server/Browser.

## 3. Während des Calls

- **Thema starten:** `:MDViewStart <file>` (oder aktueller Buffer), einmal den
  Tab teilen — danach läuft alles über `behavior = "reuse"` automatisch mit.
- **Datei wechseln:** ganz normal `:e`, Telescope, `'0`-Marks etc. — der
  geteilte Tab zeigt automatisch die neue Datei, ohne dass du das Sharing neu
  auswählen musst.
- **Innerhalb eines Dokuments navigieren:** Heading-Sprünge (`<C-f>`/`<C-p>`)
  + `scroll_sync` bringen den Coach automatisch mit; `cursor_marker = "caret"`
  zeigt exakt die Stelle, über die du gerade sprichst.
- **Tabelle besprechen:** `:Markdown table view browsernice` öffnet sie groß
  und GitHub-gestylt in einem eigenen Tab (separat teilen oder kurz
  rüberschalten); `:Markdown table format` / `table mode on`, um sie live
  während des Gesprächs sauber zu halten.
- **Querverweis spontan anlegen:** `<leader>[` auf Wort/Selektion.
- **Kontrolle abgeben:** mit `experimental.reverse_scroll = true` kann der
  Coach im Preview selbst scrollen (Polling, kleine Latenz) — praktisch, wenn
  er/sie in Ruhe etwas nachlesen will, ohne dir "scroll mal hoch" zu sagen.
  Mit `click_navigate` kann er/sie sogar selbst auf einen Link klicken und die
  Zieldatei bei dir öffnen.

## 4. Nach dem Call

- `:MDViewStop` beendet den Relay **und** schließt den Tab
  (`browser.browser_autoclose`) — kein Aufräumen von Hand nötig.
- Siehe Feature-Idee „Session-Breadcrumbs" unten — aktuell noch nicht vorhanden,
  wäre aber genau für den Nachbereitung-Schritt gedacht.

---

## 5. Feature-Ideen — mdview.nvim

- **Persistenter Mini-Outline-Overlay** — ein schwebendes TOC im Preview, das
  die aktuelle Position hervorhebt, unabhängig vom Scroll-Zustand sichtbar
  bleibt. Hilft dem Coach, Struktur und Fortschritt im Dokument im Blick zu
  behalten, ohne dass du ständig sagst "wir sind jetzt bei Punkt 3 von 5".

Eigentlidh nodh mehr: ein overlay system, mitdem ich sschnell als lin nvim overlays togglen  kanan, super wäre sowas wi dass schwebende toc oder andere nützliche overlays, da kannst du dir was einfallen lassen. zb würde mir so ein effekt im browser einfallen, der den nahem bereich um eienses cursors um etwas zomt wie eine lupe oder es git ewin tool auch nvim pluugin mitdem kann man anzeigen was manm am keyboard einfubt, ddas wäre auch coola lals overlay

---


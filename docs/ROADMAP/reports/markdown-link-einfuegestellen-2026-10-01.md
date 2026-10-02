# Markdown-Link-Einfügestellen — wer fügt Links ein, wohin geht der Cursor

**Status: umgesetzt und abgeschlossen (Nachprüfung 2026-10-02)** — alle Commits der Tabellen unten
liegen auf `main` der jeweiligen Repos, die lib.nvim-Suite (inkl. `markdown_link_cursor_spec`) läuft
grün, `link_cursor.setup({})` ist zentral in `lua/plugins/personal/specs/foundation.lua` gesetzt.
Das Dokument ist nach `wkdbook-myplugins/ALL/Backlog/FEATURES/` einsortiert (dort liegt nur ein
Pointer, dieses Original bleibt hier).

Stand 2026-10-01. Anlass: „`:Image paste` setzt den Cursor hinter den Link — dort ist nichts mehr zu
tun. Das gilt für jedes Usercmd, das einen Markdown-Link einfügt." Alle Repos unter `$REPOS_DIR` wurden
nach Link-Erzeugung/-Einfügung durchsucht (`\]\(%s\)`, `[%s](`, `link_template`, `nvim_buf_set_text`/
`set_lines` in Link-Pfaden).

## Die Regel (überall gleich)

Der Cursor geht dorthin, **wo noch etwas fehlt**, und es folgt der Insert-Modus:

| Eingefügter Link | Cursor |
|---|---|
| Titel leer (`![](assets/x.png)`, `[](url)`, `[]()`) | in den Titel `[|]` |
| Titel gefüllt, Pfad gefüllt (`[name](path)`) | in den Pfad (Ende; `path_cursor = "start"` möglich) |
| Titel gefüllt, Pfad leer (`[name]()`) | in `()` |
| mehrere Links auf einmal | der **erste** Link entscheidet |
| kein Link im Text | hinter dem Text (wie früher) |

Umsetzung an **einer** Stelle: [`lib.nvim.markdown.link_cursor`](https://github.com/StefanBartl/lib.nvim)
(`locate` rein, `place`/`insert`/`insert_links` mit Fenster). Global steuerbar über
`link_cursor.setup({ enable, startinsert, path_cursor })`; jedes Plugin kann pro Aufruf eigene Optionen
durchreichen. Helfer dazu: `lib.nvim.window.find_usable.previous_window()` (Fenster, aus dem man kam).

## Stellen, die Links in einen Buffer **einfügen**

| Plugin | Stelle / Befehl | Vorher | Jetzt | Option | Commit |
|---|---|---|---|---|---|
| images.nvim | `:Image paste`, `:Image screenshot`, Keymap | hinter dem Link | in den leeren Alt-Text, Insert | `paste.link_cursor` | `242f3ed` |
| markdown.nvim | Link-Wrap-Keymap (`core/wrap_link.lua`, Wort/Selektion → `[]()`) | in die Klammern, Normal-Modus | gleiche Position + Insert | `links.cursor` | `19fabae` |
| filetree.nvim | **neu** `MI` / `:Filetree mdlink insert` (`ML`/`MR`/`MM` kopieren nur) | – (nur Register) | ins vorherige Fenster, mehrere Links als eigene Zeilen, Cursor in den ersten | `markdown_links.keymap_insert`, `insert_path`, `env_roots`, `cursor` | `9a0e0dc` |
| pickers.nvim | **neu** `<M-n>` / `MI` / fzf `alt-n` (`markdown_link`/`ML` kopiert nur) | – (nur Register) | Picker schließt, Links ins Fenster dahinter, Cursor in den ersten | `keys.markdown_link_insert`, `link_insert` | `7fbd2aa` |
| buffer-ctx.nvim | `:Insert mdlink` (`cursor.insert_text`) | hinter dem Link | in den Link + Insert | lib-weit (`link_cursor.setup`) | `006a306` |
| buffer-ctx.nvim | `:Insert imagepaste` | – | delegiert an `images.paste` → wie images | – | (über images) |
| casedesk.nvim | `:Case insert asset` (`ui/insert.lua`, `[name](rel)`) | hinter dem Link | in den Pfad + Insert; andere Felder (Fallnummer, Firma) unverändert | lib-weit | `dd58bc1` |

Pfad-Schreibweise der Einfüge-Aktionen (jeweils konfigurierbar, Default **relativ zum Ziel-Buffer**):
filetree `insert_path` und pickers `link_insert.path` = `buffer` | `cwd` | `absolute` | `env`;
images `paste.default_path_mode` zusätzlich `env`/`repos`/Präfix. `env` → `$REPOS_DIR/…`,
`$NVIM_CONFIG_DIR/…` (über `gopath.shorten_path`, sonst eingebaute Roots, sonst relativ). Ein `$VAR/…`-Ziel
bekommt von markdown.nvims Sanitize-on-save kein `./` mehr (`03b0867`) und wird, wenn ein älterer Stand es
kaputtgemacht hat, repariert (`links.repair_env_prefix`).

## Stellen, die Links nur **erzeugen/kopieren** (kein Cursor-Thema)

| Plugin | Stelle | Verhalten |
|---|---|---|
| markdown.nvim | `:Markdown links <path>` (`commands/markdown_links.lua`, `for_paths`) | Clipboard |
| filetree.nvim | `ML` / `MR` / `MM` | Register `+` und `"` |
| pickers.nvim | `markdown_link` (`<M-l>` / `ML` / `MM`) | Register |
| markdown.nvim / filetree.nvim | `core/file_refs.lua`, `refs.lua` / `util/markdown_refs.lua` | schreiben bestehende Links nach Move/Rename um |
| color_my_ascii.nvim | `commands/fence/export.lua` (`replace_block_with_ref`) | ersetzt einen Fence-Block durch `[name](rel)` — Link ist vollständig, Cursor wird nicht angefasst → **bewusst unverändert** |
| open.nvim | `viewer/init.lua`, `viewer/scan.lua` | formatiert Links nur für die Anzeige |
| documentation.nvim | `core/render/*`, `core/deps.lua` | erzeugt Doku-Dateien (kein Buffer-Insert; der `deps.lua`-Treffer ist ein `require`-Muster) |

Ohne Treffer: mdview.nvim, media.nvim, hover.nvim, gopath.nvim, recommender.nvim, insights.nvim.

## Offen / bewusst nicht getan

- ~~`link_cursor` hat keinen Konfigurationseintrag in einer zentralen Spec~~ — **erledigt**: die nvim-Config
  ruft `require("lib.nvim.markdown.link_cursor").setup({})` zentral in `specs/foundation.lua` auf (explizit,
  obwohl gleich den Modul-Defaults); pro Plugin lässt sich weiterhin überschreiben (images/markdown/pickers/
  filetree), buffer-ctx und casedesk nutzen die lib-weiten Werte.
- Die Einfüge-Aktionen in filetree/pickers sind **neu** (vorher nur Kopieren) — wer sie nicht will, bindet
  `keymap_insert = false` bzw. `keys.markdown_link_insert = false`.
- Ein Paste mit `p` nach `ML` kann den Cursor nicht in den Link setzen (kein Hook auf `p`); dafür gibt es jetzt
  die Einfüge-Aktionen.

# buffer-ctx.nvim

## Zweck
Liefert kontextbezogene Textbausteine für den aktuellen Buffer — Pfad, Modulname,
Zeitstempel, UUID, Annotationen, Boilerplate, Snippets, Git-Infos — und schreibt sie
entweder am Cursor ein (`:Insert`) oder in die Zwischenablage (`:Copy`). Dazu kommen
`:Format` (Buffer-/Selektions-Formatierung) und `:Mark` (persistente Zeilenmarkierungen
mit Yank-to-clipboard). Alles läuft über `lib.nvim.usercmd.composer` als harte Abhängigkeit.

## Nicht-standard Patterns / Algorithmen

- `lua/buffer_ctx/mark/init.lua:24-33` — Marks werden per **Extmark-ID** statt Zeilennummer
  indiziert (`table<bufnr, table<extmark_id, boolean>>`). Grund: Neovim verschiebt Extmarks
  automatisch bei Zeileneinfügungen/-löschungen oberhalb, ein einfacher Integer-Key (Zeilennummer)
  bliebe stehen und würde nach jeder Bearbeitung auf die falsche Zeile zeigen. Der Kommentar
  verweist explizit auf einen früheren Bug (`docs/ROADMAP/anchor-stable-marks.md`).
- `lua/buffer_ctx/mark/init.lua:91-134` — Feature-Gate auf `nvim-0.10`: ab 0.10 werden
  `sign_text`/`sign_hl_group` direkt am Extmark gesetzt (eine Tracking-Quelle) und
  `invalidate = true, undo_restore = false` sorgt dafür, dass ein Mark beim Löschen seiner
  Zeile wirklich verschwindet statt auf die Nachbarzeile zu rutschen. Auf 0.9 (dokumentierter
  Minimalstand) wird stattdessen ein klassisches `sign_place`/`sign_unplace` parallel geführt,
  keyed über dieselbe Extmark-ID — bewusster Kompromiss, weil auf 0.9 das exakte Verhalten
  nicht erreichbar ist.
- `lua/buffer_ctx/mark/init.lua:225-238` — `M.yank` sortiert nach der *aufgelösten aktuellen*
  Zeile (`resolve_line`), nicht nach Extmark-ID-Erzeugungsreihenfolge, weil IDs nach mehrfachem
  Toggle/Reorder nicht mehr der Pufferreihenfolge entsprechen; dabei werden zugleich Marks mit
  gelöschter Ankerzeile aus dem State entfernt (lazy cleanup statt separatem GC-Pass).
- `lua/buffer_ctx/util/notify.lua`, `util/path.lua:8-11`, `ops/uuid.lua:8` — durchgängiges
  Soft-Dependency-Muster: `pcall(require, "lib.nvim.X")`, bei Erfolg wird die lib.nvim-Variante
  genutzt, sonst eine lokale Fallback-Implementierung mit identischer Schnittstelle. Vermeidet
  harten Crash, wenn lib.nvim in einer bestimmten Version fehlende Submodule hat, ohne auf die
  Verbesserungen (z.B. bessere Notifier-UI) zu verzichten, wenn sie da sind.
- `lua/buffer_ctx/commands.lua:380-411` — `composer.register_type` registriert dynamische
  Custom-Typen (`BUFFER_CTX_BOILERPLATE/SNIPPET/ENV`) für die drei Subcommands, deren gültige
  Werte erst zur Laufzeit aus User-Config bekannt sind (Boilerplate-Templates, Snippet-Keys,
  Env-Var-Namen) — Completion bleibt dadurch lazy statt beim `setup()` einzufrieren.
- `lua/buffer_ctx/mark/init.lua:306-313` — Buffer-scoped State wird per `BufDelete`/`BufWipeout`
  Autocommand aktiv geleert (`clear_marks`), um unbegrenztes Wachstum der `marked`-Tabelle über
  eine lange Session zu verhindern (kein automatisches Neovim-GC für plugin-eigene Lua-Tabellen).

## Abgeleitete Guidelines

1. Zustand, der an Puffer-Positionen hängt (Marks, Bookmarks, o.ä.), IMMER über Extmarks
   referenzieren, nie über rohe Zeilennummern — sonst driftet der State bei jeder Bearbeitung
   oberhalb der Position auseinander.
2. Bei Extmark-Nutzung: Feature-Gate auf `nvim-0.10` für `invalidate`/`undo_restore` und
   `sign_text`/`sign_hl_group`; auf älteren Versionen expliziten Sign-Fallback keyed über
   dieselbe ID bereitstellen, nicht stillschweigend degradieren.
3. Optionale Abhängigkeiten (lib.nvim-Submodule) immer über `pcall(require, ...)` mit
   identischer Fallback-API einbinden — nie einen harten `require` für "nice-to-have"-Verbesserungen.
4. Buffer-lokaler Plugin-State muss über `BufDelete`/`BufWipeout` aktiv aufgeräumt werden,
   sonst wächst er unbegrenzt über die Session.
5. Bei mehreren Kommandos mit identischer Options-Matrix (hier `:Insert`/`:Copy`) eine
   gemeinsame Route-Factory bauen, die nur im "Sink" variiert (`build_routes(sink)`),
   statt Logik zu duplizieren.
6. Dynamische Completion-Werte (aus User-Config gespeist) über einen eigenen `composer`-Typ
   mit `complete()`-Callback lösen statt sie beim `setup()` statisch einzufrieren.
7. Compat-/Alias-Commands (z.B. `:CopyFilepathAbsolute`) explizit und separat registrieren,
   nicht ins generische Dispatch-System zwingen, wenn sie eine eigene, stabile Außenschnittstelle
   brauchen (Migrationskompatibilität).
8. Clipboard-Schreiboperationen als reinen Sink implementieren (`clip.copy` gibt nur Status
   zurück), Benachrichtigung bleibt Aufgabe des Aufrufers — vermeidet doppelte/inkonsistente
   Notify-Nachrichten an verschiedenen Call-Sites.

## Keybindings-Audit

Definierte Keymaps (aus `config/DEFAULTS.lua` + `bindings/keymaps.lua`, `mark/init.lua`):

- `<leader>cnl` (normal) — Copy location (path:line). Kein `count`-Support: Operation ist
  buffer-global (aktuelle Cursor-Zeile), ein Count ergibt semantisch keinen Sinn (n/a).
- `<leader>cnm` (normal) — Copy module path. Gleiches: kein Count-Bezug, n/a.
- `<leader>cnf` (normal) — Copy filepath (cwd-relative). n/a für Count.
- `<S-m>` (normal, `mark.keymaps.toggle`) — Toggle Mark auf aktueller Zeile. Kein Count-Support
  in `mark/init.lua:283-285` (`M.toggle(vim.api.nvim_win_get_cursor(0)[1])` ignoriert `v:count`).
  Wäre sinnvoll nachrüstbar: `3<S-m>` könnte z.B. 3 Zeilen ab Cursor markieren — aktuell nicht
  möglich.
- `<C-p>` (normal, `mark.keymaps.yank`) — Yank alle markierten Zeilen. n/a für Count (globale
  Sammel-Operation).

Autocompletion:
- `:Insert`/`:Copy` Subcommands und deren erstes Arg sind vollständig über `composer`
  vervollständigbar (`SUBCMD_ARGS`-Tabelle, `commands.lua:311-347`), inkl. dynamischer
  Completion für `boilerplate`/`snippet`/`env` über `register_type`. Das ist vorbildlich —
  jedes Subcommand hat eine Werteliste oder eine `complete()`-Funktion.
- Kein Picker-basiertes Interface für `:Mark toggle`/`:Mark yank` (nicht nötig, da parameterlos).

Fehlende Flags/Optionen (Ideen):
- `:Mark toggle` könnte einen Range-Modus bekommen (visuelle Selektion → alle Zeilen markieren).
- `mark.sign` erlaubt nur ein globales Zeichen/Highlight; mehrere "Kategorien" von Marks
  (z.B. rot/grün/gelb) wären ein natürliches Erweiterungsfeature, fehlen aber komplett.
- Kein `:Mark clear` zum Leeren aller Marks eines Buffers ohne einzeln zu togglen.

## Ideen für andere Plugins

- Das Extmark-basierte Mark-Muster (`mark/init.lua`) ist generisch genug für ein eigenständiges
  Mini-Plugin "sticky-marks.nvim": mehrfarbige, benannte, persistente Zeilenmarkierungen mit
  Yank/Jump/Clear, die über Reloads/Sessions hinweg (via `mksession`-Hook oder JSON-Datei)
  erhalten bleiben.
- Der `composer.register_type`-Mechanismus für "Werte aus Live-Config" ließe sich in ein
  generisches lib.nvim-Modul heben: "dynamic completion source", das jedes Plugin registrieren
  kann, das Nutzer-definierte Kataloge (Templates, Snippets, Presets) hat.

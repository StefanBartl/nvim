# Ökosystem-Review: viele kleine Tasks (2026-09-23)

**Handover-Datei — wird laufend aktualisiert, während die Punkte umgesetzt
werden.** Status-Spalte pro Punkt unten in der Übersicht; Details-Abschnitte
bleiben als Analyse stehen, bekommen aber einen "Umgesetzt"-Absatz sobald
erledigt.

**Stand 2026-09-23, Fortsetzung nach Zuruf.** 10/15 committed + gepusht
(siehe Häkchen unten, je mit Commit-Hash im "Umgesetzt"-Absatz). Punkt 7s
manuelle Sichtprüfung (Wrap-Verhalten von `<M-j>`/`<M-k>` im Insert-Mode)
steht laut vorherigem Stand noch aus — Weiterarbeit an Punkt 8ff. wurde
trotzdem freigegeben; Punkt 7 selbst bleibt unverändert `[x]` (Code steht,
nur die Sichtprüfung ist ein separates, unabhängiges To-Do für dich).
Punkte 8–14 (images.nvim, buffer-ctx.nvim fm/browser, pickers.nvim-Keymaps
+ Git-Status-Marks, `:Insert`-Cross-Plugin-Shims, `:MyPlugins`
nvim-config+fetch, lsp.nvim-Breadcrumb) werden jetzt nacheinander
umgesetzt, ein Punkt pro Agent-Runde. Punkt 15 (Audit-Task) ist bereits als
eigene Aufgabe formuliert, nicht Teil dieser Umsetzungs-Reihenfolge.

Analyse + Umsetzungsplan für die Sammlung an kleinen Tasks aus der Session
vom 2026-09-23, quer über `gopath.nvim`, `images.nvim`, `pickers.nvim`,
`buffer-ctx.nvim`, `fileops.nvim`, `filetree.nvim`, `lsp.nvim`, `ui.nvim`
und die nvim-config selbst. Jeder Punkt wurde im echten Quellcode verortet
(Datei + Zeile), nicht nur aus der Beschreibung geraten.

Der zugehörige Cross-Cutting-Task "Workflows" (interaktive Bestätigung statt
Notify-mit-Anleitung) hat eine eigene Datei:
[`Final_Checks/workflows-interactive-confirm.md`](../personal/All/FINISH/Final_Checks/workflows-interactive-confirm.md).

## Klärungen (2026-09-23, zweite Runde)

- **Breadcrumbs (Punkt 14):** ist `lsp.nvim`s Winbar-Breadcrumb
  (`lua/lsp/core/winbar/render.lua`), nicht `filetree.nvim` oder `my.nvim`.
  Bestätigt.
- **Punkt 10/12 (pickers.nvim-Keymaps, Git-Status-Marks):** Empfehlung aus
  dieser Datei übernommen — `pickers.nvim`-Builtin, nicht `ui.nvim`.

---

## Umsetzungsplan (Reihenfolge)

Sortiert nach Aufwand/Risiko, nicht nach Wunsch-Priorität — die Reihenfolge
ist ein Vorschlag, keine Verpflichtung, einzeln umsetzbar/verschiebbar.

Status: `[ ]` offen · `[~]` in Arbeit · `[x]` fertig (committed+pushed).

### Phase 1 — Isolierte Ein-Datei-Fixes (je < 1h, keine Designfrage offen)

1. [x] **buffer-ctx.nvim** — `$REPOS_DIR`-rooted `:Copy`/`:Insert filepath`-Modus
2. [x] **pickers.nvim** — `oldfiles`-Builtin auf `<leader>fo` freilegen
3. [x] **fileops.nvim** — `:File delete` bei ungespeicherten Änderungen: Confirm statt Notify (Workflows-Instanz #1)
4. [x] **nvim-config** — `:MyPlugins`' `confirm.lua`: `ui.kit.confirm` statt `getcharstr()`+`print()` (Workflows-Instanz #2)

### Phase 2 — Einzelrepo, klare Lösung, eine Designentscheidung nötig

5. [x] **gopath.nvim** — Alternate-Picker abbrechen fällt jetzt auf Create-Offer zurück
6. [x] **gopath.nvim** — neuer Eintrittspunkt „im Filetree öffnen/fokussieren" (deckt sowohl `gF`-auf-Markdown-Bild als auch die separat gewünschte `:Filetree open **`-Idee ab)
7. [x] **nvim-config** — `gj`/`gk` im Insert-Mode via `<C-`-Kombination (Konflikt-Check zuerst) — **manuelle Sichtprüfung empfohlen, siehe unten**

### Phase 3 — Neue kleine Subsysteme

8. [x] **images.nvim** — `:Images paste [path=...]` + `ui.kit.select`-Abfrage (relativ/absolut/`$REPOS_DIR`/custom)
9. [x] **buffer-ctx.nvim** — `<leader>fm`-Äquivalent (im Dateimanager öffnen) + im Browser öffnen
10. [x] **pickers.nvim** — filetree.nvim-Keymaps (`[a`, `ML`, …) in der Ergebnisliste (Telescope + fzf-lua)

### Phase 4 — Größer, braucht eigenen Design-Pass

11. [x] **buffer-ctx.nvim** — `:Insert`/`:Copy` cross-plugin "shimmed providers" (z. B. `images.nvim`s `paste`)
12. [x] **pickers.nvim** — neuer Builtin: Marks-artige Liste, gefiltert auf Git-Status (uncommitted/staged/unstaged, umschaltbar) — Ort geklärt: `pickers.nvim`, nicht `ui.nvim` (siehe Klärungen oben)
13. [ ] **nvim-config `:MyPlugins`** — nvim-config selbst im Dashboard zeigen, `fetch`/`fetchThis`-Optionen beim Öffnen
14. [ ] **lsp.nvim** — Winbar-Breadcrumb rechtsbündig (Ort geklärt: `lua/lsp/core/winbar/render.lua`) + Underline-Test ohne feste Abgrenzung

Ein separater, expliziter Folge-Task (wie angefragt) — **nicht Teil dieser
Implementierungs-Reihenfolge**, bereits als eigener Task formuliert:

15. **Audit-Task** — "Vorschlag ablehnen ⇒ trotzdem ursprüngliche Aktion möglich" systematisch für alle Bindings prüfen (nicht nur `gF`) — siehe [`Final_Checks/workflows-interactive-confirm.md`](../personal/All/FINISH/Final_Checks/workflows-interactive-confirm.md)

---

## Details je Punkt

### 1. buffer-ctx.nvim: `$REPOS_DIR`-Pfad-Modus

**Fund:** `B:\repos\buffer-ctx.nvim\lua\buffer_ctx\ops\filepath.lua` hat bereits drei Modi
(`abs`, `nvim` [relativ zu `stdpath("config")`], Default [relativ zu cwd]).
Der `"nvim"`-Zweig ist exakt die Vorlage: `stdpath("config")` durch
`vim.env.REPOS_DIR` ersetzen, gleiche Present-Falls-unset-Fallback-Logik wie
die bestehenden Modi.

Ergänzt `:CopyFilepathAbsolute`/`:CopyFilepathRelative` (`commands.lua:501-505`)
um ein drittes Compat-Kommando, z. B. `:CopyFilepathRepos` →
`:Copy filepath repos`, plus `:Insert filepath repos`.

**Aufwand:** klein. **Risiko:** keins (neuer, additiver Modus).

**Umgesetzt (2026-09-23):** `mode="repos"` in `ops/filepath.lua`, Token
`repos`/`reposdir` in `parse_args`, `:CopyFilepathRepos`-Compat-Kommando,
Typ `BufferCtx.FilepathMode` erweitert, `docs/commands.md`/`BINDINGS.md`/
`doc/buffer-ctx.txt`/`health.md` + `health.lua`-Check aktualisiert,
`lazy.nvim`'s `cmd`-Liste in `plugins/personal/init.lua` ergänzt (sonst wäre
der Compat-Befehl vor dem ersten `Copy`/`Insert`/… nicht registriert
gewesen). Test in `TESTS/ops_edge_spec.lua` (innerhalb `$REPOS_DIR`,
außerhalb → cwd-Fallback, `$REPOS_DIR` unset → Error). luacheck/stylua
grün, volle Suite grün. Commit `buffer-ctx.nvim@3d3e657`.

### 2. pickers.nvim: `oldfiles` auf `<leader>fo`

**Fund:** `oldfiles` existiert bereits als Builtin
(`pickers/builtins/init.lua:66-67`, sowohl `telescope` als auch `fzf`
verdrahtet). Es fehlt nur die Bindung — analog zu den anderen
`<leader>f*`-Einträgen in `pickers/bindings/keymaps.lua`.

**Aufwand:** trivial.

**Umgesetzt (2026-09-23):** doch kein Code-Change in `pickers.nvim` nötig —
`pickers/mappings/init.lua` hatte bereits genau die richtige Erweiterung
("declarative mappings", jeder `pickers.builtins`-Name dispatchbar) und wird
in `pickers/bindings/init.lua:31` unbedingt aus `setup()` heraus aufgerufen.
Nur `mappings = { recent = { "<leader>fo" } }` in der pickers.nvim-Spec in
`plugins/personal/init.lua` ergänzt (Registry-Name ist `recent`, nicht
`oldfiles` — so heißt der Builtin bei snacks; telescope/fzf-lua nennen ihn
intern `oldfiles`, aber der `pickers.builtins`-Eintrag selbst `recent`).
luacheck/stylua grün. Commit `nvim-config@c8f24a1c`.

### 3. fileops.nvim: `:File delete` + ungespeicherte Änderungen

**Fund:** `B:\repos\fileops.nvim\lua\fileops\ops\file.lua:745-747`:

```lua
if vim.bo[b].modified and not opts.force then
  return false, "buffer has unsaved changes — use :File! delete to delete and force-close"
end
```

Reiner Return-Error, landet vermutlich als `notify.error(...)` beim Aufrufer
(`bindings/usrcmds.lua:576-592`). `ui.kit` ist in fileops.nvim bereits
Soft-Dependency und wird an anderer Stelle für genau so einen Zweck benutzt
(`usrcmds.lua:457`, Bulk-Rename-Bestätigung). `health.lua:50-52` nennt "the
modified-buffer confirm" sogar schon als erwarteten Health-Punkt — die
Erwartung war also schon da, nur nicht für `delete` verdrahtet.

Gleiches Muster (Notify-mit-Anleitung statt Confirm) auch bei
`destination already exists (use ! to overwrite)` — zweimal in
`ops/file.lua:413,557` (rename/move/copy/duplicate).

**Fix:** In `usrcmds.lua`'s `delete`-Branch: bei `modified`-Fehler
`ui.kit.confirm({question="Buffer hat ungespeicherte Änderungen — trotzdem
löschen (force-close)?", choices={"Ja, löschen","Abbrechen"}})` statt
direkt zu scheitern; bei Bestätigung mit `opts.force=true` erneut aufrufen.
Gleiches für die `!`-Overwrite-Fälle.

**Aufwand:** klein–mittel (Fallback auf `vim.ui.select` wenn `ui.nvim` fehlt,
analog zu `gopath.create.ask()`).

**Umgesetzt (2026-09-23):** `ui.kit.confirm` direkt (kein `vim.ui.select`-
Fallback — passt zum bestehenden Stil in diesem Repo: `ui.kit` wird schon
an anderer Stelle ungeguardet aufgerufen, `health.lua` nennt es explizit
als benötigte Abhängigkeit für genau diese Prompts). Sowohl `:File delete`
als auch die `delete`/`delete_force`-Keymaps abgedeckt — letztere hatten
bisher eine **eigene, parallele** Delete-Implementierung
(`bindings/keymaps.lua`), die meinen ersten Fix in `usrcmds.lua` komplett
umgangen hätte. Beide Stellen jetzt auf ein gemeinsames
`bindings/delete_confirm.lua` gezogen (vorher schon per Kommentar als
"mirroring" markiert, aber tatsächlich bereits auseinandergelaufen — die
Keymap-Kopie ignorierte `delete.mode` komplett und rief `on_before_delete`
nie auf). Gleiche Behandlung auch für die `!`-Overwrite-Fälle bei
rename/move/duplicate/copy (`run_with_overwrite_confirm`-Helper). Zwei
bestehende Tests (`usrcmds_dispatch_spec.lua`, `keymaps_spec.lua`) testeten
noch das alte "refuse"-Verhalten — auf das neue Confirm-Verhalten
umgeschrieben, nicht nur ergänzt. luacheck/stylua grün, volle Suite grün
(932 Checks). Commit `fileops.nvim@0902912`.

### 4. `:MyPlugins` Confirm-Dialog

**Fund:** [`bindings/usrcmds/plugin_repos/confirm.lua`](../../../lua/bindings/usrcmds/plugin_repos/confirm.lua)
liest Tasten direkt per `vim.fn.getcharstr()` und druckt den Prompt via
`print()` — das ist exakt das "wird als `more`-Notify angezeigt"-Verhalten,
das gemeint war. `ui.kit.confirm` ist im selben Ökosystem längst Standard
(siehe gopath.nvim, fileops.nvim, filetree.nvim).

**Fix:** `M.yesno(msg, yes_label)` durch einen `ui.kit.confirm`-Aufruf
ersetzen (Fallback `vim.ui.select`, falls `ui.nvim` fehlt — unwahrscheinlich,
da `ui.nvim` bereits `lazy=false` in der Config lädt, aber der Soft-Dep-Stil
sollte konsistent bleiben). Jede Aufrufstelle von `confirm.yesno(...)`
bleibt unverändert (`ops.lua`/`init.lua`), nur die Interaktion ändert sich.

**Aufwand:** klein.

**Umgesetzt (2026-09-23):** `M.yesno` ist jetzt callback-basiert
(`cb(accepted)` statt Rückgabewert) — `ui.kit.confirm` ist asynchron, das
alte `if not confirm.yesno(msg) then return end` ließ sich nicht 1:1
übernehmen. **Drei** statt zwei Aufrufstellen gefunden (die dritte, in
`picker.lua:231`, hatte mein erster Grep in der Analyse-Phase übersehen —
gehört zur Batch-Aktion des Pickers). Bei `finish_reclone` (`init.lua`) mit
Bedacht umgebaut: dort läuft nach einer Ablehnung weiterhin der
"nur die fehlenden Plugins klonen"-Zweig — als eigene `continue_with()`-
Funktion extrahiert, sowohl vom Confirm-Callback als auch direkt (wenn gar
nichts zu bestätigen ist) aufgerufen, damit dieses Verhalten exakt erhalten
bleibt. luacheck/stylua grün; kein automatisierter Test möglich/vorhanden
für dieses Repo (keine Test-Infrastruktur für die persönliche Config, UI-
Interaktion). Commit `nvim-config@c4a3709c`.

### 5. gopath.nvim: Alternate-Picker-Abbruch blockiert Create-Offer

**Fund:** Genau der Screenshot-Fall. `gopath/commands.lua:34-55` (`finish_open`):
bei `res.exists == false` wird zuerst `alternate.try_resolve()` versucht
(zeigt "did you mean 00_toCustomer.md?"). In
`B:\repos\gopath.nvim\lua\gopath\alternate\init.lua:53-75`
meldet `present()` bei Abbruch der Auswahl **`on_done(true)`** — "handled"
— wodurch `finish_open`s `if handled then return end` das nachgelagerte
`open_for_kind(res, kind)` (und damit `gopath.create.offer()`, den
Create-Dialog) nie erreicht. Das ist keine Nebenwirkung, sondern eine
bewusste, dokumentierte Entscheidung (Kommentar Zeile 58-62: "Cancelling
means 'none of these'... chaining a second dialog onto a dismissed one is
exactly what the user said no to.") — die inzwischen aber genau dem
widerspricht, was jetzt gewünscht ist: Ablehnen der Alternativen ist NICHT
dasselbe wie Ablehnen der Dateierstellung.

**Fix:** In `present()`s `on_choice`, im Cancel-Zweig (`not (match and
match.path)`) `on_done(false)` statt `on_done(true)` — dadurch fällt
`finish_open` korrekt auf `open_for_kind` → `gopath.open` →
`res.exists==false` → `create.offer()` durch. Race-Risiko aus dem
ursprünglichen Kommentar (zweiter Dialog stapelt sich auf den noch offenen
Picker) betrifft nur den *asynchronen* Fall vor Abschluss der Auswahl, nicht
den Moment NACH einem echten Cancel — bleibt also unberührt.

**Aufwand:** eine Zeile, aber verdient einen expliziten Test
(`gopath.nvim/TESTS/`, falls vorhanden) für: Alternates gefunden + Cancel ⇒
Create-Offer erscheint; Alternates gefunden + Auswahl ⇒ kein Create-Offer.

**Umgesetzt (2026-09-23):** `on_done(true)` → `on_done(false)` im
Cancel-Zweig von `alternate/init.lua`s `present()`, plus die `@param
on_done`-Doku an beiden öffentlichen Funktionen (`try_resolve`/
`try_resolve_with_matches`) korrigiert. `docs/resolution.md`s
"dismissing counts as handled"-Absatz umgeschrieben. Bestehender Test
`scripts/ci/specs/alternate_spec.lua` testete explizit das ALTE Verhalten
("cancelling counts as handled") — umgeschrieben, nicht nur ergänzt.
luacheck grün, alle drei CI-Runner grün (unit: 468 Checks/1696 Assertions,
functional, headless). Commit `gopath.nvim@4843133`.

### 6. gopath.nvim: "im Filetree öffnen" als eigener Eintrittspunkt

**Fund:** Die Bausteine existieren fast komplett schon:
`gopath/create.lua:135-167` (`filetree_adapter()` + `open_in_filetree()`)
wird heute nur intern für den "nearest existing ancestor directory"-Zweig
des Create-Dialogs benutzt. `gM` (`bindings/keymaps.lua:67`) reveal't
stattdessen im **OS**-Dateimanager, nicht in filetree.nvim.

**Fix:** Neuer Modus (`gopath open filetree` / `:Gopath open filetree`,
Keymap frei wählen) der `RESOLVE.resolve_at_cursor()` wie gewohnt aufruft,
aber statt `OPEN.open()` den Pfad via `filetree.adapter().open_reveal(path)`
im Baum fokussiert. Deckt beide Screenshot-Wünsche ab: den `<CR>`-auf-
Markdown-Bild-Fall und den separat notierten `:Filetree open **`-Wunsch —
letzterer braucht keinen eigenen filetree.nvim-Befehl, `open_reveal` ist
schon da (`filetree/@types/adapter.lua:30`).

**Aufwand:** klein–mittel (neue Route, kein neuer Unterbau).

**Umgesetzt (2026-09-23):** neuer Modus `"filetree"` (analog zum
bestehenden `"explorer"` = OS-Dateimanager), Default-Key `gT`
(`mappings.open_filetree`), Usercmd `:Gopath open filetree` /
`:GopathOpen filetree`. Ruft `filetree.adapter().open_reveal(path)` — läuft
durch dieselbe Resolve-Pipeline wie jeder andere Open-Modus (Fuzzy-
Alternate, Tailsearch, `:line:col`), warnt statt zu fehlern wenn
filetree.nvim fehlt/nicht gesetzt ist (kein Create-Offer, wie bei `gM`).
`gopath.util.filetree` als neues gemeinsames Modul für die
Adapter-Auflösung (vorher nur intern in `create.lua`, jetzt von `open/
init.lua` mitbenutzt statt einer zweiten Kopie). In der eigenen Config
kein Override nötig — `open_filetree` war bei den überschriebenen
Mappings nicht dabei, `gT` greift automatisch als Shipped-Default.
luacheck grün, alle drei CI-Runner grün (unit: 470 Checks/1702
Assertions). Commit `gopath.nvim@e58fb73`.

### 7. `gj`/`gk` im Insert-Mode

**Fund:** `gj`/`gk` sind natives Vim (Bildschirmzeile statt Textzeile), in
dieser Config bereits auf `<C-S-j>`/`<C-S-k>` gelegt
(`bindings/mappings/screen_line.lua:22-23`, Normal+Visual). `<C-j>`/`<C-k>`
sind in Normal-Mode bereits belegt (Fenster-Navigation, siehe
`BINDINGS-RUNTIME-CHECKLIST.md:97-100`) — **im Insert-Mode aber nicht
zwangsläufig frei.**

**Vor der Umsetzung zu prüfen:** ob `<C-j>`/`<C-k>` im Insert-Mode von
`blink.cmp`/Copilot/Snippet-Jump für "nächster/vorheriger
Completion-Eintrag" beansprucht sind (sehr verbreitete Konvention) — genau
das "sofern nichts dagegen spricht" aus der Anfrage. Falls belegt: anderes
Tastenpaar wählen (z. B. `<C-Down>`/`<C-Up>`, die laut Checkliste frei sind).

**Fix (wenn frei):** `map("i", "<C-j>", "<C-o>gj", ...)`,
`map("i", "<C-k>", "<C-o>gk", ...)` — `<C-o>` führt einen Normal-Mode-Befehl
aus, ohne den Insert-Mode zu verlassen.

**Aufwand:** trivial, aber Konflikt-Check zuerst nicht überspringen.

**Umgesetzt (2026-09-23):** Konflikt-Check ergab: `<C-j>`/`<C-k>` sind im
Insert-Mode tatsächlich schon belegt — aber auf reine `<Down>`/`<Up>`
(`bindings/mappings/general.lua:102-103`), nicht auf Completion-Navigation.
Empirisch geprüft (headless, `nvim_input`): Insert-Mode-`<Down>`/`<Up>`
bewegen sich per **Textzeile**, nicht Bildschirmzeile — also kein
gj/gk-Äquivalent, aber ähnlicher Zweck. Rückfrage an dich ergab: `<M-j>`/
`<M-k>` verwenden. Die waren zwar in der ersten Grep-Runde nicht geprüft,
aber `screen_line.lua`s eigener Kommentar hatte sie schon als "free ...
portable fallback" vorgemerkt — passt. `<A-j>`/`<A-k>` (Noice LSP-Scroll)
kollidieren nicht: buffer-lokal, nur in Noice-eigenen Floats aktiv.

Implementiert in `bindings/mappings/screen_line.lua`:
`map("i", "<M-j>", "<C-o>gj", ...)`, `map("i", "<M-k>", "<C-o>gk", ...)`.
luacheck/stylua grün. **Nicht abschließend headless verifizierbar** — der
eigentliche Bildschirmzeilen-Umbruch (`gj`/`gk` bei `wrap=true`) hängt von
echter Fenstergeometrie ab, die ein reines `--headless` ohne angehängte UI
nicht zuverlässig berechnet (gleiches Problem wie schon bei
`filetree.nvim`s `cursor_hide`-Feature in dieser Session). Der
Keymap-Mechanismus (`<C-o>` + Multi-Key-Motion) selbst ist Standard-Vim-
Idiom, aber bitte einmal von Hand testen (langer Absatz, `wrap` an, im
Insert-Mode `<M-j>`/`<M-k>` drücken).

**Fund:** `B:\repos\images.nvim\lua\images\paste.lua:204-223`
(`target_paths`) berechnet `rel` hart als Pfad relativ zum Dokument — keine
Option für absolut/`$REPOS_DIR`/custom, weder als Config noch als
Kommando-Argument.

**Fix:** `:Images paste [path=relative|absolute|repos|<custom-prefix>]` als
neues Argument in `bindings/usrcmds.lua:142-146`; ohne Argument und ohne
festen Default in der Config: `ui.kit.select`-Abfrage mit den vier Optionen
(gleiche Idee wie `filetree.nvim`s `path_copy`-Feature, das `dot_relative`/
`env_rooted`/`absolute` bereits als fertige, getestete Pfad-Transformationen
hat — `TESTS/units.lua` "path.dot_relative"/"path.env_rooted" in
filetree.nvim zeigen die Referenzlogik).

**Aufwand:** mittel (neue Pfad-Transformation + Argument-Parsing +
UI-Abfrage, aber jede Zutat hat schon eine Vorlage in einem Schwester-Plugin).

**Umgesetzt (2026-09-23):** `path=relative|absolute|repos|<prefix>` als
bare `key=value` (kv, kein `--flag`) auf der `paste`-Route in
`bindings/usrcmds.lua` — exakt das schon etablierte Muster aus
`media.nvim`s `:Media dashboard path=<dir>` (`kv = { { key = "path", type =
"STRING", values = {...} } }`), nicht händisch geparst. Eine wichtige
Klarstellung gegenüber dem ursprünglichen Fund: der Modus verändert nur den
**String im eingefügten Markdown-Link**, niemals den tatsächlichen
Speicherort der Datei (bleibt immer `paste.dir`/ein vorhandener
Resource-Ordner neben dem Dokument, wie vorher) — neue reine Funktion
`images.paste.resolve_link_path(abs, doc_rel, mode)` in `paste.lua`, von
`target_paths` aufgerufen. `mode="repos"` übernimmt exakt Punkt 1s
Fallback-Logik aus `buffer-ctx.nvim/ops/filepath.lua` (innerhalb
`$REPOS_DIR` → Prefix strippen, außerhalb → Fallback auf den
dokument-relativen Pfad, `$REPOS_DIR` unset → Error). Ein nicht erkannter
Wert wird nicht validiert/abgelehnt, sondern wörtlich als Custom-Prefix vor
den dokument-relativen Pfad gesetzt (`path=/static/img` →
`/static/img/assets/shot-1.png`).

Eine bewusste Abweichung vom wörtlichen Fix-Text: statt "kein fester
Default gesetzt ⇒ immer fragen" bekommt `paste.default_path_mode` einen
sinnvollen eingebauten Default (`"relative"`, exakt das Verhalten von
vorher) statt `nil`/unset — sonst hätte jeder bestehende `:Image
paste`/`<leader>iv`-Aufruf nach diesem Update plötzlich eine interaktive
Abfrage bekommen, im Widerspruch zum Plugin-eigenen Leitmotiv ("screenshot,
one keypress, done", so explizit in `paste.lua`s Moduldoc). `false` ist
jetzt das Opt-in-Signal für "frag mich jedes Mal" (gleiche
`false`-schaltet-ab-Konvention wie bei den Keymap-Optionen). `:Image
screenshot` bleibt bewusst außen vor (pinned auf `"relative"`, kein
`path=`-Argument dafür angefragt) — kein Scope-Creep in einen Befehl, der
gar nicht Teil der Aufgabe war.

`ui.kit.select`-Abfrage (vier Optionen: relativ/absolut/`$REPOS_DIR`/Custom)
mit `vim.ui.select`-Fallback nach dem etablierten
`pcall(require, "ui.kit")`-Muster von `images.paste.kit()`; "custom
prefix…" öffnet einen zweiten Prompt (`ui.kit.input`/`vim.fn.input`) für den
literalen Prefix. Config-seitig gab es noch kein Default-Mode-Feld — neu
ergänzt: `paste.default_path_mode` (DEFAULTS.lua, KNOWN-Schema in
`config/init.lua`, `@types/init.lua`).

Tests in `TESTS/paste_target_spec.lua` (neue Abschnitte 5-7: `resolve_link_path`
pur für alle vier Modi inkl. `$REPOS_DIR` unset/außerhalb, End-to-end über
`paste_with_name` — Datei bleibt in `assets/`, nur der Link ändert sich —,
und `resolve_path_mode`: expliziter Arg gewinnt, konfigurierter Default
überspringt die Abfrage nachweislich [`vim.ui.select` wirft, wenn
aufgerufen], `default_path_mode=false` fragt via gestubtem `vim.ui.select`,
"custom" fragt ein zweites Mal via gestubtem `vim.fn.input`, Abbruch ⇒ nil)
sowie `TESTS/usrcmds_spec.lua` (kv-Parsing von `path=...`, kombiniert mit
`name`, unbekannter Wert bleibt Custom-Prefix). luacheck (0
Warnings/Errors, `lua/`+`plugin/`+`scripts/`+`TESTS/`) und stylua (`--check`
grün) für alle geänderten/neuen Dateien. Volle Suite headless grün bis auf
zwei bereits vor dieser Änderung fehlschlagende, umgebungsabhängige Specs
(`capability_spec.lua`, `guard_spec.lua`, beide zu Terminal-Capability-
Erkennung, nichts mit `paste`/Pfaden zu tun — vor dieser Änderung per `git
stash` gegengeprüft: identischer Fehlschlag). Docs aktualisiert:
`docs/commands.md`, `docs/configuration.md` (neuer Abschnitt
`paste.default_path_mode` / `:Image paste path=...`), `docs/BINDINGS.md`,
`doc/images.txt` (Befehlssyntax, Config-Beispiel, Prosa-Abschnitt,
`images.paste()`-API-Signatur). Kein neues Usercmd, kein neuer
Lazy-`cmd`-Eintrag nötig (`path=` ist ein Argument auf der bestehenden
`:Image`-Route, `cmd = { "Image" }` deckt das schon ab). Commit
`images.nvim@4a79085`.

### 9. buffer-ctx.nvim: Datei-Manager/Browser öffnen

**Fund:** buffer-ctx.nvim hat aktuell **keine** entsprechende Funktion
(Grep nach `leader.*fm`/`file.?manager`/`browser` liefert nichts). Vorlage:
`B:\repos\filetree.nvim\lua\filetree\features\system\open_in_fm\init.lua`
(Default-Key `<leader>fm`, nutzt `lib.nvim.cross.reveal_in_fm` — dieselbe
Funktion, die auch `gopath.external.helpers.revealer` schon nutzt). Für
"im Browser öffnen" gibt es vermutlich `open.nvim` als fertigen Kandidaten
(nicht tief geprüft — `open.nvim`s eigentlicher Zweck).

**Fix:** neues `ops/reveal.lua` in buffer-ctx.nvim, das für den aktuellen
Buffer denselben `lib.nvim.cross.reveal_in_fm`-Call macht wie filetree.nvim,
plus einen zweiten Fall, der an `open.nvim` (falls installiert) oder einen
minimalen `vim.ui.open`-Fallback delegiert.

**Aufwand:** klein–mittel.

**Umgesetzt (2026-09-23):** neues, in sich geschlossenes Subsystem
`buffer_ctx.reveal` (`lua/buffer_ctx/reveal/init.lua`, analog zu `mark`/
`format`), plus die eigentliche Dispatch-Logik in
`lua/buffer_ctx/ops/reveal.lua` (`M.fm()`, `M.browser()`, beide mit
`(ok, err)`-Rückgabe statt Text-Rückgabe — anders als jeder andere
`ops/*`-Getter, weil hier ein externer Prozess der eigentliche "Wert"
ist). Zwei eigenständige Kommandos statt eines `:Reveal {subcmd}`-
Composer-Verbs, weil beide Aktionen argumentlos sind und keinen
gemeinsamen Zustand teilen — eine Subcommand-Routing-Schicht hätte
nichts zu routen gehabt: `:RevealInFm` und `:OpenInBrowser`, registriert
über `lib.nvim.bindings.usercmd` (nicht den Composer), exakt das Muster
der bestehenden Compat-Kommandos (`:CopyFilepathAbsolute`,
`:MarkLineToggle`).

`open.nvim` ist im Ökosystem bereits vorhanden (`StefanBartl/open.nvim`,
in `plugins/personal/init.lua` mit `cmd = { "Open", "UrlView",
"MDLinksView" }`) und hat einen fertigen `browser`-Handler
(`open/handlers/browser.lua`) plus eine öffentliche Lua-API
(`require("open").open(target, scope)`). `:OpenInBrowser` delegiert
dorthin mit explizitem Target+Scope (`require("open").open("browser",
"%")`) — dadurch läuft open.nvims eigene No-Target-Heuristik (Tree-Node/
`<cfile>`/`<cWORD>`/…) gar nicht erst an, und dessen opt-in Picker (der
nur bei fehlendem Target eingreift) bleibt außen vor. Ohne `open.nvim`
fällt `M.browser()` auf `vim.ui.open` zurück (Neovim 0.10+). `open.nvim`
ist als Soft-Dep über `pcall(require, "open")` eingebunden, exakt das
`resolve_kit()`-Muster aus `commands.lua:37-47`, das die Aufgabe als
Vorlage nannte.

Keymap-Entscheidung: **nicht** `<leader>fm` — der Check in
`BINDINGS-RUNTIME-CHECKLIST.md` (unter diesem Pfad liegt das, was die
Aufgabe als "docs/NOTES/BINDINGS" bezeichnete; eine Datei exakt an
diesem Pfad existiert nicht) zeigte `<leader>fm` bereits doppelt belegt
("[General] Format file" und "[lsp] Format markdown buffer", Zeilen
150/309) — eine echte globale Kollision, kein bloßer Buffer-lokal-vs-
global-Sonderfall wie bei filetree.nvims eigenem `<leader>fm` (das nur
in Tree-Buffern aktiv ist und daher ungefährlich gewesen wäre). Das
gesamte `<leader>o*`-Präfix war dagegen ökosystemweit komplett frei —
gewählt: `<leader>of` (open → file manager) und `<leader>ob` (open →
browser), beide neu in `buffer_ctx.reveal`s `reveal.keymaps`-Config
(Default gesetzt, analog zu `mark.keymaps`).

Config: neuer Abschnitt `reveal = { enable = true, keymaps = { fm =
"<leader>of", browser = "<leader>ob" } }` in `DEFAULTS.lua`, `KNOWN`-
Validierung in `config/init.lua`, `BufferCtx.RevealConfig`-Typ in
`@types.lua`, Wiring in `init.lua` (gleiches `mark`/`format`-Muster:
eigener `enable`-Gate, sowohl im Aufrufer als auch nochmal in
`reveal/init.lua`s `setup()` selbst).

Beim Ergänzen der `health.lua`-Sektion für `reveal` fiel eine echte
Regression im **bestehenden** Code auf: die `mark`-Sektion hatte bisher
ein frühes `return` im "disabled"-Zweig, weil sie bis dahin die letzte
Sektion in `M.check()` war — nach dem Anhängen der neuen `reveal`-
Sektion DAHINTER hätte das `return` deren komplette Ausgabe verschluckt,
sobald `mark = false` gesetzt ist (auch wenn `reveal` selbst aktiv
bleibt). Gefixt: sowohl `mark`s als auch `reveal`s "disabled"-Zweig
fallen jetzt durch statt früh zurückzukehren. Regressionstest dafür in
`TESTS/config_spec.lua` (stubbt `vim.health.start`, prüft dass die
`"buffer_ctx.reveal"`-Sektion bei `mark = false` trotzdem aufgerufen
wird).

Tests in neuem `TESTS/reveal_spec.lua`: Pfad-Auflösung/Dispatch-Logik
von `ops.reveal.fm()`/`.browser()` (unbenannter Buffer, `lib.nvim.cross.
reveal_in_fm` erfolgreich/fehlschlagend/fehlend, `open.nvim` erfolgreich/
fehlschlagend/fehlend mit `vim.ui.open`-Fallback, `vim.ui.open` selbst
fehlend) — der externe Seiteneffekt selbst (tatsächliches Öffnen eines
Fensters) wird nirgends ausgeführt, alle drei Abhängigkeiten sind
gestubt (`package.loaded`/`package.preload`-Swap für "Modul fehlt",
`vim.ui.open` direkt überschrieben für den Fallback-Pfad). Plus
Registrierungs-Check für `buffer_ctx.reveal.setup()` (Usercmds
vorhanden, `enable = false` ist No-Op). luacheck (0/0 über den ganzen
`lua`/`TESTS`/`plugin`-Baum) und stylua `--check` grün, volle Suite
headless grün (12/12 Specs). Docs aktualisiert: `docs/commands.md`,
`docs/BINDINGS.md`, `doc/buffer-ctx.txt` (TOC neu nummeriert, neuer
Abschnitt 8, Requirements/Keymaps/Health/Architecture ergänzt),
`docs/health.md`, `docs/configuration.md`, `docs/keymaps.md`,
`docs/architecture.md`, `docs/installation.md`, `docs/CONTRIBUTING.md`,
`docs/FEATURES/README.md` + neue `docs/FEATURES/REVEAL.md`.
`plugins/personal/init.lua`s buffer-ctx.nvim-Spec um die zwei neuen
Usercmds (`cmd`-Liste, für Lazy-Loading) und die zwei neuen Keymaps
(`keys`-Liste) ergänzt. `BINDINGS-RUNTIME-CHECKLIST.md` bewusst **nicht**
angefasst: es ist laut eigenem Kopfkommentar generiert
(`bindings.audit.checklist_lines`) und scannt offenbar nur nvim-configs
eigene `bindings/`-Module, nicht von Plugins selbst zur Laufzeit
registrierte Keymaps — buffer-ctx.nvims bereits bestehende Keys
(`<leader>cnl`/`<S-m>`/`<C-p>`) fehlen dort aus demselben Grund
ebenfalls. Commit `buffer-ctx.nvim@cd57c10`.

### 10. pickers.nvim: filetree.nvim-Keymaps in der Ergebnisliste

**Fund:** Beide Engines (`telescope.lua`, `fzf.lua`) haben bereits ein
`actions`-System pro Picker (`engines/telescope.lua` nutzt
`attach_mappings`, `engines/fzf.lua` ein eigenes `actions`-Table). Es gibt
noch keinen Cross-Link zu filetree.nvim.

**Empfehlung:** nicht ALLE filetree.nvim-Keymaps 1:1 übernehmen (viele
ergeben in einer Ergebnisliste keinen Sinn, z. B. `m`/Marks, `d`/Trash),
sondern gezielt die Pfad-Copy-Familie (`[a`, `]a`, `[e`, `ML`) plus evtl.
`gb`("add to buffer list"-Äquivalent, falls die Engine sowas kennt). Erste
Aufgabe wäre also eine kurze Auswahl-Liste, keine blinde Kopie — siehe
Klärungsbedarf-Charakter dieses Punkts unten.

**Aufwand:** mittel (zwei Engines separat verdrahten, `[a`/`ML` selbst
implementieren statt filetree.nvim direkt zu importieren — Picker-Zeilen
sind keine `FiletreeNode`s).

**Umgesetzt (2026-09-23):** Fund korrigiert — der tatsächliche Erweiterungspunkt
ist **nicht** `engines/telescope.lua`/`engines/fzf.lua` (deren
`attach_mappings`/eigenes `actions`-Table dienen nur `pickers.nvim`s eigenen
Pickern und werden nirgends von außen gemerged), sondern das schon bestehende
`pickers.entry_actions`-System (`create_file`/`open_background`/`cheatsheet`),
das die nvim-config bereits generisch in `lua/config/telescope/init.lua`,
`lua/config/fzf/init.lua` und `lua/config/snacks/picker/init.lua` einbindet
(`entry_actions.get_mappings()`/`.get_actions()`/`.get_keys()`, jeweils
komplett gemerged) — genau dort greifen auch native Telescope/fzf-lua/snacks-
Builtins (git, buffers, …) mit, nicht nur `pickers.nvim`s eigene Finder. Neue
Aktionen dort ergänzt bedeutet: **kein** nvim-config-Change nötig, die
Defaults gelten sofort überall.

Kuratierte Auswahl wie empfohlen — vier statt fünf Keymaps: `[a`
(`copy_absolute`), `]a` (`copy_dirname`), `[e` (`copy_env_rooted`), `ML`
(`markdown_link`), exakte Formate 1:1 aus `filetree.nvim/lua/filetree/
features/paths/path_copy/init.lua` und `.../markdown_links/init.lua`
übernommen (absolute Pfad, absoluter Parent, `$REPOS_DIR`-gefalteter Pfad,
`[name](relative/path)`-Markdown-Link). `gb` ("add to buffer list, no focus
switch") bewusst **nicht** dupliziert — beim Nachlesen von
`entry_actions/adapters/telescope.lua`s eigenem Modul-Kommentar stellte sich
heraus, dass `pickers.nvim`s bereits bestehende `open_background`-Aktion
(`<S-CR>`/`<C-o>`) historisch selbst aus `open_badd` umbenannt wurde — sie IST
das `gb`-Äquivalent, eine zusätzliche Aktion wäre reine Doppelung gewesen.

**Wichtiger Design-Fund, der die Aufgabenstellung so nicht vorwegnahm:**
`[a`/`]a`/`[e`/`ML` sind reine druckbare Zeichen (anders als jede bisherige
`pickers.keys`-Aktion, die durchweg Control-/Sondertasten nutzt —
`<C-a>`/`<S-CR>`/`<C-/>`/Pfeiltasten). Im Insert-Mode des Picker-Prompts
(wo praktisch jede Suchanfrage eingegeben wird) hätte eine Bindung dort genau
diese Zeichen aus einer eingegebenen Suchanfrage geschluckt (z. B. Suche nach
einer Datei mit "ML" im Namen). Fix: alle vier Aktionen sind
**Ergebnisfenster/Normal-Mode-only** (`modes = {"n"}`, gleiche Klasse wie das
bereits bestehende `mouse_confirm`), nie im Insert-Mode gebunden — bei snacks
deshalb nur in `get_keys()` (List-Fenster, Normal-Mode), nie in
`get_input_keys()`. fzf-lua hat dazu noch einen zweiten, unabhängigen Grund:
fzfs `--bind`-Syntax kennt keine Mehrtasten-Chords wie `[a` (bindet ein
einzelnes logisches Event, keine Pending-Key-State-Machine) — daher dort feste
Einzeltasten (`ctrl-y`/`alt-y`/`alt-r`/`alt-m`, geprüft gegen fzf-luas echte
`defaults.lua` UND die nvim-config-eigenen `config/fzf/*`-Overrides auf
Kollisionen — keine gefunden; `ctrl-y` überschattet nur `git_yank_commit` in
git-spezifischen Pickern, exakt dieselbe akzeptierte Präzedenz wie
`ctrl-a`/`create_file` dort schon dubletten).

Neues, eigenständiges Modul `pickers/entry_actions/path_copy.lua` (reine
Formate + `run()` mit Register-/Notify-Seiteneffekt, testbar ohne Engine-
Stubbing) — kein bestehendes gemeinsames Pfad-Utility in `pickers.nvim`
gefunden, also nach etablierter `entry_actions/*.lua`-Konvention dieses Repos
angelegt (nicht `ops/path_copy.lua`, wie die Aufgabe als Fallback-Namen
vorschlug — `pickers.nvim` hat keinen `ops/`-Ordner, `entry_actions/` ist der
tatsächlich etablierte Ort für genau diese Art von Engine-agnostischer
Action-Logik). `copy_env_rooted` liest `pickers.config`s bereits aufgelöstes
`repos_dir` (nicht `vim.env.REPOS_DIR` direkt — Konvention laut
`config/init.lua`s eigenem Kommentar) und fällt bei unset/außerhalb auf den
reinen Absolutpfad zurück statt zu fehlern — bewusst filetree.nvims
Semantik nachgebildet, nicht buffer-ctx.nvims strengerer "repos"-Modus
(Punkt 1).

Verdrahtet in allen DREI Engines (`entry_actions/adapters/{telescope,fzf,
snacks}.lua`), nicht nur den zwei in der Aufgabe genannten — snacks
konsequent mitgezogen, weil `create_file`/`open_background`/`cheatsheet`
in genau diesem Namespace bereits alle drei Engines abdecken und eine
Zwei-von-drei-Lücke inkonsistent gewirkt hätte. `pickers.keys.adapters.
snacks`s generische `SKIP`-Liste um die vier neuen Namen ergänzt (sonst
hätte deren Fallback-Zweig sie versehentlich auch aufs Input-Fenster
gebunden — dieselbe Druckzeichen-Falle wie oben). `pickers.keys.ACTIONS`/
`ORDER`, `pickers.cheatsheet.DESCRIPTIONS`, `config/DEFAULTS.lua`,
`config/init.lua`s `NESTED_OPTS.keys` (sonst würde ein eigener Override per
ERR-50 als "unknown key" verworfen) und `keys/@types/init.lua` entsprechend
ergänzt.

Tests in `TESTS/pickers_spec.lua` (neue Suiten: reine `path_copy.build()`-
Formate inkl. `env_rooted`-Fallback-Matrix, `path_copy.run()`-Register-/
Notify-Seiteneffekt, `pickers.keys`-Resolve/Defaults/Modes, alle drei
Adapter-Bindungen inkl. "leer bei `keys.enable=false`", Cheatsheet-Zeilen
mit/ohne fzf-Override). Eine Testfalle unterwegs gefunden und korrigiert:
`vim.fn.fnamemodify("/tmp/x", ":p")` verhält sich auf diesem Windows-Devbox
für einen laufwerkslosen POSIX-Pfad je nach Anzahl der Pfadsegmente
**inkonsistent** (verifiziert direkt) — Fixtures deshalb cwd-verwurzelt statt
hart "/tmp/…" getippt. luacheck (0/0 über `lua`/`plugin`/`TESTS`) und
stylua `--check` grün. Volle Suite: 281 neue+alte Checks grün bis zu einem
**vorbestehenden**, umgebungsabhängigen Crash in der `quickfix`-Preview-Suite
(`'noautocmd' cannot be used with existing windows`, NVIM v0.11.4) — per
`git stash` gegengeprüft: identischer Crash an derselben Stelle bereits vor
dieser Änderung, nichts mit `path_copy` zu tun.

Docs aktualisiert: `docs/keymaps.md`, `docs/FEATURES/KEYS.md`, `doc/
pickers.txt` (Prosa-Abschnitt + Config-Referenz), `lua/pickers/
entry_actions/README.md`. `health.lua` bewusst unverändert — die vier neuen
Aktionen laufen über `entry_actions`, nicht über `keys.patch()`, und
erscheinen deshalb korrekterweise auch nicht in `fzf_skipped()` (exakt wie
`create_file`/`open_background`/`cheatsheet` schon vorher). Keine
nvim-config-Änderung nötig: die drei `lua/config/{telescope,fzf,snacks/
picker}/init.lua`-Module mergen `entry_actions.get_*()` bereits vollständig,
neue Aktionen dort greifen automatisch, ohne Versions-Bump oder
`plugins/personal/init.lua`-Edit (anders als Punkt 2, wo ein fehlender
Default einen `mappings`-Eintrag brauchte — hier lieferen die Shipped-
Defaults `[a`/`]a`/`[e`/`ML` bereits exakt das Gewünschte). Keine Kollision
mit bestehenden Telescope-/snacks-/fzf-lua-Defaults gefunden (`M` als
Telescope-Normal-Mode-Default kollidiert mit `ML` nur im üblichen Vim-
Chord-Sinn — Timeout-Disambiguierung, kein echter Konflikt).
`BINDINGS-RUNTIME-CHECKLIST.md` bewusst nicht angefasst: sie scannt laut
eigenem Kopfkommentar nur nvim-configs eigene `bindings/`-Module, keine zur
Laufzeit von Plugins registrierten In-Picker-Keys — dieselbe Begründung wie
bei Punkt 9, und keine der bereits bestehenden `pickers.keys`-Aktionen
(`<C-a>` etc.) taucht dort ebenfalls auf. Commit `pickers.nvim@132cf8f`.

### 11. `:Insert`/`:Copy` Cross-Plugin-Shims

**Fund:** `B:\repos\buffer-ctx.nvim\lua\buffer_ctx\commands.lua:37-47`
hat bereits exakt das richtige Muster: `resolve_kit()` prüft `ui.kit` per
`pcall(require, ...)`, re-checked bei jedem Aufruf (nicht gecacht) — "nur
shimmen wenn installiert" ist hier schon gelebte Konvention, nur eben nur
für `ui.kit`, nicht für Sister-Plugins wie `images.nvim`.

**Fix-Skizze:** `DISPATCH`-Einträge, deren Handler selbst
`pcall(require, "images")` machen und bei Erfolg `images.paste(...)`
aufrufen statt eines eigenen `ops/*`-Moduls — architektonisch identisch zu
`resolve_kit()`, nur ein anderes Zielmodul. Für "Markdown-Link-Paste" analog
mit `markdown.nvim` (Modulname prüfen — im Repo-Verzeichnis vorhanden, aber
in dieser Session nicht tief untersucht, ob ein passender öffentlicher
Einstiegspunkt existiert).

**Aufwand:** größer — das ist der Punkt, an dem sich ein generisches
"Provider-Registry"-Konzept lohnt statt N Einzel-Hacks (siehe Phase 4).
Eigener Design-Pass empfohlen, bevor Code geschrieben wird.

**Umgesetzt (2026-09-24):** Design-Entscheidung **gegen** eine generische
Provider-Registry, **für** zwei explizite Shims nach dem `resolve_kit()`-
Muster — begründet in `docs/FEATURES/CROSS_PLUGIN.md` (neu) im
buffer-ctx.nvim-Repo selbst: mit exakt zwei Sister-Plugins, die zudem
unterschiedlich scheitern (kein vs. Inline-Fallback) und an
unterschiedlicher Stelle im Kommandobaum sitzen (`markdownlink` normaler
`DISPATCH`-Eintrag unter beiden Verben, `imagepaste` `:Insert`-only außerhalb
von `DISPATCH`), hätte eine Registry-Abstraktion beide Formen von Tag eins
an abdecken müssen — für zwei Aufrufstellen, die je nur wenige Zeilen neben
dem bereits etablierten `resolve_kit()`-Muster brauchen. Genau der
"drei ähnliche Zeilen statt verfrühter Abstraktion"-Fall aus den
Projekt-Leitlinien; eine dritte, real andersartige Sister-Plugin-Integration
wäre der richtige Anlass, das nachträglich zu generalisieren.

Zwei Subcommands auf `buffer-ctx.nvim`s `:Insert`/`:Copy` ergänzt:

- **`markdownlink`** (`ops/markdown_link.lua`, neu) — wrapt denselben
  Pfad-String, den `filepath` liefern würde (identische `mode`/`format`/
  `depth`-Argumente, per direktem Aufruf von `ops/filepath.lua` statt einer
  zweiten Pfad-Auflösung), in einen Markdown-Link. Delegiert an
  `markdown.commands.markdown_links.for_paths()` — die Funktion hinter
  `:Markdown links <path>` — wenn `markdown.nvim` installiert ist (das im
  Fund genannte Modul existiert und hat einen passenden öffentlichen
  Einstiegspunkt, keine Ratearbeit nötig), fällt sonst auf das identische
  literale `"[%s](%s)"`-Format zurück (`markdown.nvim` hardcoded selbst
  exakt dasselbe Format für eine Einzeldatei — der Fallback kann also nicht
  aus dem Takt geraten). Reiner Text-Producer, passt 1:1 in die bestehende
  `DISPATCH`/`sink_text`-Pipeline, unter beiden Verben registriert.
- **`imagepaste`** (`ops/imagepaste.lua`, neu) — delegiert an
  `images.nvim`s `paste`-Feature (`require("images").paste(name, nil,
  path_mode)`, dieselbe `{name}`/`path=...`-Grammatik wie `:Image paste`
  selbst aus Punkt 8). **Kein `:Copy imagepaste`** — anders als jeder andere
  Subcommand ist `images.paste` kein Text-Producer: es liest den Clipboard
  *asynchron* und fügt den Markdown-Link direkt selbst am Cursor ein (siehe
  `images/paste.lua`s `insert_link`), exakt dieselbe "Seiteneffekt statt
  Sink-Rückgabe"-Form, die `ops/reveal.lua` (Punkt 9) für
  `:RevealInFm`/`:OpenInBrowser` schon hat. Deshalb als eigene Route nur auf
  den `:Insert`-Verb gehängt (`commands.lua`s `M.register()`, außerhalb der
  über `SUBCMDS` iterierenden `build_routes(sink)`-Schleife) statt eines
  erzwungenen `:Copy`-Gegenstücks ohne sinnvolle Bedeutung. Kein lokaler
  Fallback ohne `images.nvim` — dessen Clipboard-Lesepfad ist genuin
  plattformspezifisch (`paste.lua`s Windows/macOS/Linux-Dispatch), ihn hier
  zu duplizieren wäre exakt die Duplikation, die `ops/reveal.lua` für
  `reveal_in_fm` schon bewusst vermeidet.

`resolve_kit()`s Muster (`pcall(require, ...)`, pro Aufruf neu geprüft, nicht
gecacht) 1:1 für beide übernommen. Tests in neuem `TESTS/cross_plugin_spec.lua`
(beide `ops/*`-Module isoliert mit gestubtem/fehlendem Zielmodul, `commands.lua`s
Routing strukturell geprüft — `:Insert` hat `imagepaste`, `:Copy` nicht,
beide haben `markdownlink` —, sowie ein Ende-zu-Ende-`vim.cmd("Insert
imagepaste myshot path=absolute")`-Aufruf gegen die echte Composer-Pipeline).
luacheck (0/0 über `lua`/`TESTS`/`plugin`) und `stylua --check` grün, volle
Suite headless grün (12/12 Specs). Docs aktualisiert: `docs/commands.md`,
`docs/BINDINGS.md`, `doc/buffer-ctx.txt` (TOC + zwei neue Abschnitte 5.14/
5.15), `docs/health.md` + `health.lua` (zwei neue Soft-Dep-Checks, analog zu
`ui.kit`/`open.nvim`), `docs/installation.md`, `docs/architecture.md`,
`docs/CONTRIBUTING.md` (Ground-Rules-Ausnahme für `imagepaste` dokumentiert),
`docs/FEATURES/README.md` + `CONTEXT.md` (Querverweis) + neue
`docs/FEATURES/CROSS_PLUGIN.md`. Kein Config-Options-Change (keine neuen
Keymaps, kein `plugins/personal/init.lua`-Edit nötig — `:Insert`/`:Copy`
stehen schon in dessen `cmd`-Liste seit vor Punkt 1). Commit
`buffer-ctx.nvim@307dd67`.

### 12. ui.nvim: Git-Status-gefilterte Marks-Ansicht

**Fund:** kein bestehendes `marks`-Modul in `ui.nvim` (Grep leer). Die
existierende "Marks"-Funktion im Ökosystem ist `sessions.nvim`s
`marks`-Feature (siehe `plugins/personal/init.lua:378-387`, generische
Lesezeichen-Liste, nicht Git-Status-gefiltert). `gitsuite.nvim` hat
vermutlich schon einen `git status --porcelain`-Parser (siehe
`filetree.nvim/features/git/git_status.lua`s eigene Parser-Logik als
Referenz für das Format) — nicht geprüft, ob `gitsuite.nvim` selbst schon
eine listbare Datenquelle dafür exportiert.

**Klärungsbedarf:** Soll das eine neue `ui.kit`-Liste sein (analog
`ui.kit.select`/`picker`), die `gitsuite.nvim`s Status-Parser als
Datenquelle nutzt? Oder eher ein neuer `pickers.nvim`-Builtin (passt
architektonisch vermutlich besser, da "Liste + Aktion" genau das ist, was
`pickers.nvim` schon kann, inkl. der oben unter Punkt 10 gewünschten
filetree-Keymaps)? Empfehlung: **`pickers.nvim`-Builtin**, nicht `ui.nvim`
— matcht der Sache nach eher zu Punkt 10 als zu einer neuen UI-Primitive.

**Aufwand:** mittel–groß, abhängig von der Klärung.

**Umgesetzt (2026-09-24):** zwei Fund-Korrekturen vor dem eigentlichen Code:

1. `gitsuite.nvim` exportiert **keine** eigene listbare Status-API. Sein
   `features.status.repo()`/`.quickfix()` (`gitsuite/features/status/init.lua`)
   sind Notify- bzw. Quickfix-Seiteneffekte, keine Datenquelle mit stabiler
   Rückgabe. Der tatsächliche, wiederverwendbare Parser liegt in
   `lib.nvim.git.status_porcelain()`/`.parse_status()`
   (`lib.nvim/lua/lib/nvim/git/init.lua`) — `gitsuite.nvim`s eigener Modul-
   Kommentar sagt das sogar wörtlich ("`lib.nvim.git.status_porcelain`,
   already written, not duplicated").
2. `filetree.nvim/lua/filetree/features/git/git_status/init.lua` hat **keinen**
   eigenen `git status --porcelain`-Parser (der ursprüngliche Fund-Text war
   hier veraltet) — es ruft ebenfalls `lib.nvim.git.status_porcelain_async`
   auf, exakt dieselbe Quelle wie `gitsuite.nvim`. Alle drei Repos (jetzt auch
   `pickers.nvim`) teilen sich denselben Parser; kein zweiter wurde gebaut.

Neuer Builtin `git_status_marks` in `pickers.nvim/lua/pickers/builtins/init.lua`
(REGISTRY, direkt neben dem bestehenden `git_status`-Eintrag), mit eigenem
Modul `pickers/git_status_marks/init.lua` — bewusst NICHT der bestehende
`git_status`-Name: der ist bereits durch den nativen Passthrough-Builtin belegt
(`Snacks.picker.git_status()`/`telescope.builtin.git_status()`/`fzf-lua
.git_status()`, ohne Staged/Unstaged-Trennung). `git_status_marks` ist ein
eigenständiges, engine-agnostisches Item-Picker (`pick_item()` auf allen drei
Engines, wie `pickers.browse`) mit drei Toggle-Zeilen am Listenanfang
(`[x] show: staged only` etc.), die die Liste mit dem neuen Filter neu öffnen
— bewusst KEINE rohe Tastenkombination: `pick_item()` hat auf keiner der drei
Engines einen Per-Call-Hook für zusätzliche Keymaps (snacks' `Picker.select`
ist laut eigenem Modul-Kommentar bewusst minimal gehalten), während
`pickers.browse`s "Zeile wählen → Liste neu öffnen"-Muster im selben Repo
bereits genau dieses Problem löst — übernommen statt einen zweiten Mechanismus
zu erfinden. Auswahl einer Datei-Zeile öffnet sie normal (`vim.cmd.edit`).

Die in Punkt 10 gebauten `entry_actions` (`[a`/`]a`/`[e`/`ML`) greifen
automatisch, ohne eigene Verdrahtung — verifiziert: jede `pick_item()`-basierte
Liste in `pickers.nvim` bekommt sie über die nvim-config-eigenen
`lua/config/{telescope,fzf,snacks/picker}/init.lua`-Merges für frei, exakt wie
Punkt 10s Bericht es für native Engine-Builtins schon beschrieben hatte.

Default-Key: `<leader>gm` ("git marks"), registriert über die "declarative
mappings" (`mappings.git_status_marks` in `plugins/personal/init.lua`, analog
Punkt 2s `recent`-Eintrag). Kollisionsprüfung ergab einen bereits sehr dicht
belegten `<leader>g*`-Namensraum, den die ursprüngliche Aufgabenstellung so
nicht erwartet hatte: `<leader>gs`/`gS`/`gl`/`gL`/`gB`/`gD`/`gf`/`gi`/`gI`/
`gp`/`gP` sind alle schon vergeben (`config/snacks/mappings/standard.lua`,
darunter `<leader>gs` selbst — für genau den nativen `git_status`-Builtin!),
plus bare `gb` (gitsuite Blame) und `gg` (Neogit) außerhalb des Leader-Raums.
`<leader>fg`/`<leader>fgs` (aus der Aufgabenstellung als Kandidat genannt)
sind ebenfalls belegt (FzfLua Live Grep bzw. FzfLua Git Status,
`BINDINGS-RUNTIME-CHECKLIST.md`). `<leader>gm` war ökosystemweit frei (weder im
Checklist noch in `config/snacks/mappings/standard.lua` noch sonstwo).
`BINDINGS-RUNTIME-CHECKLIST.md` bewusst NICHT angefasst — dieselbe Begründung
wie bei Punkt 9/10: sie ist generiert (`bindings.audit.checklist_lines`) und
scannt nur nvim-configs eigene `bindings/`-Module, nicht zur Laufzeit über
`pickers.mappings` registrierte Keymaps (`<leader>fo` aus Punkt 2 fehlt dort
aus demselben Grund).

Tests in `TESTS/pickers_spec.lua` (neue Suite direkt nach `pickers.browse`s
eigener): reine Klassifizierung (`is_staged`/`is_unstaged`/`matches_filter`
über alle relevanten XY-Codes inkl. `??`/`MM`), `build_rows`/`to_items`/
`toggle_rows` gegen eine fixe Status-Map (kein echtes Git-Repo, kein
Git-Prozess), sowie `open()`/Toggle-Flow gegen eine gestubbte
`lib.nvim.git` und eine Fake-Engine nach demselben Muster wie `pickers.browse`s
eigene Suite. Eine Testfalle unterwegs gefunden und korrigiert: ein literaler
`"/fake/repo"`-Pfad wird auf dieser Windows-Devbox von `:edit` NICHT als
absolut erkannt (fehlender Laufwerksbuchstabe) und stattdessen cwd-relativ
aufgelöst — Fixture auf einen echten absoluten Pfad (`vim.fn.tempname()`s
Elternverzeichnis) umgestellt, plus `vim.fs.normalize()` beim Vergleich.
luacheck (0/0 über `lua`/`plugin`/`TESTS`) und `stylua --check` grün. Volle
Suite: 722 Checks grün bis zu einem **vorbestehenden**, umgebungsabhängigen
Crash in der `quickfix`-Preview-Suite (`'noautocmd' cannot be used with
existing windows`, NVIM v0.11.4) — per `git stash` gegengeprüft: identischer
Crash an derselben Stelle bereits vor dieser Änderung (exakt das schon aus
Punkt 10s Bericht bekannte Problem). Zur eigentlichen Verifikation der neuen
Suite wurde eine temporäre Kopie der Spec-Datei ohne den abstürzenden
`quickfix`-Block separat lokal ausgeführt (722/722 grün, nie committed).

Docs aktualisiert: `docs/builtins.md` (Matrix-Zeile, Zähler 52→53, neuer
Abschnitt "`git_status` vs. `git_status_marks`" zur Abgrenzung),
`docs/FEATURES/BUILTINS.md` (Verweis auf das neue Modul). `doc/pickers.txt`
bewusst NICHT angefasst: die vimdoc-Datei listet die Builtin-Registry gar
nicht einzeln auf (nur generische `mappings`-Prosa, ohne Per-Builtin-Inhalt) —
dort gibt es nichts Git-Status-Spezifisches nachzuziehen.

Plugin-Spec: `mappings.git_status_marks = { "<leader>gm" }` in
`plugins/personal/init.lua` ergänzt (kein automatisches Greifen wie bei
Punkt 10 — anders als `entry_actions`, ist ein Builtin-Name in `mappings` ohne
expliziten Eintrag schlicht ungebunden, exakt wie Punkt 2s Fund für `recent`).

Commits: `pickers.nvim@8c9afbd`, `nvim-config` (diese Handover-Datei +
Plugin-Spec, separater Commit).

### 13. `:MyPlugins` — nvim-config + fetch-Optionen

**Fund:** `:MyPlugins dashboard` delegiert komplett an
`:Reposcope dashboard` (`bindings/usrcmds/plugin_repos/init.lua:444-451`).
`fetch` existiert bereits als Subcommand (`init.lua:934`), aber nicht als
Auto-Trigger beim Öffnen. Die nvim-config selbst liegt nicht unter
`$REPOS_DIR`, ist also für `reposcope.nvim`s eigenes Scanning unsichtbar —
das ist der eigentliche Grund, warum sie im Dashboard fehlt.

**Fix:** (a) `open_dashboard()` um ein `fetch=true`/`fetchThis=true`-Flag
erweitern, das vor dem Öffnen `:MyPlugins fetch [dir]` synchron/async
vorschaltet; (b) prüfen, ob `reposcope.nvim` einen Weg hat, einen
Extra-Pfad außerhalb seines Scan-Roots aufzunehmen (eigenes Repo, nicht in
dieser Session untersucht) — sonst wird das ein `reposcope.nvim`-Feature-
Request, kein `:MyPlugins`-Fix.

**Aufwand:** (a) klein, (b) unbekannt ohne `reposcope.nvim`-Review.

### 14. lsp.nvim: Winbar-Breadcrumb rechtsbündig

**Geklärt (2026-09-23):** `lua/lsp/core/winbar/render.lua`, nicht
`markdown.nvim`/`filetree.nvim`/`my.nvim`. `M.render()` baut den
`'winbar'`-String selbst zusammen (`table.concat(drawn, sep)`,
`render.lua:262-280`) — kein `align`-Feld, keine Rechtsbündig-Logik.

**Fix ist trivial:** Neovims `'statusline'`-Format (das `'winbar'` erbt)
kennt `%=` als eingebautes Rechtsbündig-Item — alles danach wird an den
rechten Rand gedrückt. Ein `opts.align == "right"`-Zweig, der dem
zurückgegebenen String `%=` voranstellt, reicht; keine eigene
Padding-Berechnung nötig.

**Underline:** kein `underline` im Code gefunden (weder `render.lua` noch
`init.lua`/`kinds.lua`) — die vom Nutzer beobachtete Linie kommt aus dem
Colorscheme-eigenen `WinBar`-Highlight-Group, nicht aus lsp.nvim selbst.
Der "Test ohne Underline" ist also `:hi WinBar gui=NONE` (oder ein
Colorscheme-Override), keine Code-Änderung hier — lsp.nvim zwingt aktuell
gar kein Underline, es erbt nur, was das Colorscheme für `WinBar` vorgibt.

**Aufwand:** klein (ein `%=`-Zweig + Config-Feld `align`).

### 15. Audit-Task: "Vorschlag ablehnen ⇒ Ursprungs-Aktion bleibt möglich"

Wie angefragt als eigener Task formuliert — bewusst NICHT hier im Detail
ausgeführt, sondern in
[`Final_Checks/workflows-interactive-confirm.md`](../personal/All/FINISH/Final_Checks/workflows-interactive-confirm.md)
als eigener Abschnitt, weil er inhaltlich zum selben Cross-Cutting-Thema
gehört wie die Confirm-statt-Notify-Fälle (#3/#4): beides ist "eine
Ablehnung an Punkt A darf nicht automatisch Punkt B canceln, wenn A und B
unabhängige Entscheidungen sind".

---

## Methodik

Jeder Fund wurde am echten Code verortet (`grep`/`Read`), nicht aus der
Beschreibung geschlussfolgert — wo eine Datei/Zeile fehlt, ist das ein
bewusster Hinweis auf "noch nicht gefunden", nicht auf "existiert nicht".

Ursprünglich (2026-09-23, erste Fassung) reine Analyse + Plan ohne
Code-Änderung. Ab der zweiten Runde (gleicher Tag, nach Klärung der beiden
offenen Fragen) läuft die Umsetzung entlang des Plans oben, ein Punkt nach
dem anderen — diese Datei wird dabei als Handover mitgeführt: Status-Häkchen
in der Übersicht, ein "Umgesetzt"-Absatz je Punkt sobald erledigt.

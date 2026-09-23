# Ökosystem-Review: viele kleine Tasks (2026-09-23)

**Handover-Datei — wird laufend aktualisiert, während die Punkte umgesetzt
werden.** Status-Spalte pro Punkt unten in der Übersicht; Details-Abschnitte
bleiben als Analyse stehen, bekommen aber einen "Umgesetzt"-Absatz sobald
erledigt.

**Stand 2026-09-23, pausiert nach Punkt 7 auf Zuruf.** 7/15 committed +
gepusht (siehe Häkchen unten, je mit Commit-Hash im "Umgesetzt"-Absatz).
Punkte 8–14 (images.nvim, buffer-ctx.nvim fm/browser, pickers.nvim-Keymaps
+ Git-Status-Marks, `:Insert`-Cross-Plugin-Shims, `:MyPlugins`
nvim-config+fetch, lsp.nvim-Breadcrumb) sind **noch nicht begonnen**. Punkt
15 (Audit-Task) ist bereits als eigene Aufgabe formuliert, nicht Teil dieser
Umsetzungs-Reihenfolge. Bevor hier weitergemacht wird: Punkt 7 bitte einmal
von Hand testen (siehe dessen Abschnitt) — Wrap-Verhalten ließ sich headless
nicht abschließend verifizieren.

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

8. [ ] **images.nvim** — `:Images paste [path=...]` + `ui.kit.select`-Abfrage (relativ/absolut/`$REPOS_DIR`/custom)
9. [ ] **buffer-ctx.nvim** — `<leader>fm`-Äquivalent (im Dateimanager öffnen) + im Browser öffnen
10. [ ] **pickers.nvim** — filetree.nvim-Keymaps (`[a`, `ML`, …) in der Ergebnisliste (Telescope + fzf-lua)

### Phase 4 — Größer, braucht eigenen Design-Pass

11. [ ] **buffer-ctx.nvim** — `:Insert`/`:Copy` cross-plugin "shimmed providers" (z. B. `images.nvim`s `paste`)
12. [ ] **pickers.nvim** — neuer Builtin: Marks-artige Liste, gefiltert auf Git-Status (uncommitted/staged/unstaged, umschaltbar) — Ort geklärt: `pickers.nvim`, nicht `ui.nvim` (siehe Klärungen oben)
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

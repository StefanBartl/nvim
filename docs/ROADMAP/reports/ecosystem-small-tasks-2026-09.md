# Ökosystem-Review: viele kleine Tasks (2026-09-23)

Analyse + Umsetzungsplan für die Sammlung an kleinen Tasks aus der Session
vom 2026-09-23, quer über `gopath.nvim`, `images.nvim`, `pickers.nvim`,
`buffer-ctx.nvim`, `fileops.nvim`, `filetree.nvim`, `ui.nvim` und die
nvim-config selbst. Jeder Punkt wurde im echten Quellcode verortet (Datei +
Zeile), nicht nur aus der Beschreibung geraten. Zwei Punkte ließen sich nicht
eindeutig verorten — siehe [Offene Fragen](#offene-fragen).

Der zugehörige Cross-Cutting-Task "Workflows" (interaktive Bestätigung statt
Notify-mit-Anleitung) hat eine eigene Datei:
[`Final_Checks/workflows-interactive-confirm.md`](../personal/All/FINISH/Final_Checks/workflows-interactive-confirm.md).

---

## Umsetzungsplan (Reihenfolge)

Sortiert nach Aufwand/Risiko, nicht nach Wunsch-Priorität — die Reihenfolge
ist ein Vorschlag, keine Verpflichtung, einzeln umsetzbar/verschiebbar.

### Phase 1 — Isolierte Ein-Datei-Fixes (je < 1h, keine Designfrage offen)

1. **buffer-ctx.nvim** — `$REPOS_DIR`-rooted `:Copy`/`:Insert filepath`-Modus
2. **pickers.nvim** — `oldfiles`-Builtin auf `<leader>fo` freilegen
3. **fileops.nvim** — `:File delete` bei ungespeicherten Änderungen: Confirm statt Notify (Workflows-Instanz #1)
4. **nvim-config** — `:MyPlugins`' `confirm.lua`: `ui.kit.confirm` statt `getcharstr()`+`print()` (Workflows-Instanz #2)

### Phase 2 — Einzelrepo, klare Lösung, eine Designentscheidung nötig

5. **gopath.nvim** — Alternate-Picker abbrechen fällt jetzt auf Create-Offer zurück
6. **gopath.nvim** — neuer Eintrittspunkt „im Filetree öffnen/fokussieren" (deckt sowohl `gF`-auf-Markdown-Bild als auch die separat gewünschte `:Filetree open **`-Idee ab)
7. **nvim-config** — `gj`/`gk` im Insert-Mode via `<C-`-Kombination (Konflikt-Check zuerst)

### Phase 3 — Neue kleine Subsysteme

8. **images.nvim** — `:Images paste [path=...]` + `ui.kit.select`-Abfrage (relativ/absolut/`$REPOS_DIR`/custom)
9. **buffer-ctx.nvim** — `<leader>fm`-Äquivalent (im Dateimanager öffnen) + im Browser öffnen
10. **pickers.nvim** — filetree.nvim-Keymaps (`[a`, `ML`, …) in der Ergebnisliste (Telescope + fzf-lua)

### Phase 4 — Größer, braucht eigenen Design-Pass

11. **buffer-ctx.nvim** — `:Insert`/`:Copy` cross-plugin "shimmed providers" (z. B. `images.nvim`s `paste`)
12. **ui.nvim** — neue Marks-artige UI, gefiltert auf Git-Status (uncommitted/staged/unstaged, umschaltbar)
13. **nvim-config `:MyPlugins`** — nvim-config selbst im Dashboard zeigen, `fetch`/`fetchThis`-Optionen beim Öffnen
14. **Klärungsbedarf** — Breadcrumbs rechtsbündig + Underline-Test (Ort unklar, siehe unten)

Ein separater, expliziter Folge-Task (wie angefragt):

15. **Audit-Task** — "Vorschlag ablehnen ⇒ trotzdem ursprüngliche Aktion möglich" systematisch für alle Bindings prüfen (nicht nur `gF`)

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

### 2. pickers.nvim: `oldfiles` auf `<leader>fo`

**Fund:** `oldfiles` existiert bereits als Builtin
(`pickers/builtins/init.lua:66-67`, sowohl `telescope` als auch `fzf`
verdrahtet). Es fehlt nur die Bindung — analog zu den anderen
`<leader>f*`-Einträgen in `pickers/bindings/keymaps.lua`.

**Aufwand:** trivial.

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

### 8. images.nvim: `:Images paste` Pfad-Wahl

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

### 14. Breadcrumbs rechtsbündig — Ort unklar

Siehe [Offene Fragen](#offene-fragen).

### 15. Audit-Task: "Vorschlag ablehnen ⇒ Ursprungs-Aktion bleibt möglich"

Wie angefragt als eigener Task formuliert — bewusst NICHT hier im Detail
ausgeführt, sondern in
[`Final_Checks/workflows-interactive-confirm.md`](../personal/All/FINISH/Final_Checks/workflows-interactive-confirm.md)
als eigener Abschnitt, weil er inhaltlich zum selben Cross-Cutting-Thema
gehört wie die Confirm-statt-Notify-Fälle (#3/#4): beides ist "eine
Ablehnung an Punkt A darf nicht automatisch Punkt B canceln, wenn A und B
unabhängige Entscheidungen sind".

---

## Offene Fragen

**Breadcrumbs rechtsbündig (Punkt aus der Anfrage unter "markdown.nvim"):**
In `markdown.nvim` selbst existiert **kein** Breadcrumb-Code (Grep leer).
Zwei plausible Kandidaten mit demselben Namen, aber unterschiedlichem
Zweck:

- `filetree.nvim`s `B:\repos\filetree.nvim\lua\filetree\features\ui\breadcrumbs\init.lua`
  — Pfad-Breadcrumb (Root → Datei) für die Tree-Sidebar, Modi
  `winbar`/`float`/`statusline`. Hat ein `align="left"` — aber nur für die
  **Float-Positionierung**, nicht für Text-Ausrichtung innerhalb der Zeile.
  In der aktuellen Config nirgends explizit aktiviert (`enabled=false`
  Default, kein Override in `plugins/personal/init.lua` gefunden).
- `my.nvim`s `hl_config/breadcrumbs/` — VSCode-artiger Symbol-Breadcrumb
  (Treesitter/LSP-Pfad) im Winbar, generisch für jeden Dateityp inkl.
  Markdown. Kein `align`/`underline` im Code gefunden.

Keins der beiden hat aktuell eine Rechtsbündig-Option — die Anfrage
bräuchte also so oder so neue Logik, nicht nur einen Config-Switch. Bevor
daran gearbeitet wird: **bitte kurz bestätigen, welches der beiden Module
gemeint ist** (oder ob es ein drittes ist, das dieser Review nicht
gefunden hat).

**Punkt 10/12 (pickers.nvim-Keymaps, Git-Status-Marks):** beide brauchen
vor der Umsetzung eine kurze Scope-Entscheidung (welche Keymaps genau /
wo die Datenquelle herkommt) — siehe jeweilige Abschnitte oben.

---

## Methodik

Jeder Fund wurde am echten Code verortet (`grep`/`Read`), nicht aus der
Beschreibung geschlussfolgert — wo eine Datei/Zeile fehlt, ist das ein
bewusster Hinweis auf "noch nicht gefunden", nicht auf "existiert nicht".
Kein Code wurde in dieser Session verändert; das ist reine Analyse +
Plan, wie angefragt.

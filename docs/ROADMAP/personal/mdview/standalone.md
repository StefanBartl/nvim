# mdview standalone

## Table of content

  - [Bitte du testen— ich konnte nicht](#bitte-du-testen-ich-konnte-nicht)
  - [Was gebaut wurde](#was-gebaut-wurde)
  - [Drei Dinge, die unterwegs Korrekturen brauchten](#drei-dinge-die-unterwegs-korrekturen-brauchten)
  - [Verifiziert (real, nicht nur Tests)](#verifiziert-real-nicht-nur-tests)

---

## Bitte du testen— ich konnte nicht

Voraussetzung: `npm run build:go`, dann in deiner Config `standalone = { binary_path = "E:/repos/mdview.nvim/native/server/mdview-server.exe" }` (bis ein v0.3.0-Release existiert).

1. **`:MDView detach`** auf einer .md-Datei — Browser-Tab öffnet sich? Dann `:qa` in der Ursprungsinstanz: läuft die Preview weiter?
2. **Danach editieren**: neue Instanz öffnen, dieselbe Datei ändern — kommt Live-Push und Scroll-Sync in der detachten Preview an? (Das ist der Kernunterschied zu standalone.)
3. **Preview-Tab schließen** → beendet sich die detachte nvim-Instanz von selbst? (`MDViewSessionEnded` → `qa!`). Prüf mit `tasklist | findstr nvim`, dass nichts unsichtbar zurückbleibt.
4. **`:MDView standalone`** *ohne* `--no-browser` — öffnet der Go-seitige Browser-Opener (`rundll32`) den Tab korrekt? Die URL enthält `&`, deshalb bewusst nicht `cmd /c start`.
5. **`scripts/mdview-bg.ps1 README.md`** aus einem Terminal, dann Terminal schließen — läuft die Preview weiter?
6. **Beides parallel**: normale Session (43219) + standalone (43319) gleichzeitig — stören sie sich?
7. **Alter-Binary-Pfad**: `standalone.binary_path` entfernen und `:MDView standalone` — kommt die klare v0.3.0-Fehlermeldung statt Stille?
8. **`:help mdview-standalone`** — Sektion 11 lesbar, Tags springen?
9. Falls du Linux/WSL nutzt: `scripts/mdview-bg.sh` (Exec-Bit ist gesetzt) und der `$BROWSER`-Pfad im Opener.

---

## Was gebaut wurde

*Go-Seite** — `native/server/internal/source`: ein Datei-Watcher, der `registry.Broadcast` aufruft — exakt derselbe Call wie der `/update`-Handler. Dadurch sind Client, WebSocket-Framing und WASM-Renderer unverändert erreichbar; die beiden Modi sind stromabwärts nicht unterscheidbar. Polling statt fsnotify: keine neue Dependency, plattformgleich, und es überlebt das Write-Temp-then-Rename jedes ernsthaften Editors. Vergleicht Inhalt statt mtime, damit ein No-Op-Save still bleibt.

**Lua-Seite** — `:MDView detach` (zweites, minimales headless nvim; volle Features) und `:MDView standalone` (kein nvim mehr in der Kette; Datei auf Platte). Dazu `scripts/mdview-bg.{sh,ps1}` als Terminal-Einstieg.

---

## Drei Dinge, die unterwegs Korrekturen brauchten

1. **`ipairs`-Falle** in `minimal_init.lua`: unbelegtes `$LIB_NVIM_PATH` als erstes Tabellen-Element beendete die Kandidatensuche sofort — lib.nvim wurde nie gefunden.
2. **Composer-Semantik**: sobald eine Route `args` deklariert, enthält `ctx.rest` nur noch *Reste jenseits des Schemas*. Mein erster Wurf las `ctx.rest` und bekam still nichts. Jetzt korrekt über `ctx.args`/`ctx.flags`.
3. **Stummer Fehlschlag**: die installierte v0.2.0-Release-Binary kennt `--watch` nicht, und ein detached Prozess hat keine Pipes — es passierte einfach *nichts*. Jetzt gibt es einen Preflight-Probe mit klarer Meldung plus `standalone.binary_path` als Override.

---

## Verifiziert (real, nicht nur Tests)

Standalone rendert und live-updated im echten Browser (Dateiänderung → Watcher → WebSocket → WASM → DOM); detached Spawn überlebt den Elternprozess mit korrekter Env-Durchreichung; beide Subcommands in `<Tab>`-Completion; 24 Lua-Tests + alle Go-Tests inkl. 5 neuer Watcher-Specs; Vimdoc-Tags lösen auf.

---


# casedesk — Session-pro-Case (Konzept)

Grundlage: `sessions.nvim`, bereits in `plugins/personal/init.lua` verdrahtet
(aktuell `opts = {}` — keine Keymaps, kein `autoload`, `autosave = true` auf
den fixen Namen `"last"`, siehe `sessions.nvim/docs/configuration.md`).

> **Paket 1 steht** (2026-08-07): `<leader>cs` (§5) und der `:Case
> new`-Hook (§3) sind gebaut und headless getestet — siehe
> [Keymaps.md](../../NOTES/casedesk/Keymaps.md). Der aktive Teil von §6
> (Session löschen bei `:Case close`/`reassign`) ist ebenfalls schon
> gebaut.
>
> **Paket 2 steht** (2026-08-09): PowerShell-`case`-Funktion im `$PROFILE`
> eingerichtet (`Configs/Windows/DOTFILES/WindowsPowerShell/
> Microsoft.PowerShell_profile.ps1`, außerhalb dieses Repos) und `autoload
> = true` in `plugins/personal/init.lua`s `sessions.nvim`-Spec aktiviert.
> Offen: nur noch der `:Cases doctor`-Sicherheitsnetz-Teil von §6 (Paket 3),
> siehe §10.

Fertige Features stehen sonst in [CONCEPT.md](CONCEPT.md), weitere offene
Punkte in [ROADMAP.md](ROADMAP.md) — dieses Dokument bleibt die Vorarbeit
für den Rest der Integration.

---

## Table of content

- [1. Warum ein Case eine Session braucht](#1-warum-ein-case-eine-session-braucht)
- [2. Namensschema](#2-namensschema)
- [3. Automatische Erstellung](#3-automatische-erstellung)
- [4. Start: direkt in eine Case-Session](#4-start-direkt-in-eine-case-session)
- [5. Der eine Keymap](#5-der-eine-keymap)
- [6. Invalidierung](#6-invalidierung)
- [7. Modulaufbau](#7-modulaufbau)
- [8. Risiken und Fallen](#8-risiken-und-fallen)
- [9. Offene Fragen](#9-offene-fragen)
- [10. Reihenfolge](#10-reihenfolge)

---

## 1. Warum ein Case eine Session braucht

Ein Case ist normalerweise über mehrere Sitzungen verteilt (§8h in
CONCEPT.md beschreibt das für die Zeitachse) — man macht einen Case auf,
recherchiert, schließt Neovim, macht am nächsten Tag weiter. Ohne eigene
Session heißt "weitermachen" heute: Case-Ordner erneut per `:Case open`
suchen, `Research/00_Research.md` erneut öffnen, Split-Layout erneut
aufbauen. Eine Session pro Case macht daraus einen Sprung zurück zu genau
dem Zustand (Buffer, Fenster-Layout), in dem man den Case verlassen hat —
dieselbe "Zustand ableiten statt zweite Kopie pflegen"-Denkweise wie
CONCEPT.md §3 (Ordner = Zustand) und §8h (Zeitachse aus mtimes statt
Logbuch), nur für Fenster-/Buffer-Layout statt Case-Status.

## 2. Namensschema

Session-Name = die kurze Case-Nummer, unverändert (`1007631`) — dasselbe
Format, das `.case.json`, der Ordnername und die `CASE`-Argtyp-Validierung
(`init.lua`, `render.to_short`) schon verwenden. Kein Präfix, kein Suffix:
`sessions.nvim` erlaubt beliebige Namen, `:Session load 1007631` funktioniert
ohne jede Änderung an `sessions.nvim` selbst.

## 3. Automatische Erstellung

Hook in `:Case new`, direkt nach dem bestehenden Scaffold-Schritt, der
`Research/00_Research.md` öffnet (`ui.lua`, Blueprint-Knoten mit
`open = true`, CONCEPT.md §5): einmalig

```lua
require("sessions").save(case_nr)
```

Damit hat jeder ab jetzt neu angelegte Case ab Geburt eine Session, nicht
erst nach dem ersten manuellen Save. Bestandscases (vor diesem Feature)
bekommen ihre erste Session beim ersten `<leader>cs` (§5) oder `:Case sync` —
kein Nachzieh-Migrationsschritt nötig, das Verhalten ist identisch zu einem
Case, der einfach noch nie gespeichert wurde.

## 4. Start: direkt in eine Case-Session

`nvim +{CASENUMBER}` geht wörtlich nicht — Vims `+N`-Flag heißt "spring zu
Zeile N in der ersten Datei", eine Zahl danach wird nie als Ex-Command
interpretiert (anders als `sessions.nvim`s eigenes `:LastSession`, das
genau dafür als **eigener, unquoted-CLI-freundlicher** Befehl existiert,
siehe `docs/commands.md`: `nvim +LastSession`).

Zwei Ebenen, keine davon braucht neuen Code in `sessions.nvim` oder casedesk:

1. **Ohne Wrapper, funktioniert schon heute:**
   `nvim -c "Session load 1007631"` (oder `nvim +"Session load 1007631"`)
2. **Für die eigentlich gewünschte Kurzform** — eine PowerShell-Funktion
   im `$PROFILE` (liegt außerhalb dieses Repos, gehört ins
   PowerShell-Profil, nicht in die nvim-Config):
   ```powershell
   function case {
     param([string]$CaseNr)
     if ($CaseNr) { nvim -c "Session load $CaseNr" } else { nvim }
   }
   ```
   Aufruf: `case 1007631`.
3. **Ergänzend, deckt den häufigsten Fall ohne jede Nummer ab:**
   `sessions.nvim`s `autoload = true` (oder `"ask"` für einen y/n-Prompt) —
   bloßes `nvim` ohne Dateiargumente lädt automatisch die zuletzt geladene
   Session. Für "einfach weitermachen, wo ich aufgehört habe" reicht das,
   `case {nr}`/§4.2 bleibt für den gezielten Wechsel auf einen *anderen*
   Case als den zuletzt aktiven.

## 5. Der eine Keymap

Einziger neuer Keymap, casedesk-spezifisch (nicht in `sessions.nvim`s
eigenem `keymaps`-Block, da der generisch bleiben soll): `<leader>cs`
("Case Session"), aktuell unbelegt.

```lua
map("n", "<leader>cs", function()
  local entry = require("bindings.usrcmds.case.resolve").sync(nil)
  local sessions = require("sessions")
  if entry then
    sessions.save(entry.short)
  else
    sessions.save(nil) -- sessions.nvim's eigenes Auto-Resolve (Projekt/Branch, sonst "last")
  end
end, { desc = "[casedesk] Save session (case-aware)" })
```

`resolve.sync(nil)` ist exakt dieselbe Ordner-Validierung, die `:Case snow`,
`:Case activity` etc. schon nutzen, um "welcher Case?" aus dem fokussierten
Buffer zu beantworten (`resolve.lua`, Registry-Abgleich, kein Marker-File
nötig) — kein neuer Resolutions-Mechanismus, derselbe wie überall sonst in
casedesk. Der Else-Zweig ist **kein** hartcodiertes `"last"`, sondern
`sessions.nvim`s eigenes Naming (`docs/configuration.md`s Projekt-/
Branch-Tabelle) — bei Arbeit an dieser nvim-Config selbst also z. B.
`nvim_main` statt pauschal `"last"`, was der ursprünglichen Beschreibung
("wenn ich in keinem Case bin, dann auf last") als Sonderfall entspricht,
aber für andere Repos sinnvoller ist.

`sessions.nvim`s eigener `autosave = true` (Default) bleibt unverändert
aktiv und speichert bei jedem Exit weiterhin nach dem fixen
`autosave_name` (`"last"`) — unabhängig davon, ob eine Case-Session geladen
war. Das ist ein reines Sicherheitsnetz und bewusst nicht case-aware
(würde sonst beim Beenden lautlos die zuletzt *geladene* statt die zuletzt
*bearbeitete* Case-Session überschreiben, ohne dass man das gesehen hätte).
Case-Sessions werden ausschließlich über `<leader>cs` und den
Auto-Save bei `:Case new` (§3) geschrieben — explizit, nie beim Beenden.

## 6. Invalidierung

**Regel, kein Alters-Schwellwert:** eine Session, deren Name auf einen
bekannten Case (`registry.find(name)`) zeigt, dessen aktueller Zustand aber
nicht `config.default_state` ("Open") ist, ist überflüssig. Folgt direkt
aus CONCEPT.md §3 ("der Zustand IST der Ordner"): sobald ein Case zu ist,
braucht seine Session niemand mehr — kein separates `session_prune_days`
nötig.

**Primärmechanismus (steht, 2026-08-07): aktiv, direkt bei `:Case
close`/`:Case reassign`.** `M.move_state` — die eine geteilte Grundlage
hinter jedem generierten State-Move-Verb (`init.lua` baut einen pro
Nicht-Default-Eintrag in `config.states`) — löscht die Session sofort nach
dem erfolgreichen Ordner-Umzug, wenn `state ~= config.default_state`:

```lua
-- ui.lua, M.move_state, nach registry.invalidate()
if state ~= config.default_state then
  local ok_sessions, sessions = pcall(require, "sessions")
  if ok_sessions then
    sessions.delete(entry.short)
  end
end
```

`sessions.delete` liefert `false, "session not found: …"` wenn keine
existiert (kein Fehler, kein Wurf) — der häufige Fall, da die meisten
Cases nie eine Session hatten. Kein Threshold, kein Bestätigungsdialog:
der Umzug selbst wurde schon per `kit.confirm` bestätigt, das Löschen der
dazugehörigen Session ist Teil derselben Aktion, kein zweiter
Entscheidungspunkt.

**Sicherheitsnetz: `doctor.lua`/`normalize.lua`** (CONCEPT.md §10, derselbe
Plan → Dry-Run → Confirm → Apply-Pfad, den `:Cases doctor`/`normalize`
schon für Case-Hygiene nutzen), für zwei Fälle, die der aktive Hook nicht
abdeckt: Cases, die schon vor diesem Feature geschlossen wurden, und ein
Ordner-Umzug außerhalb von `M.move_state` (von Hand, oder ein zukünftiger
Pfad). Noch nicht gebaut (Paket 3, §10):

```lua
-- doctor.lua, neuer Check
for _, name in ipairs(require("sessions").list_names()) do -- oder S.list() + Namens-Extraktion
  local entry = registry.find(name)
  if entry and entry.state ~= config.default_state then
    findings[#findings + 1] = {
      kind = "stale-session",
      case = entry.short,
      detail = ("session '%s' exists for a %s case"):format(name, entry.state),
      fix = function() require("sessions").delete(name) end,
    }
  end
end
```

Sessions, deren Name **gar keinem** bekannten Case entspricht (händisch
benannt, oder ein Case, der aus der Registry verschwunden ist), sind ein
separater, niedriger priorisierter Fund — nur melden, nie automatisch
löschen, da mehrdeutig (könnte eine bewusst so benannte Nicht-Case-Session
sein, z. B. für dieses nvim-Config-Repo selbst).

## 7. Modulaufbau

Kein neues Untermodul nötig — Umfang ist klein genug für drei Stellen:

```
lua/bindings/usrcmds/case/
  ui.lua      -- :Case new-Hook (§3), M.move_state-Hook (§6, aktiv)
  doctor.lua  -- neuer Finding-Typ "stale-session" (§6, Sicherheitsnetz)
  normalize.lua -- Fix-Zweig für "stale-session" (§6, Sicherheitsnetz)
```

`<leader>cs` selbst lebt bewusst außerhalb dieses Baums, in
`bindings/mappings/custom.lua` (§5 begründet warum).

## 8. Risiken und Fallen

| Risiko | Gegenmaßnahme |
| --- | --- |
| `<leader>cs` überschreibt versehentlich eine Case-Session mit dem falschen Layout (z. B. Split von einer anderen Aufgabe noch offen) | Kein automatisches Save beim Verlassen des Case-Buffers — nur explizit per Keymap, der Nutzer sieht, wann er speichert |
| `autosave` (fix `"last"`) und Case-Sessions könnten verwechselt werden | Bewusst getrennt gehalten (§5) — `"last"` ist nie eine Case-Nummer, Verwechslung filesystem-seitig ausgeschlossen |
| `doctor`s neuer Check bricht, wenn `sessions.nvim` nicht geladen ist (remote-Modus, andere Plugin-Auswahl) | `pcall(require, "sessions")`, Fallback: Check einfach überspringen — gleiches Muster wie jede andere optionale Integration in CONCEPT.md §9 |
| Session-Datei zeigt auf Buffer, die nicht mehr existieren (Case wurde inzwischen `normalize`t, Dateien umbenannt) | Bestehendes `sessions.nvim`-Verhalten (`S.load` meldet "hidden_bufs" für nicht mehr vorhandene Pfade), kein zusätzlicher Schutz hier nötig |
| Aktives Löschen in `M.move_state` (§6) trifft die falsche Session — z. B. ein Case wird versehentlich `reassign`t und die Session ist weg | Kein zusätzlicher Dialog *für die Session*, aber der Ordner-Umzug selbst läuft schon durch `kit.confirm` — wer den Umzug bestätigt, bestätigt implizit auch das. Die Session-Datei selbst ist jederzeit aus einem frischen `<leader>cs` neu erzeugbar, kein Datenverlust im engeren Sinn (Buffer-Layout, kein Inhalt) |

## 9. Offene Fragen

1. Soll `:Case sync` (bestehender Befehl, "fehlende Blueprint-Teile
   nachziehen") auch "Session existiert noch nicht" nachziehen, oder bleibt
   das exklusiv `<leader>cs`/§3? Tendenz: `:Case sync` mit erledigen, da es
   ohnehin "diesen Case auf den erwarteten Stand bringen" bedeutet.
2. `:Cases sessions` als Übersicht (welcher offene Case hat noch keine
   Session, welcher hat eine) — eigener Befehl oder ein Fund-Typ mehr in
   `:Cases doctor`? Tendenz: kein neuer Befehl für eine Frage, die `doctor`
   sowieso schon beantwortet.
3. Reihenfolge von `<leader>cs` vs. dem bestehenden `sessions.nvim`-eigenen
   `keymaps`-Block (`opts.keymaps`) — bleibt der leer (nur casedesks
   eigener Keymap), oder aktiviert man zusätzlich generische
   `sessions.nvim`-Keymaps (`save`/`load`/`list`) für Nicht-Case-Arbeit?
   Laut Anfrage: keine weiteren Keymaps gewünscht, also `opts.keymaps`
   bleibt `false`/leer.

## 10. Reihenfolge

**Paket 1 — Fundament (steht):** `<leader>cs` (§5,
`bindings/mappings/custom.lua`), `:Case new`-Hook (§3, `ui.lua`s
`M.create`), aktives Session-Löschen bei `:Case close`/`reassign` (§6,
`ui.lua`s `M.move_state`). Funktioniert für sich, ohne §4/den
Sicherheitsnetz-Teil von §6 — Frage 3 aus §9 wurde dabei mitentschieden:
`opts.keymaps` bleibt leer.

**Paket 2 — Start-Komfort (steht, 2026-08-09):** PowerShell-`case`-Funktion
(§4.2) im `$PROFILE` eingerichtet (liegt außerhalb dieses Repos, im
DOTFILES-Repo), `autoload = true` in `plugins/personal/init.lua`s
`sessions.nvim`-Spec aktiviert (§4.3).

**Paket 3 — Hygiene-Sicherheitsnetz:** `doctor.lua`/`normalize.lua`-Erweiterung
(§6) für Cases, die schon vor Paket 1 geschlossen wurden, oder deren Ordner
außerhalb von `M.move_state` verschoben wurde. Zuletzt, weil der aktive
Hook den Regelfall bereits abdeckt.

## Siehe auch

- [CONCEPT.md](CONCEPT.md) §3 (Zustand = Ordner), §4 (Modulaufbau),
  §8h (Zeitachse), §10 (`:Cases doctor`/`normalize`)
- [ROADMAP.md](ROADMAP.md) — Plugin-Check-Tabelle, Zeile `sessions.nvim`
- `sessions.nvim`s eigene [`docs/commands.md`](https://github.com/StefanBartl/sessions.nvim/blob/main/docs/commands.md), [`docs/api.md`](https://github.com/StefanBartl/sessions.nvim/blob/main/docs/api.md), [`docs/configuration.md`](https://github.com/StefanBartl/sessions.nvim/blob/main/docs/configuration.md)

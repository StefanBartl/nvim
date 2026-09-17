# `rules.nvim` gegen die nvim-config — Durchgang 2026-09-17

> Schwesterdokument zu [`rules-nvim-review.md`](./rules-nvim-review.md) und
> [`rules-nvim-review-full.md`](./rules-nvim-review-full.md), die beide
> `ai.nvim` prüfen. Dieser Durchgang richtet denselben Katalog auf **die
> Konfiguration selbst**. Lebendes Dokument: bei einem Re-Run vor Ort
> aktualisieren.

**Stand:** 2026-09-17. **Geprüft gegen:** dieses Repo, Worktree
`nvim-plugins-quality-review-30b806`, Basis `38c40a1`. **Katalog:** 421
Regeln in 14 Familien aus
`$REPOS_DIR/WKDBooks/Development/wkdbook-Lua/Checklists` — 32 davon
mechanisch prüfbar, 389 `manual`.

**Vorgehen:** die Engine headless gefahren (`rules.check_family_json` über
jede geladene Familie), danach die kritischen `manual`-Regeln einzeln gegen
den Quelltext geprüft. Jeder Fund unten wurde **in einem laufenden Neovim
reproduziert**, bevor er gefixt wurde — kein Fund steht hier auf reiner
Quelltext-Lektüre. Die Gegenprobe steht jeweils in der Commit-Message.

**Status-Legende:** ✅ erfüllt · ➖ nicht anwendbar · 🔶 Fund (gefixt) ·
❓ offene Entscheidung

---

## Zusammenfassung — 8 Funde, 8 gefixt, 2 Entscheidungen offen

| # | Regel | Schwere | Fund | Commit |
| - | ----- | ------- | ---- | ------ |
| 1 | `ERR-60` | 🔴 kritisch | `case/doctor.lua`s „Ziel existiert schon"-Guard war an **sieben** Stellen als `exists(to) and nil or to` geschrieben — ein Ausdruck, der *immer* `to` liefert. `normalize.lua` handelt auf jedem `to ~= nil`, `mutate.rename_file` ist ein nacktes `uv.fs_rename`, und das **überschreibt sein Ziel stillschweigend** (auf dieser Windows-Maschine verifiziert). Mit einer Alias-Datei neben einer echten `Notes.md` hätte `:Case normalize` die Notizen gelöscht. Derselbe Verlust ist diesem Modul laut eigenem Header **schon einmal passiert**. | `c560cfb` |
| 2 | `SEC-03` | 🔴 kritisch | `custom_menu`s „Terminal hier öffnen" baute `cd <dir> ; $SHELL` als Shell-String. `<dir>` kommt aus dem Buffernamen; ein Pfad darf Shell-Metazeichen enthalten. Reproduziert: ein `;` im Namen führt den Rest aus — das `cd` muss dafür nicht einmal gelingen. | `b157786` |
| 3 | `SEC-34` | 🔴 kritisch | Vier `vim.fn.expand()`-Aufrufe auf nicht-statischen Strings. Der in `context_open/providers.lua` bekommt `<cfile>`, also beliebigen Text aus einem fremden Buffer: unter `expand()` ist ein Backtick-Span eine Kommandosubstitution über `&shell`, und `%`/`#` lösen still zu anderen Pfaden auf (verifiziert: `expand("%")` gibt den aktuellen Dateinamen). Alle vier gehen jetzt über `lib.nvim.cross.fs.expand_path`. | `b157786` |
| 4 | `ERR-31` | 🔴 kritisch | Harpoons `is_first_run()`/`mark_initialized()` waren Check-dann-Erzeugen, mit ungewöhnlich weitem Fenster: geprüft in `setup()`, markiert erst nach `VimEnter` + `vim.schedule`. Zwei gleichzeitig gestartete Neovims hätten beide geseedet. Jetzt ein `fs_open(..., "wx")` (`O_CREAT|O_EXCL`), das beansprucht *und* markiert. | `9494c08` |
| 5 | `LUA-16` | 🔴 kritisch | `bindings_explorer/source.lua` fällt mit `node.module or node.id` zurück. Ein JSON-`null` dekodiert zu `vim.NIL` — Userdata und damit **truthy**, der Fallback greift nie, und die erste Verkettung wirft. `documentation.nvim` schreibt diese Form nachweislich (192 von 414 Knoten). Latent, nicht aktiv: nur ein Knoten trägt derzeit `bindings`, und der hat beide Felder gesetzt. | `d0a9493` |
| 6 | `XP-05` | 🔴 kritisch | Die `bat`-Probe steckte in fzf-luas `preview`-Callback, den fzf pro angezeigtem Eintrag aufruft. `vim.fn.executable` cacht nicht. Gemessen: ~13,6 ms pro Probe bei gefundenem Tool, ~48 ms bei nicht gefundenem. 50 Previews kosteten 633 ms reines PATH-Stat'en, jetzt 12,3 ms. | `43225b4` |
| 7 | `XP-01` | 🔴 kritisch | `:NeotestDebugFramework` listete das CWD per `vim.fn.glob(cwd .. "/*")`. glob liest sein ganzes Argument als Pattern, `cwd` eingeschlossen — verifiziert: ein `proj[1]`-Ordner mit einer Datei globt zu 0 Einträgen, `vim.fs.dir` findet sie. Ein Debug-Kommando, das still „nichts" antwortet, ist der schlechtestmögliche Ausfall. | `5f7e8fb` |
| 8 | `NEW-03`/`NEW-36` | 🟡 empfohlen | `.luarc.json` hatte zwei Trailing Commas und war damit **kein gültiges JSON**. LuaLS' eigener Parser toleriert das, weshalb es unbemerkt blieb; nichts anderes, was die Datei liest, tut das. Im selben Durchgang: `stylua --check` war auf drei committeten Dateien rot, das Format-Gate der CI also bereits rot. | `20e3e83` |

### Zusätzlich gehärtet (kein aktiver Bug)

- **`SEC-35`** (`be55563`): Der WhichKey-Prompt wurde in einen Ex-String
  konkateniert, wo `|` ein zweites Kommando beginnt. which-key deklariert
  sein Usercommand mit `nargs="*"` **ohne** `-bar`, schluckt den `|` also
  heute — an einer Live-Deklaration verifiziert, nicht angenommen. Das ist
  aber ein Fremdplugin-Detail, das diese Config nicht kontrolliert, und die
  Argumentform liefert ein byte-identisches `cmd.args`.
- **`ERR-60`** in `case/solution.lua` (`c560cfb`): dasselbe Idiom, dort
  **inert**, weil `flush()` zuerst `current_key` prüft. Trotzdem auf ein
  explizites `if` umgestellt, damit die Falle nicht stehen bleibt.

---

## Offene Entscheidungen (keine Mängel, sondern deine Wahl)

| Regel | Sachverhalt |
| ----- | ----------- |
| `NEW-06` / `REL-28` | Kein `LICENSE` im Repo. Der Katalog legt seit 2026-09-06 MIT (Copyright Stefan Bartl) als Hausentscheidung fest — das ist dort allerdings für *Plugins* begründet. Dieses Repo ist öffentlich (`github.com/StefanBartl/nvim`), also hat die Frage eine echte Außenwirkung: ohne Lizenzdatei gilt „alle Rechte vorbehalten". |
| `NEW-11` / `REL-01` | Kein `README.md`. Für eine persönliche Config kein Mangel im Sinne der Regel (die zielt auf installierbare Plugins), aber das Repo ist die erste Seite, die jemand sieht. |

Beide sind bewusst **nicht** in `.rules-waivers.json` eingetragen: ein
Waiver hält fest, dass ein Fund gesehen und akzeptiert wurde — hier ist noch
nichts entschieden.

---

## `.rules-waivers.json` — was bewusst nicht gilt

Die Engine lädt alle 14 Familien, auch die beiden Plugin-Gates. Deren
Formregeln beschreiben ein `*.nvim`-Repo (`lua/<plugin>/health.lua`,
`config/DEFAULTS.lua`, `doc/<name>.txt`, `bindings/{keymaps,usrcmds,autocmds}.lua`).
Diese Config hat keinen `lua/<name>/`-Namensraum, in dem irgendetwas davon
leben könnte — sie hält dieselben Trennungen eine Ebene höher unter
`lua/bindings/`.

Waived mit Begründung: `LUA-80`, `NEW-07`, `NEW-08`, `NEW-10`, `NEW-13`,
`NEW-27`, `UI-62`, `REL-05`, `REL-16` (Plugin-Form) · `NEW-45`
(`.stylua.toml` ist da, nur dot-präfixiert — der `file_exists`-Check kennt
nur die undotted Schreibweise) · `NEW-49` (kein Testsuite in diesem Repo,
also keine busted-Globals für luacheck) · `DEP-01` (beide Treffer sind
Kommentarprosa, die Harpoon2s *eigenes* `settings.key()` zitiert; jede
Aufrufstelle im Repo nutzt längst `vim.uv or vim.loop`).

Ein Waiver ist ausdrücklich nicht dasselbe wie die Familie aus dem Gate zu
nehmen: der Fund bleibt sichtbar, mit Grund.

---

## Geprüft und sauber (Auswahl, mit Beleg)

Damit ein Re-Run nicht dieselben Wege noch einmal geht — das sind die
Stellen, an denen eine Regel *hätte* greifen können und nachweislich nicht
greift:

- **`SEC-46`** (Escape-Zeichen zuerst escapen): `case/attachments.lua`s
  `ps_quote()` verdoppelt `'`, genau PowerShells Regel für
  Single-Quote-Literale — und dort ist `\` kein Escape, die beschriebene
  Falle existiert also nicht. Der eingebettete Wert ist ohnehin das
  Downloads-Verzeichnis.
- **`SEC-15`** (Keys nie selbst verwalten): `gp_config/config.lua` liest
  ausschließlich `os.getenv(...)`, kein Key-Store, keine Persistenz.
- **`SEC-30`** (Nutzereingabe literal escapen): die Pattern-Baustellen
  nutzen durchweg `vim.pesc` oder eine handgeschriebene, vollständige
  Metazeichen-Klasse. Zwei Stellen ohne Escape (`case/render.lua`s
  `snow_prefix`, `case/ui.lua`s `label`) bekommen dokumentierte, aktuell
  alphanumerische Konstanten — kein Nutzereingabe-Pfad.
- **`SEC-20`/`21`/`23`** (Downloads): die Config lädt keine Binaries. Der
  einzige Netzwerkpfad ist `case/linkcheck.lua`s `HEAD`-Anfrage über
  `lib.nvim.net.curl`, mit `timeout_ms`.
- **`ERR-33`/`LUA-13`** (Handles in verzögerten Callbacks): ein Scan über
  alle `vim.schedule`/`vim.defer_fn`-Blöcke fand zwei Kandidaten
  (`explorer-singleton.lua`, `custom_menu/init.lua`); beide lesen ihre
  Handles **frisch im Callback** statt sie einzufangen.
- **`ERR-62`** (`pcall(f(args))` fängt nichts): kein einziger Treffer, alle
  Stellen sind `pcall(function() … end)` oder `pcall(fn, args)`.
- **`XP-06`** (Modulpfad-Schreibweise): 321 verschiedene `require`-Ziele
  gegen 251 Module auf Platte geprüft — **0** Abweichungen. Der Linux-CI-
  Runner kann daran nicht scheitern.
- **`PERF-92`** (keine Layout-Geometrie auf Modulebene): alle zwölf
  `vim.o.columns`/`vim.o.lines`-Lesungen liegen in Funktionskörpern, werden
  also pro Öffnen berechnet.
- **`PERF-93`** (heißes Event nie ungeschützt): alle vier Handler auf
  `CursorMoved`/`TextChanged`/`WinScrolled` sind **buffer-lokal**
  registriert, laufen im normalen Editier-Buffer also gar nicht erst an.
  `CursorHold` verlässt den häufigen Fall über einen `buftype`-Vergleich.
- **`LUA-17`** (`vim.g` ist kein Transportweg): die vier `vim.g.*`-
  Zuweisungen sind reine Datentabellen für Vimscript-Plugins (matchup,
  mkdp, VM) — keine Funktionen, keine Metatables.
- **`UI-55`** (sichtbare Fenster vor dem Löschen umleiten): an einem echten
  Split nachgestellt — solange ein anderer gelisteter Buffer existiert,
  setzt Neovim die Fenster selbst darauf. Bleibt keiner übrig, ist ein
  Scratch-Buffer die einzig mögliche Antwort.

---

## Methodik-Notiz

`run_all.lua`/`rules_init.lua` (headless-Bootstrap plus Schleife über alle
Familien) waren bewusst Wegwerf-Skripte im Scratchpad, nicht committetes
Werkzeug — nach `TOOLS/TOOL-PLACEMENT.md` § 1: die Frage war einmalig zu
beantworten, das Ergebnis ist dieses Dokument, und `:Rules check` ist für
den Wiederholungsfall schon da.

# Config-DEFAULTS-Purity-Sweep: Gegencheck + zwei Nachträge

**Status:** Abgeschlossen. Ein echter Nachtrag gefixt (reposcope.nvim), ein
offener Punkt geprüft und mit negativem (= beruhigendem) Ergebnis geschlossen.
**Ausgangspunkt:** `docs/ROADMAP/personal/All/FINISH/ERLEDIGT/2026-09-12-config-defaults-purity-sweep.md`
(dorthin verschoben, dort steht die ursprüngliche Analyse).

## Methode

Anders als beim vorherigen Report (`../personal/All/FINISH/ERLEDIGT/pdfport-health-checkhealth-dedup.md`)
enthielt dieser fast nur "erledigt"-Behauptungen. Statt sie zu übernehmen,
wurden sie gegen den aktuellen Quelltext verifiziert:

| Behauptung | Verifiziert? |
|---|---|
| pickers.nvim `DEFAULTS.lua` pure (`repos_dir = nil`) | ✅ stimmt |
| casedesk.nvim `DEFAULTS.lua` pure (`repos_dir` hardcoded, Kommentar) | ✅ stimmt |
| reposcope.nvim `DEFAULTS.lua` pure (`clone.std_dir` verschoben) | ⚠️ nur teilweise — siehe unten |
| color_my_ascii.nvim Timer-Leak in `cache_manager.setup_auto_cleanup` gefixt | ✅ stimmt, Stop-vor-Neuerzeugen vorhanden |
| `debounce_manager.setup_auto_cleanup` (zweite Stelle, nicht im Report genannt) | ✅ geprüft, augroup-basiert, nie betroffen |
| WKDBooks-Checklist `LUA-06`-Beleg korrekt (nur `clone.std_dir` behauptet) | ✅ stimmt, keine Überbehauptung |

## Fund 1: reposcope.nvim war nur halb LUA-06-konform

`config/DEFAULTS.lua` löste `clone.std_dir` bereits korrekt aus (Fix vom
12.09.), las aber weiterhin `GITHUB_TOKEN`/`GITLAB_TOKEN`/`CODEBERG_TOKEN`
über `reposcope.utils.env.get()` **auf Modul-Ebene** — dieselbe Datei, exakt
dasselbe verbotene Muster, einfach nie Teil der ursprünglichen Untersuchung
(die durch den pickers.nvim-Perf-Fund ausgelöst wurde und sich auf `env.get()`
via `lib.nvim.system.env` konzentrierte, nicht auf den separaten, lokalen
`reposcope.utils.env`-Wrapper).

**Fix** (`f7bb0c9`, [reposcope.nvim](https://github.com/StefanBartl/reposcope.nvim/commit/f7bb0c9)):
- `config/DEFAULTS.lua`: die drei Felder auf statische `""`-Platzhalter,
  Kommentar analog zu `clone.std_dir`.
- `config/init.lua`: Auflösung direkt nach dem `require`, gleiche Stelle wie
  `clone.std_dir` schon.

**Nebenfund beim Fixen:** Diese Maschine hat `GITHUB_TOKEN` gesetzt.
`TESTS/config_spec.lua` pickt sich generisch "irgendein skalares
DEFAULTS-Feld" und vergleicht `config.options[key]` gegen `DEFAULTS[key]` —
mit dem Fix hätte das brechen können, wäre der Picker zufällig auf einen der
drei Token-Keys gefallen (`config.options` hat dann den echten Token,
`DEFAULTS` den Platzhalter). `clone.std_dir` entgeht dem nur, weil es eine
Tabelle ist, kein Skalar. Test angepasst: Picker schließt die drei Felder
jetzt explizit aus. Volle Suite vor/nach grün.

⚠️ **Sicherheitsvorfall dabei:** Beim Verifizieren per Headless-Nvim-Befehl
wurde versehentlich der echte `GITHUB_TOKEN`-Wert dieser Maschine in die
Tool-Ausgabe gedruckt (stand damit kurz im Chat-Verlauf dieser Sitzung). Dem
Nutzer direkt im Chat gemeldet, mit der Empfehlung, den Token zu rotieren.
Für künftige Verifikationen dieser Art: nur Länge/Vorhandensein eines
Secrets ausgeben, nie den Wert selbst.

WKDBooks-Checklist (`LUA_NVIM.md`, `LUA-06`-Beleg) um einen Nachtrag
ergänzt, der das jetzt vollständige Bild dokumentiert
(commit `a03ca7c` im WKDBooks-Repo).

## Fund 2 (negativ, aber jetzt verifiziert): Cross-Plugin-`require`-Check (LUA-93-Risiko)

Der Report ließ eine Frage explizit offen: könnte irgendeines der 17
"reinen Load-Guard"-Plugins (buffer-ctx, cascade, dap, debugging, diff,
emojis, fileops, gopath, images, insights, language, markdown, mdview,
open, pdfport, recommender, spotlight) von einem *anderen* Modul per nacktem
`require(...)` gezogen werden, ohne über den eigenen lazy.nvim-Trigger zu
laufen — wodurch `setup()` nie liefe (der bekannte `LUA-93`-Bugtyp,
dokumentiert bei blink.cmp/nvim-ts-autotag)?

**Geprüft:** Volltextsuche über die gesamte nvim-Config nach jedem
`require("<plugin>"...)`/`pcall(require, "<plugin>"...)` außerhalb der
jeweils eigenen `lua/plugins/personal/init.lua`-Spec. Treffer gab es für
`images`, `gopath`, `markdown`, `pdfport`, `open`, `emojis`, `language` — alle
in `lua/bindings/usrcmds/context_open/` (der `M-o`/`:ContextOpen`-Dispatcher)
sowie vereinzelt in `case/`- und `config/fzf|telescope`-Modulen.

**Ergebnis: kein Risiko.** Jede dieser Stellen ist entweder:
- explizit per `lazy.core.loader.load()` vorab geladen
  (`context_open/util.lua`s `ensure_loaded()`, für `open.nvim`), oder
- in `pcall(require, ...)` gewrappt und fällt bei nicht geladenem Plugin
  sauber auf "keine Kandidaten" zurück (kein Crash, keine Arbeit mit
  uninitialisiertem Zustand).

Der eigentliche `LUA-93`-Mechanismus (ein Plugin landet als Nebeneffekt
einer fremden `dependencies`-Deklaration auf dem Runtimepath, OHNE dass
`setup()`/`opts` je liefe) tritt hier nicht auf: keine andere Plugin-Spec in
`personal/init.lua` deklariert eines der 17 Load-Guard-Plugins als
`dependencies` (verifiziert per Volltextsuche). Ohne diesen Pfad bleibt ein
zu früher `require()` entweder ein sauberer "Modul nicht gefunden"-Fehler
(abgefangen) oder läuft — wenn schon getriggert — ganz normal durch
lazy.nvim inklusive `setup()`.

**Damit geschlossen, ohne Codeänderung nötig.**

## Nebenbefund: lazy-installierte Kopie von reposcope.nvim hatte dieselbe veraltete Historie

Wie bei pdfport.nvim/images.nvim/mdview.nvim zuvor: `nvim-data/lazy/reposcope`
(Achtung, `name = "reposcope"` in der Spec — nicht `reposcope.nvim`) war
287 Commits vor / 264 hinter `origin/main`, gleiches Muster (History-Rewrite,
Commit-Messages identisch unter anderen Hashes in `E:\repos`). Per
`git reset --hard origin/main` bereinigt, kein Code-Verlust.

## Offene Punkte

Keine. Beide Fragen aus dem alten Report (Punkt 6) sind jetzt beantwortet:
"eager-statisch vs. Load-Guard" war schon im alten Report beantwortet, der
Cross-Plugin-`require`-Check ist jetzt nachgeholt (Ergebnis: unbedenklich).

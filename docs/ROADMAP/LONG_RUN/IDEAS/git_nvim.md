# `git.nvim` — Konzept

> Arbeitstitel. `git.nvim` ist auf GitHub mehrfach vergeben (u. a.
> `dinhhuy258/git.nvim`, `akinsho/git-conflict.nvim` als Nachbar im Namensraum).
> Der Lua-Modulwurzel-Name ist das eigentliche Kollisionsrisiko, nicht der
> Repo-Name — siehe [Offene Fragen](#offene-fragen).

Angelegt 2026-09-17 aus dem Stub in dieser Datei, auf Basis von
[`Externe-Plugins-Nachbau-Analyse.md`](../../personal/All/FINISH/ERLEDIGT/Externe-Plugins-Nachbau-Analyse.md)
und einer Erhebung der tatsächlichen Git-Oberfläche dieser Config.

## Table of content

  - [Problem](#problem)
  - [Idee in einem Satz](#idee-in-einem-satz)
  - [Bestandsaufnahme](#bestandsaufnahme)
    - [Extern installiert (7)](#extern-installiert-7)
    - [Eigener Bestand, der schon Git kann](#eigener-bestand-der-schon-git-kann)
  - [Die Feature-Familien in drei Schichten](#die-feature-familien-in-drei-schichten)
    - [Schicht 1 — schon da oder billig selbst zu bauen](#schicht-1-schon-da-oder-billig-selbst-zu-bauen)
    - [Schicht 2 — orchestrierbar, Backend bleibt extern](#schicht-2-orchestrierbar-backend-bleibt-extern)
    - [Schicht 3 — niemals nachbauen](#schicht-3-niemals-nachbauen)
  - [Bewertung: nachbauen oder orchestrieren?](#bewertung-nachbauen-oder-orchestrieren)
    - [Variante A — alles selbst nachbauen](#variante-a-alles-selbst-nachbauen)
    - [Variante B — reine Orchestrierung](#variante-b-reine-orchestrierung)
    - [Variante C — Hybrid](#variante-c-hybrid)
  - [Empfehlung](#empfehlung)
  - [Architektur](#architektur)
  - [Auswirkung auf die nvim-Config](#auswirkung-auf-die-nvim-config)
    - [Was verschwindet](#was-verschwindet)
    - [Plugin-Bilanz](#plugin-bilanz)
    - [Was sich für die Bedienung ändert](#was-sich-fr-die-bedienung-ndert)
  - [Aufwand](#aufwand)
  - [Risiken und Abgrenzung](#risiken-und-abgrenzung)
  - [Offene Fragen](#offene-fragen)
  - [Literatur und Referenzen](#literatur-und-referenzen)

---

## Problem

Git ist in dieser Config auf **sieben externe Plugins**, **526 Zeilen
Config-Code** und mindestens **sechs Einstiegspunkte** verteilt, die
voneinander nichts wissen:

| Einstieg | Wohin |
|---|---|
| `<leader>lg` | lazygit.nvim |
| `<leader>gg` | neogit |
| `<leader>gd` / `<leader>gb` | vim-fugitive |
| `<leader>dv` / `<leader>dc` / `<leader>dh` | diffview.nvim |
| `<leader>di` | eigener `:ToggleInlineDiff` über gitsigns |
| `<leader>fgs` | fzf-lua `git_status` |
| sieben `<leader>`-Tasten | pickers.nvim → snacks `git_*` |
| Rechtsklick → Git | zwölf Einträge über gitsigns |
| `:GitConflict*` (9 Commands) + `co`/`ct`/`cb`/`c0`/`]x`/`[x` | git-conflict.nvim |
| Neo-tree `git_status`-Source | neo-tree |

Das ist dasselbe Muster, das `debugging.nvim`, `filetree.nvim` und `dap.nvim`
jeweils für ihre Domäne aufgelöst haben: verstreute Einzel-Commands, deren Namen
man kennen muss, bevor man sie benutzen kann. Für Git ist es hier besonders
ausgeprägt, weil **vier verschiedene Plugins dieselbe Frage beantworten** („zeig
mir den Diff") und drei davon nur wegen je ein bis drei Commands installiert sind.

---

## Idee in einem Satz

**Ein `:Git <scope> <action>`-Kommandobaum mit Provider-Registry, der die
Familien selbst implementiert, in denen eigener Code schon existiert oder billig
ist, und die verbleibenden an austauschbare Backends delegiert** — die Form, die
`filetree.nvim` über neo-tree/nvim-tree/oil/netrw/mini.files bereits hat.

---

## Bestandsaufnahme

### Extern installiert (7)

| Plugin | Konfigurierte Oberfläche | Trigger |
|---|---|---|
| `git-conflict.nvim` | `config = true` — neun Default-Commands, sechs buffer-lokale Tasten, nichts eigenes konfiguriert | `BufReadPost`, `BufNewFile` |
| `gitsigns.nvim` | `config = true` + zwölf Menüeinträge + eigener `:ToggleInlineDiff` | `BufReadPre`, `BufNewFile` |
| `diffview.nvim` | `config = true`, drei Commands benutzt (`Open`, `Close`, `FileHistory`) | `cmd` |
| `neogit` | `kind = "split"`, `integrations.diffview = true`, eine Taste | `cmd` |
| `vim-fugitive` | **zwei** Tasten: `:Gdiffsplit`, `:Git blame` | `VeryLazy` |
| `vim-rhubarb` | **ein** Command: `:Gbrowse` | `VeryLazy` |
| `lazygit.nvim` | eine Taste + 146 Zeilen `nvr`-Brücke (`:LazygitBadd`, `:LazygitReplace`) | `cmd` |

Dazu als Abhängigkeitskette: `plenary.nvim` hängt an lazygit, diffview und
neogit; `telescope-github.nvim` ist git-benachbart, gehört aber zu
reposcope/github_stats (siehe die Nachbau-Analyse).

---

### Eigener Bestand, der schon Git kann

Das ist der entscheidende Teil — es wird **nicht bei null angefangen**:

| Modul | Was es heute kann |
|---|---|
| `lib.nvim/nvim/git` | `in_git_repo`, `repo_root`, `current_branch`, `is_detached_head`, `is_dirty`, `is_tracked`, `upstream`, `ahead_behind`, `head_short_hash`, `info`, `refs`, `status_porcelain`, `clear_line_diff` — dreizehn Primitive, keine Fremdabhängigkeit |
| `diff.nvim/core/git` | Auflösung von `git:HEAD`, `git:HEAD~1`, `git:<sha>`, `git:<branch>` gegen die aktuelle Datei; `git show` über `vim.system`, plattformunabhängig, ohne Shell. `git:HEAD` steht bereits in der `:Diff`-Completion |
| `insights.nvim/conflicts` | Repo-weiter Report unaufgelöster Merge-Konflikte (`unmerged`-State) in die Quickfix-Liste |
| `ui.nvim/statusline/modules/git_clickable` | **Abhängigkeitsfreier Branch-Switcher** per Linksklick plus Kontextmenü — dokumentiert als „braucht weder gitsigns noch irgendein Git-Plugin, nur `git` im `$PATH`" |
| `sessions.nvim/git` | `current_branch`, `project_root` — Sessions lösen branch-abhängig auf |
| `filetree.nvim/features/git/git_status` | Git-Status im Baum, adapterunabhängig |
| `reposcope.nvim` | GitHub/GitLab/Codeberg: Suche, Clone, Bulk-`git status`, Fetch-and-Pull über einen ganzen Ordner |
| `github_stats.nvim` | Traffic-Historie |

---

## Die Feature-Familien in drei Schichten

Die Erhebung trennt sauber. Das ist das eigentliche Ergebnis dieser Analyse:

---

### Schicht 1 — schon da oder billig selbst zu bauen

| Familie | Stand | Aufwand |
|---|---|---|
| **Konflikt-Auflösung im Buffer** (`:GitConflict*`) | Markererkennung (`<<<<<<<` / `\|\|\|\|\|\|\|` / `=======` / `>>>>>>>`), Extmark-Highlight der drei Abschnitte, vier Choose-Varianten, Navigation, Refresh — reine Puffer-Textarbeit, kein Git-Plumbing. `:GitConflictListQf` ist **exakt** das, was `insights.nvim/conflicts` schon tut | **M–L** |
| **`:Gdiffsplit`** | `diff.nvim` kann es heute. Nur umbinden | **S** |
| **`:Gbrowse`** | `open.nvim` (Routing) + `reposcope.nvim` (Remote-URL-Formen der drei Hoster) | **S–M** |
| **lazygit-Float** | `lib.nvim` hat `terminal/`, `window/`, `git/`, `cross/` | **S** |
| **`nvr`-Brücke** | 146 Zeilen, **schon geschrieben**, nur am falschen Ort | **M** (Umzug) |
| **Branch-Switcher** | `ui.nvim` hat ihn, abhängigkeitsfrei | **S** (herausziehen) |
| **Repo-Status / ahead-behind / refs** | `lib.nvim/nvim/git` | **—** |

---

### Schicht 2 — orchestrierbar, Backend bleibt extern

Hunk-Aktionen (stage/reset/preview, Buffer wie Hunk), Blame-Zeile und
Blame-Toggle, `diffthis` gegen `~`, Side-by-side-Diff, File-History, der
Staging-Puffer. Diese Familien bekommen einen **Provider-Slot**: `git.nvim`
definiert die Aktion, ein Adapter führt sie aus.

---

### Schicht 3 — niemals nachbauen

**gitsigns' Hunk-Engine** (inkrementeller Diff bei jeder Änderung plus
Sign-Verwaltung) und **neogits Staging-UI**. Beides ist jahrelange
Edge-Case-Arbeit, und beides ist genau das, was ein Adapter-Slot billig
delegierbar macht.

Ein Befund am Rande, der eine frühere Vermutung korrigiert:
`insights.nvim/conflicts` und `git-conflict.nvim` sind **keine Duplikate**. Das
eine fragt Git nach Dateien im `unmerged`-Zustand (Repo-Ebene), das andere
zerlegt Marker im Puffer (Zeilen-Ebene). Sie ergänzen sich — und zusammen
ergeben sie `:GitConflictListQf` plus die acht anderen Commands.

---

## Bewertung: nachbauen oder orchestrieren?

### Variante A — alles selbst nachbauen

Sieben Plugins ersetzen heißt, gitsigns' Hunk-Engine und neogits Staging-UI zu
schreiben. Das sind nicht sieben Features, das sind zwei eigene Projekte plus
fünf Features. **Zahlt sich nicht aus**, und es widerspricht dem eigenen Muster:
`filetree.nvim` baut neo-tree nicht nach, `dap.nvim` baut nvim-dap nicht nach.

---

### Variante B — reine Orchestrierung

Ein `:Git`-Baum über alle sieben, nichts selbst implementiert. Besser, aber
lässt Wert liegen: vier der sieben Plugins sind wegen ein bis drei Commands
installiert, die Schicht 1 ohnehin billig abdeckt. Nach Variante B stünden
weiterhin sieben Repos im Baum, nur mit einheitlicher Grammatik davor.

---

### Variante C — Hybrid

Orchestrator **mit eigener Implementierung dort, wo Schicht 1 gilt**. Das ist
wörtlich `filetree.nvim`s Aufbau: ein `adapter/`-Registry mit
`register`/`resolve(name|"auto")`/`is_available()`, daneben ein `features/`-Baum,
dessen Module adapterunabhängig sind.

---

## Empfehlung

**Variante C**, und die Konflikt-Familie zuerst — nicht weil sie die größte ist,
sondern weil sie die drei Kriterien gleichzeitig erfüllt: sie ist der
Arbeitsablauf, der hier täglich läuft; sie ist technisch die zugänglichste (reine
Puffer-Textarbeit, kein Git-Plumbing); und ihr Repo-Ende ist mit
`insights.nvim/conflicts` schon geschrieben.

Zielgrammatik, nach `NEW-23` (`lib.nvim.usercmd.composer`, Completion aus
geschlossenen Mengen per `NEW-26`, live wo der Zustand es verlangt):

```
:Git conflict  ours|theirs|both|base|none|next|prev|list|refresh
:Git hunk      stage|reset|preview|stage-buffer|reset-buffer|toggle-deleted
:Git blame     line|toggle|full
:Git diff      head|last|rev <rev>|split|history
:Git branch    switch|list|current
:Git browse    file|selection|repo
:Git ui        lazygit|neogit|diffview
:Git status    repo|quickfix
```

`:Git conflict *` ist eigener Code. `:Git hunk *` und `:Git blame *` gehen an
den Provider. `:Git diff head|last|rev` geht an `diff.nvim`, `:Git browse` an
`open.nvim`/`reposcope.nvim`, `:Git ui *` an das jeweilige TUI.

---

## Architektur

Nach `NEW-07`/`NEW-08`/`NEW-09`/`NEW-10`, mit `filetree.nvim` als Vorlage für
`adapter/` und `dap.nvim` für `registry.lua`:

```
git.nvim/
  lua/git/                      -- Modulwurzel, siehe Offene Fragen
    adapter/
      init.lua                  -- register / resolve("auto") / is_available
      gitsigns.lua              -- Hunks, Blame, diffthis
      diffview.lua              -- Side-by-side, File-History
      neogit.lua                -- Staging-UI
      lazygit.lua               -- TUI + nvr-Brücke
      native.lua                -- nur `git` im $PATH, Fallback für alles Mögliche
    features/
      conflict/                 -- EIGEN: Parser, Highlight, Resolve, Navigation
      blame/                    -- eigen (native) oder delegiert
      browse/                   -- eigen, über open.nvim + reposcope.nvim
      branch/                   -- eigen, aus ui.nvim herausgezogen
      hunk/                     -- delegiert
      diff/                     -- an diff.nvim
      status/                   -- lib.nvim/nvim/git + insights.nvim/conflicts
      ui/                       -- TUI-Start + nvr-Brücke
    integrations/
      diff_nvim.lua  insights_nvim.lua  reposcope_nvim.lua
      open_nvim.lua  pickers_nvim.lua   ui_nvim.lua
    config/{init,DEFAULTS}.lua
    bindings/{keymaps,usrcmds,autocmds}.lua
    @types/init.lua
    health.lua
  TESTS/  scripts/  doc/git.txt  docs/BINDINGS.md
  README.md  .luarc.json  stylua.toml  .luacheckrc
```

Der `native.lua`-Adapter ist die wichtigste Designentscheidung: **jede Familie
braucht einen Pfad, der nur `git` im `$PATH` voraussetzt.** `ui.nvim`s
Branch-Switcher beweist, dass das trägt, und `lib.nvim/nvim/git` liefert die
Primitive dafür bereits. Damit ist `git.nvim` ohne ein einziges externes
Git-Plugin benutzbar, und jedes installierte Plugin ist eine Verbesserung statt
einer Voraussetzung — dieselbe Eigenschaft, die `filetree.nvim` über netrw hat.

---

## Auswirkung auf die nvim-Config

### Was verschwindet

| Datei | Zeilen | Wohin |
|---|---|---|
| `lua/plugins/git.lua` | 99 | eine Zeile in `plugins/personal/init.lua` |
| `lua/config/lazygit/**` | 146 | `features/ui/` |
| `lua/config/menu/git.lua` | 126 | `features/hunk/`, `features/blame/`, `features/diff/` |
| `lua/bindings/mappings/git.lua` | 99 | `bindings/keymaps.lua` |
| `lua/config/neotree/keymaps/git_status.lua` | 56 | `filetree.nvim` (eigener Posten) |
| **Summe** | **526** | |

---

### Plugin-Bilanz

| | Vorher | Nachher (Phase 4) | Nachher (Endausbau) |
|---|---|---|---|
| Externe Git-Plugins | 7 | 3 (gitsigns, diffview, neogit) | 1–3 |
| Eigene | 0 dediziert | 1 (`git.nvim`) | 1 |
| `plenary`-Konsumenten in der Git-Gruppe | 3 | 2 | 0–2 |

Weg sind nach Phase 4: **vim-fugitive, vim-rhubarb, git-conflict.nvim,
lazygit.nvim** — vier Repos, davon drei, die wegen ein bis drei Commands da
waren. Ob diffview später in `diff.nvim` aufgeht, ist eine eigene Entscheidung
und kein Teil dieses Konzepts.

---

### Was sich für die Bedienung ändert

Die neun `:GitConflict*`-Commands und die sechs buffer-lokalen Tasten
(`co`/`ct`/`cb`/`c0`/`]x`/`[x`) sind der einzige Ort, wo Muskelgedächtnis auf
dem Spiel steht. Die Tasten bleiben eins zu eins erhalten — sie sind
buffer-lokal und werden ohnehin erst gesetzt, wenn der Puffer einen Konflikt
enthält. Für die Commands bietet sich eine Übergangszeit mit Aliassen an
(`:GitConflictChooseOurs` → `:Git conflict ours`), die nach ein paar Wochen
fällt.

---

## Aufwand

Maßstab wie in der Nachbau-Analyse: eine Session ≈ ein konzentrierter halber Tag.

| Phase | Inhalt | Sessions |
|---|---|---|
| **0** | Skelett nach `NEW_PROJECT.md`: Repo, Struktur, `health.lua`, `TESTS/` mit lautem Runner (`NEW-40`), `.luarc.json`, `stylua.toml`, `.luacheckrc` mit busted-`std` (`NEW-49`), CI, README/vimdoc/BINDINGS. Templates existieren | 1–2 |
| **1** | `:Git`-Composer über `lib.nvim.usercmd.composer`, Adapter-Registry, `native.lua`, Provider-Auflösung, `:checkhealth` | 2–3 |
| **2** | **`features/conflict/`** — Parser inkl. `diff3`/`zdiff3`-Ancestor, Extmark-Highlight, fünf Choose-Varianten, Navigation, Refresh, `list` über `insights.nvim`. Mit Tests | 3–4 |
| **3** | Delegierende Familien: `hunk`, `blame`, `diff`, `ui` (inkl. `nvr`-Brücke aus `config/lazygit`) | 2–3 |
| **4** | Eigenes: `browse` (open/reposcope), `branch` (aus `ui.nvim`), `status` | 2–3 |
| **5** | Config-Migration: 526 Zeilen raus, Menü-Sektion, Statusline-Kopplung, Keymaps, Extern-Korpus unter `docs/NOTES/ExternPlugins/Bindings` nachziehen | 2–3 |
| **6** | Doku: `docs/BINDINGS.md`, vimdoc, README nach Template, `:DocMap` (`NEW-19`/`NEW-20`) | 1–2 |
| | **Summe** | **13–20** |

Zum Vergleich: Variante A käme mit gitsigns (**10+**) und neogit (**15+**) auf
das Doppelte bis Dreifache, für Funktionalität, die heute schon funktioniert.

**Erster sinnvoller Schnitt nach Phase 2** (6–9 Sessions): `git-conflict.nvim`
fliegt raus, der Arbeitsablauf, der hier täglich läuft, gehört dann dir, und das
Gerüst steht für alles Weitere.

---

## Risiken und Abgrenzung

**Der Konflikt-Parser ist die einzige Stelle mit echtem Korrektheitsrisiko.**
Falsch aufgelöste Marker heißen verlorener Code in einem halbfertigen Merge.
Absicherung: Tests gegen echte Konfliktdateien in allen drei Stilen (`merge`,
`diff3`, `zdiff3`), verschachtelte und mehrfache Konflikte pro Puffer, und
`NEW-43` beachten — kein Testfall, der sich selbst überspringt. Vor dem ersten
Produktiveinsatz beide Implementierungen parallel laufen lassen und die
Ergebnisse vergleichen.

**gitsigns hat Konsumenten außerhalb dieser Config.** Ein Grep über die eigenen
Repos findet Referenzen in `fileops.nvim`, `hover.nvim`, `my.nvim` und
`lib.nvim` (`contextmenu`, `ui/kit/menu`). gitsigns bleibt in Variante C
ohnehin, aber wenn `git.nvim` die Hunk-Familie kapselt, sollten diese Stellen
mittelfristig über `git.nvim` gehen statt direkt — sonst gibt es wieder zwei
Wege zur selben Aktion.

**Die Statusline ist gekoppelt.** `ui.nvim`s `primitives.git()` braucht gitsigns
für den *gerenderten Text*, die Klick-Aktionen nicht. Wenn `git.nvim` die
Statusline beliefern soll, ist das ein eigener Posten, kein Nebeneffekt.

**Kein Ersatz für `reposcope.nvim`.** Repo-Suche, Clone und Bulk-Operationen
über einen Ordner bleiben dort. `git.nvim` ist *ein* Repository, `reposcope` ist
*viele* — die Grenze sauber halten, sonst wachsen beide ineinander.

**`NEW-14` beachten:** keine `docs/ROADMAP.md` im Repo und kein Verweis auf das
Wkdbook irgendwo im Plugin. Die Roadmap gehört nach
`wkdbook-myplugins/git.nvim/ROADMAP/ROADMAP.md`.

---

## Offene Fragen

1. **Modulwurzel.** `require("git")` ist ein sehr allgemeiner Name und genau die
   Kollisionsart, an der `hover.nvim` schon einmal hing (dessen README warnt
   explizit vor `lewis6991/hover.nvim` — die Repo-Namen kollidieren nicht, die
   Lua-Modulwurzel schon). Kandidaten: `wkdgit`, `gitdesk`, `vcs`. Vor `NEW-01`
   entscheiden, danach ist es teuer.
2. **Gehört `diff`/`history` überhaupt hier hinein**, oder ist `:Git diff` nur
   ein Alias auf `diff.nvim` und File-History wächst dort? Letzteres wäre
   sauberer, macht `git.nvim` aber von `diff.nvim` abhängig.
   -> diff.nvim als dep ist kein problem,. machen wir das so
3. **Soll `native.lua` Blame selbst können** (`git blame --porcelain` parsen,
   virtueller Text) oder bleibt Blame delegiert? Blame ist die einzige Familie,
   für die im eigenen Bestand **nichts** existiert — ein Grep über `lib.nvim`,
   `diff.nvim`, `insights.nvim`, `ui.nvim`, `sessions.nvim` findet keinen
   Treffer.
   Was meisnt du mit native.lua ? generell_> wenn es ein feature ist, das entweder eijfach nachbaubar oder von mehrereh pplugin sverwendet weren würde dann selbstg bauen
4. **Migrationsfenster für die neun Commands** — Aliasse mit Deprecation-Notice,
   oder harter Schnitt mit einem Eintrag im Extern-Korpus?
   Harter Schnitt

Zusatz: lib.nvim kann auch erweitert werden wenn nötig; gdas neue git.nvim bzw lib.nvim kann features imlementieren, die dann meine naderen plugins verwnen können

---

## Literatur und Referenzen

**Eigene Vorlagen und Regeln**

- `wkdbook-Lua/Checklists/gates/NEW_PROJECT.md` — `NEW-01` … `NEW-50`,
  insbesondere `NEW-07`/`NEW-08` (Struktur), `NEW-10` (health), `NEW-23`
  (Compound-Command), `NEW-26` (Completion als Pflicht), `NEW-40` (Runner
  scheitert laut), `NEW-43`/`NEW-47` (Testfallen), `NEW-14` (Roadmap-Ort)
- `wkdbook-Lua/Checklists/regeln/PRINCIPLES.md`, `LUA_NVIM.md` — Architektur,
  `lib.nvim`-Verwendung, LuaLS-Annotationen
- `wkdbook-myplugins/TEMPLATES/README-NVIM-PLUGIN/` — README-Struktur,
  Badge-Reihenfolge, Schwesterplugin-Blockquote

**Muster im eigenen Bestand**

- `filetree.nvim` — `adapter/init.lua` (`register`, `resolve(name\|"auto")`,
  `is_available`) plus adapterunabhängiger `features/`-Baum. **Das Vorbild.**
- `dap.nvim` — `registry.lua`, `adapters/`, `configurations/`, `languages/`:
  Registrierungsschicht über einem fremden Kern
- `debugging.nvim` — `:Debug {category} {action}` als Beleg, dass ein
  Dispatcher über verstreute Commands trägt
- `pickers.nvim` — engine-agnostische Auslieferung, hier für alles Listenartige

**Extern, als Referenzimplementierung zu lesen**

- `akinsho/git-conflict.nvim` — `lua/git-conflict.lua`, `setup_commands` und
  `setup_buffer_mappings`; die Marker-Parser-Logik ist die eigentliche Vorlage
  für `features/conflict/`
- `lewis6991/gitsigns.nvim` — für die Adaptergrenze, nicht zum Nachbauen
- `tpope/vim-rhubarb` — URL-Formen der Hoster für `features/browse/`

**Config-interne Belege**

- `docs/ROADMAP/reports/Externe-Plugins-Nachbau-Analyse.md` — Feature-Familien
  und Aufwände aller externen Plugins
- `docs/NOTES/ExternPlugins/Bindings/Usercmds/GitConflict.md` — die neun
  Commands und sechs Tasten vollständig
- `docs/NOTES/ARCHITECTURE/startup.md` — Startup-Kosten der Git-Gruppe

---


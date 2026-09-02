## Kurzanalyse

**Korrektur zur Verortung:** `bindings_explorer` liegt nicht in `lib.nvim`, sondern in dieser nvim-Config selbst, unter [`lua/bindings/usrcmds/bindings_explorer/`](./lua/bindings/usrcmds/bindings_explorer/init.lua). `lib.nvim` hat ein eigenes, andersartiges Modul (`lib/nvim/bindings/audit.lua` — Keymap-vs-Command-Lücken für die *aktuelle Session*, nicht Doku-vs-Live). Für die Umsetzung ändert das die Richtung: kein Cross-Repo-Feature nötig, es bleibt im Config-Repo.

**Die eigentliche Lücke, die dein Vorschlag trifft — gefunden in [`drift.lua:507`](./lua/bindings/usrcmds/bindings_explorer/drift.lua:507):**

```lua
if (not plugin or rec.plugin == plugin) and is_plugin_loaded(rec.plugin) then
  -- geprüft
elseif not plugin or rec.plugin == plugin then
  skipped[rec.plugin] = true  -- NICHT geprüft, nur gemeldet als "übersprungen"
end
```

Eine dokumentierte Bindung wird nur gegen Neovims Live-Zustand geprüft, wenn das Plugin **in dieser Session bereits geladen** ist (`lazy.core.config`-Check). Lazy-geladene Plugins, deren Trigger-Event noch nicht gefeuert hat, oder Plugins, die man in der aktuellen Session gar nicht angerührt hat, fallen komplett aus der Prüfung — sie landen als „skipped", nicht als „geprüft und korrekt". Genau das war bei `lsp.nvim` gestern kein Problem, weil ich es aktiv geladen hatte — bei den anderen 22 personal-Plugins wäre es eines.

**Der Baustein für die Alternative existiert schon**, und er ist bereits genau so gebaut, wie du es forderst — konfigurierbar, nicht hartkodiert: [`plugins/personal/export.lua`](./lua/plugins/personal/export.lua) liefert `{ name, repo, dir }` für jedes aktivierte Plugin mit lokalem Checkout, aufbauend auf `plugins/personal/list.lua`. Das ist bereits die „verpflichtende Liste" — nur eben zur Laufzeit aus dem Lazy-Spec abgeleitet, nicht aus einer Markdown-Datei (die Roadmap-Notiz in `list.lua` beschreibt genau, warum: eine handgepflegte Liste war schon mal die Ursache für Drift).

**Was `check_repo` zusätzlich könnte, was der Live-Check nicht kann:** den lokalen Checkout-Pfad eines Plugins direkt durchsuchen (grep nach dem `lhs`/Commandnamen im Quellcode), unabhängig davon, ob das Plugin in dieser Session je geladen wurde. Das deckt die 22 anderen Plugins ab, nicht nur die, die man gerade zufällig geöffnet hat.

---

## Workorder: `:Bindings check` — `repo`-Achse

**Ziel:** Eine dritte Prüfachse neben „live in dieser Session": den lokalen Plugin-Checkout direkt durchsuchen. Deckt genau die Lücke, die `is_plugin_loaded` heute als „skipped" durchwinkt.

**Scope-Entscheidung (zur Bestätigung vor dem Bauen):** Personal-only, wie die bestehenden zwei Achsen — Extern dokumentiert fremden Code, den diese Config nicht selbst registriert, dieselbe Begründung wie in `drift.lua`s Docstring für die bestehende Beschränkung.

1. **Neuer Resolver, injizierbar statt hartkodiert.** `config.lua` bekommt eine Funktion, die `{name, dir}`-Paare liefert — Default-Implementierung ruft `plugins.personal.export.projects()`, aber als austauschbare Funktion (`M.repo_dirs()` o.ä.), nicht als fester Pfad. Macht das Modul unabhängig von `list.lua`s konkretem Speicherort und portabel, falls es je in ein eigenes Repo wandert.

2. **`drift.lua`: dritte Prüfachse `repo-not-found`.** Für jeden Keymap-/Usercmd-Record, dessen Plugin *nicht* geladen ist (heute: `skipped`), aber einen aufgelösten lokalen Checkout hat: `lhs`/Commandnamen als Literal im Quellbaum grep'en (`vim.fn.glob` + `vim.fn.readfile` oder `rg` falls vorhanden). Treffer → stillschweigend korrekt. Kein Treffer → neuer Befund-Typ, klar getrennt von den live-basierten (andere Fehlerquelle: Grep auf String-Literal ist unschärfer als eine echte API-Abfrage, false negatives bei berechneten `lhs`-Werten sind zu erwarten und müssen im Report als solche gekennzeichnet sein).

3. **`M.check`-Signatur erweitern**, ohne die bestehenden zwei Achsen zu verändern: `M.check(plugin, opts)` mit `opts.repo = true/false` (Default `false`, additiv, kein Verhaltensbruch für bestehende Aufrufer). `:Bindings check <plugin> repo` als neue Subcommand-Variante in `init.lua`.

4. **`M.describe`**: eigener Abschnitt für Repo-Funde, mit dem Hinweis, dass ein Treffer auf Quelltext-Ebene schwächer ist als eine Live-Bestätigung (String-Match, kein AST).

5. **Tests**: gegen ein Fixture-Repo (Temp-Dir mit synthetischer Lua-Datei), nicht gegen echte `C:\repos\*`-Checkouts — sonst hängt der Test-Erfolg vom Zustand fremder Repos ab.

**Aufwand:** S–M. Größter Teil ist Schritt 2 (Grep-Strategie robust gegen `lhs`-Varianten wie String-Konkatenation).

**Offene Entscheidung, die ich vor dem Bauen bräuchte:** Soll `repo` **automatisch** immer mitlaufen (dann prüft `:Bindings check` künftig alle Plugins, nicht nur geladene — teurer, aber vollständiger), oder **bewusst separat** anfordern (günstiger, aber man muss dran denken)? Meine Empfehlung: separat anfordern, Default aus — der bestehende Check ist schnell genug, um ihn beiläufig laufen zu lassen; ein Grep über 22 Repo-Checkouts ist das nicht, und sollte kein stiller Kostenfaktor werden, den man nicht angefordert hat.

---

## Umgesetzt (2026-08-30)

Alle fünf Schritte gebaut, headless verifiziert. Die offene Entscheidung ist
nach der eigenen Empfehlung entschieden: **separat anfordern, Default aus.**

| Schritt | Datei | Ergebnis |
| --- | --- | --- |
| 1 Resolver, injizierbar | `config.lua` | `M.repo_dirs()` → `{name, dir}[]` + Grund; Default ruft `plugins.personal.export.projects()`, `M.set_repo_dirs(fn)` tauscht sie. `M.config_lua_root()` dazu. |
| 2 neue Prüfachse (tatsächlich die vierte — `source.lua` kam seit der Workorder dazu) | `repo.lua` (neu), `drift.lua` | Neue Kinds `keymap-not-in-repo` / `usercmd-not-in-repo` statt eines stillen „skipped". |
| 3 Signatur additiv | `drift.lua`, `init.lua` | `M.check(plugin, opts)` mit `opts.repo`; 4. Rückgabewert `Bindings.RepoInfo`. Zwei Routen: `:Bindings check repo [plugin]` und `:Bindings check <plugin> repo`. |
| 4 eigener Abschnitt | `drift.lua` `M.describe` | „Documented, and nowhere in the plugin's own checkout", mit dem Hinweis auf String-Match statt AST. |
| 5 Tests | Fixture-Repo im Temp-Dir | 26 Assertions, keine echten `C:\repos\*`-Checkouts. |

**Über die Workorder hinaus, weil es sonst systematisch falsch gemeldet
hätte:** die Achse meldet nur, was in *keinem* der drei steht — Checkout des
Plugins, `lua/`-Baum dieser Config, gerade registrierte Keymaps/Commands. Der
`<leader>`-Einstieg eines Personal-Plugins wird sehr oft hier registriert (in
einer lazy-`keys`-Spec), nicht im Plugin selbst; ohne diesen Unterdrücker wäre
jeder davon ein Falschbefund gewesen. Und die Case-Regel ist nach Token-Art
verschieden: Keymaps case-unabhängig (`<Leader>` = `<leader>`), Commandnamen
case-abhängig — sonst trifft `:Images` das Wort „images" in jeder zweiten
Zeile von images.nvim und die Achse meldet nie etwas.

**Messung** (headless, alle 30 auflösbaren Plugins künstlich als ungeladen —
der Worst Case, für den die Achse existiert): 775–940 ms, 2861 Quelldateien,
30 von 30 Checkouts beantwortet, 0 übersprungen, **10 Findings**. 7 davon sind
`debugging.nvim`s `prefix .. "m"` (der dokumentierte Falschbefund einer
Grep-Achse), 1 ein Parser-Artefakt, 2 echte Funde — darunter `:RATelemetry`,
das in `Usercmds/lib.nvim.md` steht, aber in runtime-analysis.nvim registriert
wird. Diesen Fund kann die Live-Achse strukturell nie machen: das Command
existiert ja, nur nicht dort, wo das Cheatsheet es verortet.

Der Zwischenspeicher (28 MiB über 30 Repos) wird am Ende des Laufs wieder
freigegeben, nicht für den Rest der Session gehalten.

### Zwei Nebenbefunde, nicht mitgefixt

1. **`records.lua`s `split_cells` zerlegt escapte Pipes.** Eine Tabellenzelle
   mit `` `]\|` `` wird an dem escapten `|` getrennt; als „lhs" kommt `` `]\ ``
   heraus. Vorbestehender Scraper-Defekt, betrifft auch `browse`, hier nur
   erstmals sichtbar geworden (markdown.nvim, Zeile 39).
2. **`lua/plugins/personal/init.lua` fehlt im Working Tree** (in HEAD
   vorhanden, unstaged gelöscht). Damit schlägt `require("plugins.personal")`
   fehl — die Default-Auflösung der neuen Achse meldet das korrekt als Grund,
   aber die Config lädt in diesem Zustand überhaupt keine Personal-Plugins.
   Nicht angefasst, weil parallele Sessions in diesem Repo arbeiten.

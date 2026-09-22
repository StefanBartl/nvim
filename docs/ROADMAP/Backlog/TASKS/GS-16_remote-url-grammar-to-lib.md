# GS-16 — Remote-URL-Grammatik nach `lib.nvim` heben

**Repos:** lib.nvim (`git/remote.lua` neu), gitsuite.nvim, github_stats.nvim,
documentation.nvim · **Nutzen** 4 · **Risiko** mittel · **Welle** 3
(Duplikate) · erledigt 2026-09-22.

## Ausgangslage

`gitsuite.features.browse.url` war laut eigenem Kopfkommentar rein (kein
`vim.api`, kein Prozess), wurde aber von mehr als gitsuite gebraucht:
`github_stats/statusline.lua`s `resolve_slug` parste Remotes mit einer
eigenen, nur GitHub-tauglichen Regex direkt über `vim.fn.systemlist`;
`documentation.nvim`s Docmap-Pipeline verlangte `--repo-url=`/`--branch=`
von Hand, obwohl die Antwort im `.git`-Verzeichnis bereits steht — `branch`
fiel dabei sogar still auf das wörtliche `"main"` zurück, unabhängig vom
tatsächlichen Standardbranch des Repos.

## Umsetzung, je Repo

- **lib.nvim** (`1db2bf6`): `lib.nvim.git.remote` (`parse_remote`,
  `host_kind`, `build`) — wortgleich aus gitsuites `url.lua` übernommen, rein,
  kein Prozess. Alle 15 Fälle aus `browse_url_spec.lua` wanderten nach
  `TESTS/git_remote_spec.lua` mit.
- **gitsuite.nvim** (`ad09a26`): `features/browse/init.lua` requiret jetzt
  `lib.nvim.git.remote` unter demselben lokalen Namen (`url`) — der Rest der
  Datei blieb unverändert. `features/browse/url.lua` und dessen Test
  komplett gelöscht, nichts blieb dort zu testen übrig.
- **github_stats.nvim** (`c9d2de0`): `statusline.lua`s `resolve_slug` nutzt
  jetzt `lib.nvim.git.remote_url` + `lib.nvim.git.remote.parse_remote` statt
  eigenem `vim.fn.systemlist` + Regex. Das Modul verfolgt weiterhin nur
  github.com — die anderen von `parse_remote` erkannten Host-Arten fallen
  einfach auf `slug = false` zurück, wie jedes Nicht-Repo auch.
- **documentation.nvim** (`369cd77`): `config.build()` leitet `repo_url`/
  `branch` jetzt automatisch aus dem echten Git-Remote/-Branch ab (via
  `lib.nvim.git.remote_url` + `lib.nvim.git.remote`), wenn weder Host, Repo-
  eigene `.docmap.json` noch CLI-Flag sie setzen. **`pcall`-abgesichert, nicht
  nur eine Capability-Prüfung:** `standalone/vim_shim.lua` (der Neovim-freie
  Parser-less-MVP-Build, reines PUC Lua) stellt weder `vim.system` noch
  `vim.fn.system` bereit — ein direkter Aufruf hätte den Standalone-Build
  beim ersten echten Lauf zum Absturz gebracht. Ein fehlendes Remote, ein
  fehlendes `git`-Binary und ein fehlendes `vim.system` degradieren jetzt
  alle gleich: `repo_url`/`branch` bleiben unverändert, wie vor dieser
  Änderung. `DEFAULTS.lua`s statisches `branch = "main"` entfernt — es
  gewann in `build()`s Merge-Reihenfolge immer gegen die Ableitung, hätte den
  neuen Code also tot gemacht; `core/scan.lua`s eigenes `opts.branch or
  "main"` ist jetzt die einzige Stelle, an der dieses Literal noch lebt.

## Nicht angefasst — dokumentierte Entscheidung

Die von `html.lua`s generiertem JS gebaute Blob-URL
(`repo + "/blob/" + branch + "/" + path`) ist weiterhin GitHub-only-Format
(keine GitLab-`/-/blob/`- oder Codeberg-`/src/branch/`-Grammatik) — das war
schon vor dieser Karte so und ist ein separater, nicht angefasster Bug: der
Plan-Umfang nannte nur "docmap leitet die Blob-URL aus dem echten Remote ab"
(Herkunft der URL, nicht ihr Format für andere Hosts).

## Tests

`TESTS/git_remote_spec.lua` (lib.nvim, 15 Fälle, wortgleich aus gitsuite
übernommen). `documentation.nvim`s `TESTS/config_file_spec.lua`: die zwei
Assertions, die `branch == "main"` direkt aus `build()` erwarteten, liefen
gegen einen anderen, weiterhin statischen `DEFAULTS`-Schlüssel um (sie
prüften eigentlich nie `branch` selbst, nur "Defaults überleben"); ein neues
echtes Git-Fixture belegt, dass `repo_url`/`branch` tatsächlich abgeleitet
werden und ein expliziter Override weiterhin gewinnt. Der Standalone-Build
selbst wurde nicht end-to-end nachgestellt (die Rocks `lfs`/`dkjson` sind in
dieser Umgebung nicht installiert) — stattdessen belegt, dass
`lib.nvim.git`s Legacy-Fallback (`vim.fn.system`) einen gewöhnlichen,
`pcall`-fangbaren Lua-Fehler wirft, wenn sowohl er als auch `vim.system`
fehlen — genau das, worauf dieser Code im Shim trifft.

## Ergebnis

Alle vier Commits einzeln CI-grün auf allen Systemen (lib.nvim zuerst,
`ci-verified` abgewartet, dann die drei Konsumenten, K-6). Lokale Suiten
grün: `LIB_TESTS_OK`, gitsuites volle `TESTS/gitsuite/`-Suite,
`github_stats.nvim`s volle Suite (inkl. Integration), `documentation.nvim`s
volle Suite (`DOCUMENTATION_TESTS_OK`). `stylua`/`luacheck` sauber in allen
vier Repos.

## Dokumentation mitgezogen

`lib.nvim/lua/lib/nvim/git/README.md` (verlinkt aus `remote.lua`s
Modul-Docstring); `documentation.nvim/docs/docmap.schema.json` (`repo_url`/
`branch`-Beschreibungen), `lua/documentation/@types/init.lua`,
`lua/documentation/config/DEFAULTS.lua` (Kopfkommentar: vier statt drei
bewusst fehlende Felder), `standalone/docmap.lua` (Asymmetrie
Standalone/Neovim-Host erklärt).

## Nachwirkung

`lib.nvim.git.remote` ist jetzt öffentliche API — jeder weitere Konsument,
der einen Git-Remote in einen Host/Owner/Repo zerlegen oder eine
Blob-/Repo-Web-URL bauen will, braucht keine eigene Regex mehr. `hover.nvim`
und `buffer-ctx.nvim` (Permalinks) sind laut Plan als Welle-5-Konsumenten
vorgemerkt, nicht Teil dieser Karte.

## Nachtrag 2026-09-22: zwei Funde aus der Session-Selbstprüfung

Auf Nutzeranfrage alle Commits dieser Session gegen Bugs/Security/
Performance geprüft — zwei echte Funde, beide sofort gefixt und CI-grün
nachgezogen:

1. **Bug, `lib.nvim.git.remote.build()`** — Branch/Pfad wurden roh in die
   URL interpoliert. Ein getrackter Datei- oder Branch-Name mit Leerzeichen,
   `#` oder `?` (alle auf POSIX-Dateisystemen gültig) hätte den Link
   stillschweigend abgeschnitten (`#` = Fragment-Trenner) oder umgeleitet
   (`?` = Query-Trenner). Fix (`7a10289`): jedes Pfadsegment einzeln über
   `lib.lua.strings.encoding.url_encode` kodiert, `/` bleibt als Trenner
   erhalten (sonst hätte ein Unterordner oder ein Branch mit `/` einen
   literalen `%2F` bekommen). Zwei neue Testfälle in
   `TESTS/git_remote_spec.lua`.
2. **Performance-Regression, `documentation.nvim`** — die
   Git-Ableitung landete ursprünglich in `config.build()`. Laut dessen
   eigenem (vorbestehendem) Kommentar in `bindings/usrcmds/init.lua` läuft
   genau diese Funktion bei **jedem Tastendruck** während
   `:DocMap <Tab>`-Completion, weil sie als "cheap" (Table-Merge + ein
   `vim.fs.dir`-Probe) dokumentiert und darauf verlassen ist. Die neuen
   zwei Git-Prozessaufrufe hätten jeden Tastendruck blockiert. Fix
   (`ddb0335`, dokumentation.nvim): Ableitung nach `core/scan.lua`
   verschoben — läuft nur noch einmal pro echtem Scan, nicht pro
   Tastendruck. `config/DEFAULTS.lua`s Kommentar entsprechend korrigiert,
   der GS-16-Testfall von `config_file_spec.lua` nach der neuen
   `TESTS/scan_repo_url_derive_spec.lua` verschoben (prüft jetzt
   `scan()`s IR-Ausgabe statt `config.build()`s Opts-Tabelle).

Beide Fixes CI-grün auf allen Systemen; `gitsuite.nvim`/`github_stats.nvim`
gegen das aktualisierte `lib.nvim` erneut lokal getestet, unverändert grün
(ihr eigener Code war von keinem der beiden Funde betroffen).

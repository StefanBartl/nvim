# `lsp.nvim-envlinks` — ein eigener In-Process-LSP-Client für `$VAR`-Links in Markdown

Stand: 2026-09-29 · Repos: `lsp.nvim` (`d951163`), `gopath.nvim` (`d971b09`)

## Kurzfassung

marksman kann Markdown-Links wie `[x]($REPOS_DIR/a/b.md)` nicht auflösen. Ein
kleiner, selbst geschriebener LSP-Client (`lsp.nvim-envlinks`, läuft im
Neovim-Prozess, ohne externen Prozess) liefert Definition und Hover für solche
Links. Zusätzlich werden die Fehlalarme von marksman gegen die Festplatte
geprüft, statt pauschal ausgeblendet zu werden. Das Ganze ist als Feature von
`lsp.nvim` gebaut (`languages.env_links`) und hängt nur weich an gopath.nvim.

## 1. Das Problem (gemessen, nicht vermutet)

Gegen echtes marksman mit einem Fixture-Ordner:

| Link | Definition | Hover | Diagnostic |
|---|---|---|---|
| `[r](./b.md)` | ja | ja | – |
| `[e]($REPOS_DIR/…/Links.md)` | **nichts** | **nichts** | „Link to non-existent document“ (falsch, Datei existiert) |
| `[e]($REPOS_DIR/…/nope.md)` | nichts | nichts | dieselbe Meldung (hier zu Recht) |

Ursache: marksman löst Linkziele relativ zum Dokument auf. `$REPOS_DIR` ist für
den Server ein Ordnername. Er kennt keine Umgebungsvariablen, und er sollte sie
auch nicht kennen: `$NVIM_CONFIG_DIR` existiert nicht einmal als echte
OS-Variable, das ist eine Konvention von gopath.nvim.

Verschärfend: `lsp.servers.marksman.config` setzte `suppress_missing_doc_links =
true`. Das versteckte die Fehlalarme, aber jeden echten kaputten Link in jedem
Repo gleich mit.

## 2. Die Lösung in zwei Hälften

### 2.1 Diagnostics: prüfen statt verstecken

In `servers/marksman/diagnostics_handler.lua` fragt der Filter vor den alten
Regeln `env_links.verdict(message)`:

- Ziel ist ein Env-Link und die aufgelöste Datei **existiert** → Meldung
  verwerfen (Fehlalarm).
- Ziel ist ein Env-Link und die Datei **fehlt** → Meldung **behalten**, auch
  wenn die Pauschalregel sie verstecken würde, und um den Suchpfad ergänzen:
  `… (resolved to C:/Users/bartl/nope.md)`.
- Alles andere (normaler Link, undefinierte Variable) → alte Regeln, unverändert.
  „Nicht entscheidbar“ ist nicht „kaputt“.

### 2.2 Definition und Hover: ein eigener Client

`lua/lsp/core/env_links_server.lua`. Ein LSP-Server, dessen `cmd` eine
Lua-Funktion ist. Kein Prozess, keine Installation, dasselbe Muster wie
`lsp.nvim-gitsigns` (`core/gitsigns_actions.lua`).

- **Fähigkeiten:** nur `definitionProvider` und `hoverProvider`.
- **Attach:** per `FileType`-Autocmd an Markdown-Buffer (`markdown`,
  `markdown.mdx`, `mdx`) mit `buftype == ""`. Ein einziger Client für alle
  Buffer (`root_dir = nil`, `vim.lsp.start` findet ihn über Name und gleiche
  Root wieder).
- **Definition:** `Location` der aufgelösten Datei. Bei `#anker` steht sie auf
  der Überschrift (GitHub-Slug, inklusive Umlauten, Überschriften in
  Codeblöcken zählen nicht). Für nicht existierende Dateien gibt es **keine**
  Location.
- **Hover:** Markdown mit Linkziel, aufgelöstem Pfad und den ersten 12 Zeilen
  der Datei. Bei fehlender Datei steht dort `-> (missing) <Pfad>`. Genau das
  will man beim Hovern über einen kaputten Link wissen.
- **Zurückhaltung:** Außerhalb eines Env-Links antwortet der Client mit `nil`.
  Bei normalen Links bleibt marksmans Antwort die einzige.

### Warum ein Client und kein Keymap-Fallback

`gd`, Peek, Hover und alles, was eine Config später ergänzt, fragen die
Language Server über `vim.lsp.buf_request_all` ab und führen **die Antworten
aller Clients zusammen**. Ein zusätzlicher Client wirkt dadurch überall ohne
Einzelverdrahtung. Ein Fallback im `gd`-Keymap würde nur `gd` reparieren.

Ebenfalls geprüft und verworfen: ein Handler in der marksman-Config. Handler aus
`config.handlers` greifen nur bei Requests, die Client-Handler benutzen.
`vim.lsp.buf.definition` benutzt sie nicht, es übergibt einen eigenen Callback.

## 3. Auflösung der Pfade (`lua/lsp/core/env_links.lua`)

Reihenfolge:

1. **`~`** immer selbst (gopaths Text-API ist für Env-Referenzen gedacht).
2. **gopath.nvim**, wenn installiert und `require("gopath").resolve_text`
   existiert. gopath besitzt die Variablen-Regeln (`$VAR`, `${VAR}`, beide
   Trenner, „well-known“-Verzeichnisse wie `$NVIM_CONFIG_DIR` ohne echte
   Variable, Nutzer-Config). Dadurch löst sich ein Link im Editor exakt wie mit
   `gP`.
3. **Eingebauter Fallback:** echte Umgebung, `$NVIM_CONFIG_DIR` →
   `stdpath("config")`, sonst nichts. Bewusst klein: sobald der Fallback eigene
   Regeln bekäme, würde er von gopath abweichen.

Zusätzlich in `gopath.nvim`: `require("gopath").resolve_text(text)` als
stabiler öffentlicher Einstieg (delegiert an `gopath.resolve_selection`, das
das schon konnte). Ohne ihn hätte man in interne Resolver greifen müssen. Ein
gopath ohne diese Funktion, ein Fehler in gopath oder ein unbekannter Name
führen automatisch zum Fallback.

Weitere Details: Prozent-Kodierung (`%20`) wird vor dem Auflösen decodiert,
`<…>`-Ziele mit Leerzeichen funktionieren, UTF-16-Spalten des LSP werden in
Byte-Offsets umgerechnet (sonst wird ein Link nach einem Umlaut verfehlt).

## 4. Bedienung und Konfiguration

```lua
require("lsp").setup({
  languages = { env_links = true },  -- Default; false schaltet Client und
})                                    -- Diagnostics-Filter gemeinsam ab
```

`languages` darf auch in einer projektlokalen `.nvim-lsp.json` gesetzt werden.
Sichtbar ist der Client in `:Lsp servers` als `lsp.nvim-envlinks`. Er wird von
`lsp.core.util.server_clients` wie der Gitsigns-Client übergangen (Präfix
`lsp.nvim-`), damit Winbar-Guard, `:Lsp stop` und `:Lsp restart` ihn
ignorieren.

## 5. Verifikation

- 79 neue Specs (`TESTS/lsp/env_links_spec.lua`): Auflösung mit und ohne
  gopath-Stub (inklusive Fehler und alter gopath), Link-Parser (Umlaute,
  Bilder, Referenz-Definitionen, Titel, `<…>`), Verdict, Heading-Suche,
  Diagnostics-Filter (bestehendes Verhalten bleibt), Server-Handler direkt
  und als echter Client per `buf_request_sync`. Gesamtsuite: 1191 bestanden,
  0 Fehler. stylua und luacheck sauber.
- Ende-zu-Ende mit echtem marksman und der echten Config: existierende
  Env-Links (`$REPOS_DIR`, `${REPOS_DIR}`, `$NVIM_CONFIG_DIR`, mit Anker)
  ohne Meldung, zwei kaputte (`…/nope.md`, `~/nope.md`) mit Suchpfad gemeldet,
  Definition und Hover kommen von `lsp.nvim-envlinks`, normale Links weiter
  von marksman.

## 6. Grenzen

- **Kein Completion:** marksmans Datei-Completion in Links liefert weiter
  relative Pfade. Env-Pfade werden nicht vorgeschlagen.
- **Nur einzeilige Links:** kein Markdown-Parser, über Zeilen umbrochene Links
  löst auch marksman nicht auf.
- **Anker:** Die Existenz der Datei wird geprüft, ob die Überschrift vorhanden
  ist, dagegen nicht (nur bei Definition: Sprung dorthin, sonst Dateianfang).
- **Undefinierte Variable:** Der Link bleibt unangetastet (keine Aussage
  möglich), die alte Pauschalregel gilt weiter. Dasselbe gilt für `${VAR}text`
  ohne Trenner: In der Shell ist das der Wert mit angehängtem Text, kein
  Unterordner, also wird nicht geraten.
- **Längenlimits (Review-Nachtrag):** Zeilen über 20000 Byte werden nicht nach
  Links durchsucht, Linkziele über 4096 Byte werden abgelehnt (nicht
  abgeschnitten), Überschriften-Zeilen über 2000 Byte zählen nicht als
  Überschrift. Das begrenzt die Arbeit bei pathologischem Inhalt: Der erste
  Entwurf brauchte für eine Zeile aus 20000 `[` 1,2 s, und das
  Überschriften-Pattern war kubisch (2000 Zeichen mit Leerzeichen: 4,3 s).
  Beides ist jetzt linear (ca. 1 ms) und per Spec abgesichert.
- **Ein Client mehr:** sichtbar in `vim.lsp.get_clients()`; jedes Feature, das
  nur fragt „hängt irgendein Client dran“, sieht ihn.
- **Verwandtes, nicht Teil davon:** marksman meldet in Repos mit doppelten
  Dateinamen (z. B. `.claude/worktrees/*`-Kopien im Repo) „Ambiguous link to
  document“ als Fehlalarm. Das ist ein anderes Thema. Der Schalter
  `:Lsp workspace off <projekt>` dämpft es für nicht geöffnete Dateien.

## 7. Als Plugin für andere veröffentlichen?

Was dafür spricht: Das Problem betrifft jeden, der Env-Variablen oder `~` in
Markdown-Links nutzt (Notiz-Vaults, Doku-Repos). Die Lösung ist klein
(~500 Zeilen inklusive Kommentaren), abhängigkeitsarm (lib.nvim für
autocmd/fs.read, gopath optional) und gut getestet. Das Muster „kleiner
In-Process-Client ergänzt, was der echte Server nicht kann“ ist ein
wiederverwendbarer Baustein.

Was zu klären wäre:

1. **Zuschnitt.** Aktuell drei Teile in `lsp.nvim`: Auflösung
   (`core/env_links.lua`, ohne LSP-Bezug, gut extrahierbar), Client
   (`core/env_links_server.lua`), marksman-Diagnostics-Filter (eng an marksmans
   Meldungstext gekoppelt, `^Link to non%-existent document '(.*)'`). Eigenes
   Repo (`envlinks.nvim`) müsste alle drei mitnehmen. Der Filter braucht dann
   einen Hook statt des direkten `require` aus dem marksman-Modul.
2. **Abhängigkeiten.** Aus `lsp.nvim` herausgelöst braucht er `lib.nvim`
   (autocmd, fs.read) und `lsp.core.util` (nur für den Präfix
   `lsp.nvim-`, ersetzbar durch eine Konstante).
3. **Andere Server.** Der Client ist serverunabhängig. Der Diagnostics-Filter
   ist marksman-spezifisch. `markdown-oxide` (bei dir in Mason installiert)
   hätte eigene Meldungstexte.
4. **gopath.** `resolve_text` ist jetzt öffentliche API in gopath; ein
   veröffentlichter Client sollte gopath als weiche Abhängigkeit dokumentieren.
5. **Marksman-Meldungstext** ist keine stabile API. Änderungen dort brechen den
   Filter, dann fällt das Verhalten auf die alten Regeln zurück (kein Absturz).

Empfehlung: erst in `lsp.nvim` mitlaufen lassen (steckt schon drin und ist
per Config abschaltbar) und, wenn es sich im Alltag bewährt, Auflösung und
Client als eigenes kleines Plugin herauslösen. Der Diagnostics-Filter bleibt
dann in `lsp.nvim` als Konsument.

## 8. Dateien

| Repo | Datei | Rolle |
|---|---|---|
| lsp.nvim | `lua/lsp/core/env_links.lua` | Auflösung, Link-Parser, Verdict, Heading-Suche |
| lsp.nvim | `lua/lsp/core/env_links_server.lua` | In-Process-Client (Definition, Hover) |
| lsp.nvim | `lua/lsp/servers/marksman/diagnostics_handler.lua` | Filter: prüfen statt verstecken |
| lsp.nvim | `lua/lsp/init.lua` | Setup-Schritt `markdown env links` |
| lsp.nvim | `lua/lsp/config/DEFAULTS.lua`, `config/init.lua`, `@types/init.lua` | Option `languages.env_links` |
| lsp.nvim | `TESTS/lsp/env_links_spec.lua` | 79 Specs |
| lsp.nvim | `docs/configuration.md` (`languages.env_links`), `docs/FEATURES/SERVERS.md`, `doc/lsp.nvim.txt`, `servers/marksman/README.md` | Doku |
| gopath.nvim | `lua/gopath/init.lua` (`resolve_text`), `scripts/ci/specs/resolve_selection_spec.lua`, `docs/resolution.md` | öffentliche Text-API |

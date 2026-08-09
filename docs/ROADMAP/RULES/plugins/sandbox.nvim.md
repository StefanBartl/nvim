# sandbox.nvim

## Zweck
`sandbox.nvim` ist eine Neovim-native Fernbedienung für Container-Engines
(Docker, Podman, nerdctl/containerd) und WSL-Distros: Container-/Image-/
Volume-/Network-/Compose-Lifecycle, Registry-Login, Devcontainer-Support,
alles über `:Sandbox`/`:Sbx` mit Tab-Completion, buffer-lokale List-Views und
eine optionale Telescope-Extension. Architektur ist explizit hexagonal
(Ports & Adapters): `lua/sandbox/core/usecases/` + `core/ports/` sind
engine-agnostisch, `lua/sandbox/adapters/<engine>/` implementiert dieselbe
Portschnittstelle dreifach (docker/podman/nerdctl) plus separat `adapters/wsl/`.
Der Name "sandbox" bezieht sich auf den Anwendungsfall (Container als
Sandbox), nicht auf eine vom Plugin selbst bereitgestellte Isolation.

## Nicht-standard Patterns / Algorithmen

**Sicherheitsrelevanter Befund zuerst, wie angefordert:** Das Plugin führt
selbst **keine** Isolation/Sandboxing aus (kein `unshare`, kein `chroot`,
keine Namespaces/cgroups/seccomp im eigenen Code — die grep dazu über
`lua/sandbox` ergab ausschließlich Treffer, weil "sandbox" der Modulname
ist, nicht weil irgendwo Isolationslogik steht). Die eigentliche Isolation
liefert immer der externe Daemon (Docker/Podman/nerdctl). Das Plugin selbst
ist reine CLI-Fernsteuerung. Was tatsächlich als bewusste
Security-Entscheidung im Code sichtbar ist:

1. **Durchgängig argv-Arrays statt Shell-Strings** — `lua/sandbox/util/run_argv.lua:17-21`
   (`vim.fn.system(cmd, ...)` mit `cmd` als Tabelle) und
   `run_argv.lua:91` (`vim.system(cmd, ...)`). Über den gesamten Adapter-Baum
   (docker/podman/nerdctl × containers/images/volumes/networks/registry/wsl,
   >150 Dateien) wird kein einziger Befehl per String-Konkatenation gebaut
   und an eine Shell übergeben (`os.execute`/`io.popen`/`shell=true` kommen
   im ganzen `lua/`-Baum nicht vor). Warum abweichend vom naiven Ansatz:
   String-Konkatenation von IDs/Namen/Pfaden in einen Shell-Befehl wäre eine
   klassische Command-Injection-Lücke, sobald ein Container-Name oder
   Dateiname aus einer Docker-Ausgabe zurück in einen Befehl eingesetzt wird.
2. **Passwort nie als argv-Element** —
   `lua/sandbox/adapters/docker/registry/login.lua:16-22`: `docker login
   --password-stdin`, Passwort wird über `run_argv.run_blocking_captured(args,
   password)` per stdin gepiped. Warum: argv-Elemente sind über `ps`/Shell-
   Historie/Prozessliste für andere lokale Prozesse sichtbar, stdin nicht.
3. **`friendly_error.lua`** (`lua/sandbox/util/friendly_error.lua:1-59`) —
   mappt bekannte Daemon-unreachable-Fehlermuster (Substring-Suche, keine
   Regex) auf eine feste, kurze Nutzermeldung, sonst wird nur die erste Zeile
   des Rohfehlers (auf 200 Zeichen gekappt) gezeigt. Warum: mehrzeiliger CLI-
   Stderr in einem `vim.notify`-Popup ist unlesbar; die Rohausgabe geht
   trotzdem separat an `sandbox.logger` für Postmortem-Debugging statt verloren
   zu gehen.
4. **`statusline.lua`** cached die Engine-Statuszusammenfassung für 3s
   (laut README), um nicht bei jedem Redraw zu shellen — typisches
   Debounce/Cache-Pattern gegen eine Statusline, die mehrfach pro Sekunde neu
   zeichnet.
5. **`progress_label()`** (`run_argv.lua:32-42`) kürzt lange Image-
   Referenzen/Digests auf 40 Zeichen, damit der Statusline-Fortschrittsindikator
   nicht durch eine 200-Zeichen-Registry-URL gesprengt wird — kleine, aber
   bewusste UX-Absicherung gegen unbegrenzte externe Eingabelänge.
6. **`.sandboxrc`-Parser** (`lua/sandbox/util/project_config.lua:17`) nutzt ein
   restriktives Lua-Pattern (`^%s*([%w_]+)%s*=%s*(%S+)%s*$`) und validiert den
   Wert zusätzlich gegen eine feste Enum (`docker`/`podman`/`nerdctl`) statt
   die Zeile roh zu übernehmen — verhindert, dass eine manipulierte
   `.sandboxrc` im Projektverzeichnis beliebige Strings in `config.options.engine`
   einschleust.
7. **`confirm.destructive` + `bulk_confirm_then`** (`util/confirm.lua`,
   `ui/list_actions.lua:107-131`): destruktive Aktionen (remove/prune/kill)
   fragen einmal nach, bei Multi-Select-Bulk-Aktionen wird `confirm_destructive`
   temporär auf `false` gesetzt und pro Item durchgereicht, um nicht N-mal
   nachzufragen — bewusste Abweichung vom naiven "jede destruktive Funktion
   fragt für sich selbst nach", weil das bei Bulk-Operationen die UX zerstören
   würde.
8. **`Visual-Mode Multi-Select liest `getpos("v")`/`getpos(".")`** statt
   `mode()`/Marks (`ui/list_actions.lua:56-65`), weil `'<`/`'>` erst nach
   Verlassen des Visual-Mode aktualisiert werden, eine Lua-Function-Mapping in
   Mode `"x"` aber läuft, bevor das passiert — ein bekanntes Neovim-API-Detail,
   das hier explizit dokumentiert und umgangen wird.

Insgesamt: keine besonderen Performance-Algorithmen (keine Caching-Strategie
außer der Statusline, keine Diffing-Logik) — der Schwerpunkt des "besonderen"
Codes liegt komplett auf Command-Injection-Vermeidung und CLI-Fehler-UX.

## Abgeleitete Guidelines

1. Befehle an externe Prozesse **immer** als argv-Tabelle bauen (`{"cmd",
   "sub", arg1, arg2}`), nie als konkatenierter String — auch nicht für
   "harmlose" interne IDs, da diese oft aus vorheriger CLI-Ausgabe stammen.
2. Geheimnisse (Passwörter, Tokens) nie als Prozessargument übergeben, wenn
   die Ziel-CLI eine `--xxx-stdin`-Variante anbietet; sonst zumindest
   dokumentieren, dass sie sichtbar sind.
3. Externe Fehlerausgaben (CLI stderr) nie direkt in einem einzeiligen Popup
   zeigen — auf bekannte Muster mappen + erste Zeile kappen, vollen Text
   separat loggen.
4. Hexagonale Struktur (`core/ports` + `core/usecases` + `adapters/<impl>`)
   lohnt sich, sobald ein Plugin mehr als eine austauschbare Backend-
   Implementierung hat (hier: 3 Engines + WSL) — Test-Suite testet dann gegen
   einen gefakten `run_argv` statt gegen echte Binaries.
5. Destruktive Aktionen zentral über ein einziges `confirm.destructive()`-Gate
   routen, das per Config global abschaltbar ist, statt in jeder Funktion
   eigene `vim.fn.confirm`-Aufrufe zu duplizieren; bei Bulk-Aktionen einmal
   statt N-mal fragen.
6. Konfigurationswerte aus Dateien, die außerhalb der eigenen Config-API
   gesetzt werden können (`.sandboxrc`, Projekt-Overrides), immer gegen eine
   feste Enum/Whitelist validieren, nie roh übernehmen.
7. Lange, potenziell unbegrenzte externe Strings (Image-Digests, Registry-URLs)
   vor der Anzeige in begrenzten UI-Flächen (Statusline) aktiv kappen.
8. Optionale Abhängigkeiten (`lib.nvim`-Submodule wie `progress`, `notify`)
   konsequent per `pcall(require, ...)` weich einbinden und mit einem
   Fallback auf Bordmittel (`vim.notify`, `vim.fn.system`) versehen — Muster
   zieht sich durch `run_argv.lua`, `notify.lua`, `confirm.lua`.
9. Mehrstufige User-Commands (`:Sandbox <namespace> <subcommand> <args>`)
   über einen einzigen Composer/Route-Table registrieren statt viele
   Einzelbefehle — ermöglicht generierte Doku (`:Sandbox docs generate`) und
   verhindert Drift zwischen Code und Doku.
10. Bei Visual-Mode-Keymaps, die mit `'<`/`'>`-Marks arbeiten wollen: auf das
    Timing-Problem achten (Marks erst nach Mode-Exit gültig) und stattdessen
    `getpos("v")`/`getpos(".")` innerhalb der laufenden Selektion lesen.

## Keybindings-Audit

Sandbox.nvim setzt **keine globalen Keymaps** (siehe `docs/BINDINGS.md`:
"No global keymaps or autocmds"). Alle Interaktion läuft über `:Sandbox`/`:Sbx`
Subcommands plus **buffer-lokale** Keymaps in den read-only List-View-Scratch-
Buffern (`lua/sandbox/ui/list_actions.lua`).

Buffer-lokale Keymaps im Container-List-View (`?`-Cheatsheet, `q` schließt):
`<CR>`/`i` inspect, `s` start, `x` stop, `X` kill, `r` restart, `p`/`P`
pause/unpause, `n` rename, `D` remove, `l`/`L` logs/logs-follow, `e` exec,
`t`/`T` top/stats, `R` refresh. Analog für Image-/Volume-/Network-Lists.

- **Count-Unterstützung (`2<key>`, `3<key>` etc.):** Nicht unterstützt und für
  diese Aktionen auch kaum sinnvoll — jede Aktion bezieht sich auf genau ein
  Item unter dem Cursor (`item_under_cursor`, `list_actions.lua:10-14`); ein
  Count hätte hier keine natürliche Bedeutung (anders als z.B. bei `dd`).
  Für "N Items betreffen" existiert bereits ein besseres Mittel: Visual-Mode
  Multi-Select (`V`/`j`/`j`/... + Taste), was in der Doku explizit als
  Alternative zu Count beworben wird.
- **Autocompletion:** Ja, durchgängig vorhanden — `:Sandbox` ist komplett auf
  `lib.nvim.usercmd.composer` mit `<Tab>`-Completion auf jeder Ebene gebaut
  (Sub-Namespace → Subcommand → Container-/Image-/Volume-/Network-/Distro-
  Namen, live aus der aktiven Engine aufgelöst, kurz gecacht). Vorbildlich
  umgesetzt.
- **Fehlende Flags/Optionen (Ideen beim Lesen):**
  - Kein Keymap/Command, um zwischen den drei Engines direkt aus dem List-View
    zu wechseln (nur `:Sandbox engine set`).
  - `container exec`/`exec-once` haben kein Flag, um ein Arbeitsverzeichnis im
    Container zu setzen (`docker exec -w`).
  - Kein `--dry-run`/Preview für destruktive Bulk-Aktionen vor dem Bestätigen
    (man sieht nur "Remove 5 containers?", nicht welche).
  - List-Views haben kein Such-/Filter-Keymap (`/` filtert nur im Buffer via
    Neovim-Suche, kein strukturiertes Filtern nach Status/Name).

## Ideen für andere Plugins

- **Ein generisches "CLI-Remote"-Gerüst** aus `run_argv.lua` +
  `friendly_error.lua` + `confirm.lua` + `list_actions.lua` extrahieren (evtl.
  Kandidat für `lib.nvim`): argv-Runner mit Progress-Integration, destruktive
  Bestätigungs-Gate, buffer-lokale List-View-Keymap-Wiring inkl. Visual-Multi-
  Select — dieses Quartett taucht 1:1 wiederverwendbar auf, sobald ein
  zukünftiges Plugin eine weitere CLI fernsteuert (z.B. `kubectl`, `gh`,
  systemd via `systemctl`).
- **systemctl.nvim** / **k8s.nvim**: gleiches Ports-&-Adapters-Muster wie
  sandbox.nvim, nur für systemd-Units oder Kubernetes-Ressourcen — die
  komplette UI-Schicht (List-View, Inspect-View, Log-View, Confirm-Gate)
  ließe sich fast unverändert wiederverwenden.
- **`.projectrc`-Familie**: das `.sandboxrc`-Muster (Key=Value-Datei im
  Projektroot, whitelisted Werte, Session-Override > Projekt-Override >
  Default) ist generisch genug für andere Plugins, die pro-Projekt-Overrides
  brauchen (z.B. welcher Formatter/Linter/Python-Interpreter aktiv ist).

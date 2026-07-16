Gefunden — sehr wahrscheinlich ist es `github_stats.nvim`. Die beiden Logs zeigen, dass reines Plugin-Loading auf der Workstation genauso schnell ist wie bei dir (599ms bis `NVIM STARTED`, VeryLazy-Events lösen sich in ca. 1.4s auf) — der Freeze passiert also **nach** dem Zeitfenster, das `--startuptime` und `:Lazy profile` überhaupt erfassen. Das schließt reines Plugin-Laden als Ursache aus und zeigt auf etwas, das erst 1s nach dem Start per `vim.defer_fn` losläuft.

## Der Mechanismus

[lua/plugins/personal/init.lua:445-459](lua/plugins/personal/init.lua:445) konfiguriert `github_stats.nvim` mit `watch_users = { "StefanBartl" }`. Das löst bei jedem `VimEnter` (via [background.lua:63-82](../../E:/repos/github_stats.nvim/lua/github_stats/background.lua:63)) automatisch aus:

1. **Repo-Discovery**: alle öffentlichen Repos von `StefanBartl` auflisten (paginierter curl-Call)
2. **Für jedes gefundene Repo × 4 Metriken (clones/views/referrers/paths) je ein eigener `curl`-Subprozess** via `vim.system` ([api.lua:117](../../E:/repos/github_stats.nvim/lua/github_stats/api.lua:117))

In `github-stats/data/` liegen bei dir aktuell **41 Repo-Ordner** → das sind **41 × 4 = 164 curl.exe-Spawns**, alle in einer engen Schleife ohne Pause abgefeuert ([fetcher.lua:190-197](../../E:/repos/github_stats.nvim/lua/github_stats/fetcher.lua:190)).

Das ist zwar als "async" gebaut (`vim.system`), aber der eigentliche `CreateProcess`-Syscall läuft in libuv **synchron auf dem Event-Loop-Thread** — jeder einzelne Spawn blockiert kurz, bevor der nächste startet. Auf deinem PC dauert das pro Prozess ein paar Millisekunden (unmerklich). Auf einer Dell-Business-Workstation hängt üblicherweise ein Corporate-EDR/AV (Defender ATP, CrowdStrike o.ä.), das **jeden neuen Prozessstart synchron abfängt und scannt** — wenn das nur 300–500ms pro curl.exe-Spawn kostet, sind 164 Spawns genau in deiner beobachteten 45-90s-Range.

## Warum "freezed nach ein paar Sekunden"

Passt exakt: der Fetch-Zyklus startet 1000ms nach `VimEnter` (`vim.defer_fn(run_cycle, 1000)`), also kurz nachdem die UI schon nutzbar aussah — dann kommt die Prozess-Lawine.

## Warum evtl. bei jedem Start (nicht nur alle 24h)

Der Fetch ist eigentlich auf `fetch_interval_hours = 24` gedrosselt, aber der Zeitstempel liegt in `github-stats/last_fetch.json` **lokal pro Maschine** (nicht Teil des Git-Trackings, siehe `git status` — die Datei taucht dort gar nicht auf). Wenn das Schreiben dieser Datei auf der Workstation aus irgendeinem Grund fehlschlägt (Rechte, Pfad, AV blockiert Datei-Write), denkt das Plugin bei **jedem** Start "nie gefetcht" → volle Lawine bei jedem `nvim`-Start.

## Was du testen/liefern kannst

1. **Sofort-Test auf der Workstation**: `lua/plugins/personal/init.lua` Zeile 449 temporär auf `background = { enabled = false }` setzen (oder `watch_users` rausnehmen) und neu starten. Wenn der Freeze weg ist → bestätigt.
2. **Log**: `Get-Content "$env:LOCALAPPDATA\nvim\github-stats\last_fetch.json"` auf der Workstation direkt nach einem Freeze — steht da ein aktueller Timestamp oder ist die Datei alt/fehlt sie?
3. **Prozessmonitor** (optional, aber beweiskräftig): Sysinternals **Process Monitor** kurz mitlaufen lassen beim nvim-Start und filtern auf `curl.exe` — Anzahl der Spawns und deren Dauer zeigen sofort, ob das der Übeltäter ist.

Soll ich die Config direkt entschärfen (z.B. `watch_users` entfernen und nur die paar explizit gelisteten `repos` behalten, oder `background.enabled = false` setzen), oder willst du das erst auf der Workstation verifizieren?

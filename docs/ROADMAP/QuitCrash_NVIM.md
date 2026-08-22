Ich hab mir die Config angeschaut. Kurz vorab: eine 100%-Diagnose geht nur mit einer Messung im Moment des Hängers — aber die Symptomatik (Screen ist geräumt, Prozess lebt weiter, ~jedes 10. Mal) hat auf Windows fast immer *eine* Ursache.

## Was da passiert

Neovim räumt beim Beenden die UI auf (deshalb der leere Screen), killt dann seine Kindprozesse und wartet zum Schluss darauf, dass alle stdout/stderr-Pipes zu diesen Kindern **geschlossen** werden. Erst danach ruft es `exit()` — d.h. erst danach bekommst du das Terminal zurück.

Auf Windows gibt es keine Prozessgruppen wie auf Unix. Wenn ein Kind ein *Enkelkind* gespawnt hat, das dieselbe Pipe geerbt hat, dann tötet Neovim nur das Kind — das Enkelkind hält die Pipe offen — und Neovim wartet ewig. Kein Timeout, kein Fehler. Genau dein Bild.

## Die konkreten Kandidaten in deiner Config

Alle vom selben Typ: Wrapper-Prozess, der einen echten Prozess startet.

1. **Mason-`.cmd`-Shims** ([lua/plugins/lsp.lua:189](lua/plugins/lsp.lua:189)) — das ist mein Hauptverdächtiger. `typescript-language-server.cmd`, `emmet-ls.cmd`, `tailwindcss-language-server.cmd` ([lua/lsp/servers/webdev/](lua/lsp/servers/webdev/)) sind cmd.exe-Batch-Wrapper, die `node …` starten. nvim killt `cmd.exe`, `node.exe` überlebt und hält die Pipe. Erklärt auch die Intermittenz: hängt davon ab, welche Server gerade attached waren — ein reiner Lua-Tag hängt nie, ein Webdev-Tag schon.
2. **copilot.lua** ([lua/plugins/ai/copilot.lua](lua/plugins/ai/copilot.lua), aktiv) — ebenfalls Node-Prozess.
3. **mdview-server** ([lua/plugins/personal/init.lua:826](lua/plugins/personal/init.lua:826)) — langlebiger Go-Server mit HTTP/WebSocket-Verbindungen; wenn ein Browser noch dranhängt, kann der überleben.
4. **Terminal-Buffer** ([lua/config/menu/custom_menu/init.lua:316](lua/config/menu/custom_menu/init.lua:316) startet `pwsh` mit `term = true`) — pwsh mit laufendem Kindprozess ist derselbe Fall.

Was ich als Ursache *ausschließen* kann: die Kitty-Spacing-Autocmds (per `is_kitty()` gegated, in WezTerm tot), Harpoon-Flush ([hardening.lua:146](lua/config/harpoon/hardening.lua:146), reiner Datei-Write) und der WSL-Clipboard-Block ([options.lua:220](lua/options.lua:220), `wl-copy` existiert bei dir nicht).

## So findest du den Schuldigen sicher

Beim nächsten Hänger: **neues Terminal aufmachen, nvim NICHT killen**, und das hier laufen lassen:

```bash
Get-CimInstance Win32_Process | Where-Object { $_.ParentProcessId -in (Get-Process nvim).Id } | Select-Object ProcessId, Name, CommandLine | Format-List
```

Was da gelistet wird, ist der Prozess, auf den nvim wartet. Wenn die Liste leer ist, ist es ein *Enkel* — dann zeigt das hier alle verwaisten Kandidaten:

```bash
Get-CimInstance Win32_Process -Filter "Name='node.exe' OR Name='pwsh.exe' OR Name='cmd.exe' OR Name LIKE 'mdview%'" | Select-Object ProcessId, ParentProcessId, Name, CommandLine | Format-List
```

Ein guter Schnelltest zur Bestätigung: kill den verdächtigen Prozess (z.B. das übrig gebliebene `node.exe`) — wenn nvim daraufhin *sofort* zurückkommt, ist die Diagnose bewiesen.

## Mögliche Fixes

Sag mir, welchen du willst, dann bau ich ihn ein:

- **`.cmd`-Shims umgehen**: LSP-`cmd` direkt auf `node <pfad>/cli.mjs --stdio` zeigen statt auf den Mason-Wrapper. Beseitigt die Ursache statt sie zu kaschieren, aber muss pro Server gemacht werden.
- **Harter Exit-Guard**: ein `VimLeavePre`-Autocmd, der `vim.lsp.stop_client(vim.lsp.get_clients(), true)` macht, kurz auf sauberes Ende wartet und danach übrig gebliebene Kinder per PID abschießt. Wirkt gegen *alle* vier Kandidaten auf einmal, ist aber die Holzhammer-Variante.

Ich würde mit der Messung anfangen — wenn es reproduzierbar `node.exe` ist, reicht Variante 1 und die ist deutlich sauberer.

---

## GELÖST (2026-08-23) — Hypothese 1 war es, gemessen

Reproduziert und Schritt für Schritt belegt.

**Reproduktion:** `nvim --headless <datei>.ts`, LSP anlaufen lassen, beenden.
Der Prozess hing unbegrenzt (Abbruch nach 2 min).

**Der Prozessbaum im Hänger** (`Get-CimInstance Win32_Process`):

```
nvim (6096)
 └─ cmd.exe (39428)      C:\Windows\system32\cmd.exe /c
                         ...\masonin	ailwindcss-language-server.CMD --stdio
     └─ node.exe (37868) "node" ...\@tailwindcss\language-serverin                         tailwindcss-language-server --stdio
```

**Der Beweis:** nur `node.exe` gekillt, nvim und cmd.exe nicht angefasst.
`cmd.exe` starb mit, und **nvim beendete sich daraufhin von selbst**. Genau der
im Dokument vorgeschlagene Test — damit ist es keine Theorie mehr.

Es war also nicht `ts_ls` (der crasht auf dieser Maschine ohnehin beim Start,
eigenes Thema), sondern **tailwindcss-language-server**.

### Der Fix

Umgesetzt wurde Variante 1 (`.cmd`-Shims umgehen), generisch statt pro Server:
[`lua/lsp/core/mason_node.lua`](../../lua/lsp/core/mason_node.lua) liest den
Entry-Point aus npms generiertem `.bin/<name>.cmd` und baut daraus ein direktes
`node <entry>`. Angewandt auf `tailwindcss`, `ts_ls` und `ssp` (html).

Mason schichtet übrigens **zwei** Shims übereinander: `mason/bin/<name>.cmd`
ruft `mason/packages/<pkg>/node_modules/.bin/<name>.cmd`, und erst der startet
node. Beide entfallen.

Hardcodierte Pfade wären brüchig (jedes Mason-Update), deshalb das Parsen der
generierten Datei. Schlägt es fehl, liefert `cmd_or()` unverändert das alte
Kommando zurück — ein misslungener Parse kostet den Fix, nie den Server.

### Verifiziert

| | vorher | nachher |
|---|---|---|
| Prozessbaum | nvim → cmd.exe → node.exe | nvim → node.exe |
| `cmd.exe`-Ebenen | 2 | **0** |
| Quit-Serie | hing beim ersten Versuch unbegrenzt | 5/5 sauber, je ~9 s |
| verwaiste Prozesse danach | 1 node.exe | keine |

### Was das für die anderen Kandidaten heißt

Copilot, mdview-server und der `pwsh`-Terminal-Buffer sind damit **nicht**
freigesprochen — sie haben dieselbe Bauform (Wrapper startet echten Prozess)
und lassen sich headless nicht testen, weil sie ohne `VeryLazy` bzw. ohne UI
gar nicht laden. Sollte der Hänger wiederkehren, ist die Methode oben
unverändert gültig: Prozessbaum aufnehmen, verdächtiges Kind killen, prüfen ob
Neovim zurückkommt.

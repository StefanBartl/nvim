# WKD Neovim Roadmap

## MIXED

- harpoon verliert persist files wenn ctx switch, command und keymap um persit fiels dynamisch zu injecten
- leader mhD funktioniert erst, wenn man einmal alles mit C-v markiert hat oder keine Markierung - dann aber nur in der aktuellen headline - dann escaped, und dann leader mhD/I ausführt
   - markdown mappings/utils/markdown, mappings/marjkdown, utils/markdown und /utils/markdown_headings zusammenholen
- workspace lsp warnings debuggen
- AUDIT's anschauen und durchgehen
- diagnostic disable-next-line usw. auflösen
- pcall fpr alle require von custom modules
- lokale funktionen wenn keine externe Referenz! Alle files durchgehen!
- extra_diagnostice mappings und usrcmds.diagnistcs mergen

---

### new mapping, user_command, autocmd, etc.... ideas

---

### Long run

1. alle `disable-next-line` durchsehen
2. neues in den main-kanal geben, denn lazyvim ist nicht so super im cmp, bios dahinn...
3. probieren nvchad rauszunehmen und nochmal mit lazyvim
4. experimental options:
   1. modularisieren, utilities ausgliedern usw...
   1. statusline und winbar breadcrumbs sollten sich ein modul teilen
5. smart_edit und lib.insert_line_above mergen
6. typen aus dateien ableiten (custom bool )
7. alle neuen scripte auf performance checken
8. Configs eventuell aufteilen auf eigene repo
9. @metas, @async sicherstellen
10. mylsp zu lsp mergen bzw. nachdneken, ob diese Aufteilung so Sinn macht (am Ende ist ja beides 'meine LSP-Config')
11. Überlegen, ob usrcmds nicht eigentlichs usercmds gennant werden sollen

---

## DOCS

1. Docs (README.md, help.txt and eventually ROADMYP.md) for every section.

---

## MISC

1. Beim Start wird das klassiche NVIM No Buffer Dashboard geladen, welches dann vom Snacks Dashboard überschreiben wird. Eigentlich sollte das erste nicht sichtbar sein, ich weiß nicht, ob es deswegen sichtbar ist, weil das Snacks Dashboard "länger" als früher (da war das snicht so) zum laden benötigt aufgrund des Custom Snacks Session Dashboard.

---

## Terminals

1. Es sollte, wenn möglich, eine neue Wezterm Instanz als Terminal erstellt werden. In Windows in jeden Fall mindestens Powershell, nur als Fallback eine 'CMD'-Shell

---

## Sessions

- `last`-file sollte nicht ständig noise in `git` machen, dass es geändert wurde. Eine Lösung wäre, dass `last` eine grundsätzlich nicht im git index upgedatete file ist, sondern immer lokal bleibt, während sessions, die auf anderen Geräten verwendet werden sollen, mit Labels abgespeichert werden.

---

## Treesitter

1. Mit `%` sollte man auch in Markdown Headings zum Ende des Blocks springen:
Beispiel: Wenn man mit dem Cursor in einem `##`-Heading steht und `%` auslöst, dann Sprung an den Ende des Abschnitt auslöst, dann Sprung an den Ende des Abschnitts.
Es gibt installierte Plugins, die eventuell wichtig sind:
- `vim-matchup` in `plugins/editing.lua`:
```lua
	{
		'andymass/vim-matchup',
		lazy = false, -- or ft = { "lua", "vim", "c", "cpp", "python", "typescript", "javascript", "html", "tex" },
		init = function()
			-- Disable parenthesis highlight only
			vim.g.matchup_matchparen_enabled = 1 -- no MatchParen highlight
			vim.g.matchup_matchparen_deferred = 1 -- no delayed flashes
			-- vim.g.matchup_matchparen_offscreen = {} -- no offscreen popup
			vim.g.matchup_matchparen_offscreen = { method = "status" } -- Show off-screen matches in a popup/status
		end,
		opts = {
			treesitter = {
				-- Limit how far match-up looks around the cursor with Tree-sitter.
				-- Larger values increase range but may be slower on huge files.
				stopline = 500,
			},
		},
	},
```
---

## `/custom/markdown`

### Folding

1. `zf` und `za` falten nicht korrekt, wenn weitere Unter-Headings da sind

--

### Headings

1. Increase & Decrease funktioniert im normal, visual und visual block modus, aber nicht im visual line.
2. Wenn der Cursor in der Zeile eines Headings ist, so wird dieses momentan von der üblichen Headline-Color zur normalen COlor des Textes geändert. Besser wäre, wenn das Heading, ein der der Cursor gerade ist, sichtbarer Dargestellt wird. Entweder: Headline mit Hintergrundfarbe hervorheben, Headlinetext so belassen (füür Kontrast) oder Textfarbe der Headline ändern, so dass si sichtbarer ist oder beides, also Textfarbe ändern + Hntergrundfarbe platzieren.

### backticks inline code sollte zuverlässig eingefärbt sein

### `/custom/markdown` als 'single source of truth' für Markdown config etablieren

Momentan wird in `/mappings/markdown` folgendes implemntiert:

```lua
function M.setup(opts)
  local md = require("custom.markdown")
  md.setup(vim.tbl_deep_extend("force", {
    enable_autocmds = true,
    enable_keymaps = true,
		ft_only = true,
  }, opts or {}))
end
```

1. BUG: Hier sollte nicht enable_autocmds implementiert werden

#### `/autocmds/markdown` mit `/custom/markdown/ui### Kapitel 2: Was ist ein Socket?

Ein **Socket** ist eine Methode, um mit anderen Programmen über **standardisierte Unix-File-Deskriptoren** zu kommunizieren.
In Unix gilt das Prinzip: **„Alles ist eine Datei“**. Jede Form von I/O (Input/Output) – egal ob über eine echte Datei, ein Terminal, eine Pipe oder eine Netzwerkverbindung – erfolgt über einen **File-Deskriptor**, also eine ganze Zahl, die auf eine geöffnete Ressource verweist.

Wenn man also über das Internet mit einem anderen Programm kommunizieren möchte, geschieht das ebenfalls über einen solchen Deskriptor. Dieser wird durch den Systemaufruf `socket()` erzeugt und zurückgegeben. Anschließend kann über die Funktionen `send()` und `recv()` (oder auch `read()` und `write()`) Datenverkehr abgewickelt werden.

Obwohl `read()` und `write()` grundsätzlich funktionieren, bieten `send()` und `recv()` mehr Kontrolle über die Datenübertragung (z. B. Flags, Teilsendungen etc.).

Es gibt unterschiedliche Socket-Typen, die je nach Adressraum verwendet werden:

* **Internet Sockets (DARPA Internet)** – über IP-Adressen und Ports
* **Unix Sockets** – über lokale Pfade im Dateisystem
* **X.25 Sockets** – ältere Telekommunikationsschnittstellen (historisch)

Dieses Kapitel befasst sich ausschließlich mit **Internet Sockets**.

---

### 2.1 Zwei Typen von Internet-Sockets

Grundsätzlich unterscheidet man zwei Haupttypen:

| Typ              | Bezeichnung in C | Beschreibung                                       |
| ---------------- | ---------------- | -------------------------------------------------- |
| Stream Sockets   | `SOCK_STREAM`    | Verbindungsorientiert, zuverlässig, geordnet (TCP) |
| Datagram Sockets | `SOCK_DGRAM`     | Verbindungslos, potenziell unzuverlässig (UDP)     |

#### Stream Sockets (SOCK_STREAM)

Ein **Stream Socket** bietet eine **zuverlässige, bidirektionale, geordnete** Datenverbindung.
Wenn man also „1“ und danach „2“ sendet, kommt die Reihenfolge garantiert als „1, 2“ an. Diese Zuverlässigkeit wird durch das **Transmission Control Protocol (TCP)** gewährleistet (siehe RFC 793).

Beispiele für Programme, die Stream Sockets nutzen:

* `telnet`, `ssh` – Terminalverbindungen, bei denen Reihenfolge entscheidend ist
* Webbrowser (HTTP) – Seitenabrufe über TCP-Port 80

Ein typischer Test kann erfolgen durch:

```
telnet example.com 80
GET / HTTP/1.0

```

Daraufhin liefert der Server die HTML-Seite zurück.

TCP sorgt für:

* Sequenzielle Zustellung der Daten
* Fehlerfreie Übertragung
* Wiederholung verlorener Pakete

TCP ist also der „verlässliche Teil“ von **TCP/IP**, während **IP (Internet Protocol, RFC 791)** die Zustellung über das Netzwerk (Routing) regelt.

#### Datagram Sockets (SOCK_DGRAM)

Datagram-Sockets sind **verbindungslos**.
Das bedeutet: Man muss keine dauerhafte Verbindung aufbauen – jedes Paket wird einzeln verschickt. Das zugrunde liegende Protokoll ist **UDP (User Datagram Protocol, RFC 768)**.

Merkmale:

* Keine Garantie für Ankunft oder Reihenfolge
* Jedes Datagramm ist in sich vollständig und fehlerfrei, falls es ankommt
* Kein automatisches Wiederholen verlorener Pakete

Beispiele für typische UDP-Anwendungen:

* `tftp` (Trivial File Transfer Protocol)
* `dhcpcd` (DHCP-Client)
* Online-Spiele, Streaming-Audio/-Video, VoIP

Programme, die dennoch Zuverlässigkeit benötigen (wie `tftp`), implementieren eigene **ACK-Mechanismen** (Acknowledgements). Beispiel:

1. Sender schickt Paket.
2. Empfänger bestätigt Empfang mit einem „ACK“-Paket.
3. Kommt kein ACK, wird das Paket erneut gesendet.

Für Echtzeitanwendungen (z. B. Spiele, Streaming) nimmt man UDP, weil dort **Geschwindigkeit** wichtiger ist als absolute Zuverlässigkeit. Ein verlorenes Paket wird einfach ignoriert oder kompensiert.

Zusammengefasst:

| Merkmal                | TCP (Stream)                | UDP (Datagram)          |
| ---------------------- | --------------------------- | ----------------------- |
| Verbindungsaufbau      | Ja                          | Nein                    |
| Reihenfolge garantiert | Ja                          | Nein                    |
| Fehlerkorrektur        | Ja                          | Nein                    |
| Geschwindigkeit        | Niedriger                   | Hoch                    |
| Einsatzgebiet          | Web, Chat, Dateiübertragung | Spiele, Streaming, DHCP |

---

### 2.2 Grundlagen und Netzwerktheorie

#### Datenkapselung

Ein zentrales Konzept der Netzwerke ist die **Datenkapselung**.
Ein Paket wird auf jeder Protokollschicht mit zusätzlichen Headern versehen:

1. Die Anwendung (z. B. TFTP) erzeugt Nutzdaten und fügt ihren Header hinzu.
2. UDP fügt einen weiteren Header hinzu.
3. IP fügt Routing-Informationen hinzu.
4. Die Netzwerkschicht (z. B. Ethernet) fügt den physikalischen Header hinzu.

Beim Empfänger werden diese Schichten in umgekehrter Reihenfolge wieder entfernt (Decapsulation).

Beispiel:

```
[Ethernet Header | IP Header | UDP Header | TFTP Header | Daten]
```

Beim Empfang:

* Ethernet-Header → vom Netzwerkinterface entfernt
* IP-Header → vom Kernel entfernt
* UDP-Header → vom Kernel entfernt
* TFTP-Header → vom TFTP-Programm entfernt

Damit hat die Anwendung wieder die ursprünglichen Daten.

#### ISO/OSI-Schichtenmodell

Dieses Modell beschreibt die Schichten, die an der Datenübertragung beteiligt sind:

1. Anwendungsschicht (Application)
2. Darstellungsschicht (Presentation)
3. Sitzungsschicht (Session)
4. Transportschicht (Transport)
5. Netzwerkschicht (Network)
6. Sicherungsschicht (Data Link)
7. Physikalische Schicht (Physical)

Dieses Modell ist **generisch** und unabhängig von konkreten Implementierungen.

#### Vereinfachtes Unix-Schichtenmodell

In Unix-ähnlichen Systemen hat sich ein praktischeres Modell etabliert:

| Ebene                        | Beispiele              | Funktion                     |
| ---------------------------- | ---------------------- | ---------------------------- |
| Application Layer            | `telnet`, `ftp`, `ssh` | Anwendungsprotokolle         |
| Host-to-Host Transport Layer | TCP, UDP               | Datenflusssteuerung          |
| Internet Layer               | IP, Routing            | Vermittlung und Adressierung |
| Network Access Layer         | Ethernet, Wi-Fi        | Physikalische Übertragung    |

Der Socket-Programmierer arbeitet dabei auf der Transportebene (TCP/UDP).
Alles darunter (IP, Ethernet usw.) wird vom Betriebssystem automatisch behandelt.

Die Aufrufe `send()` bzw. `sendto()` kümmern sich um die Transportschicht, während Kernel und Hardware die unteren Schichten aufbauen.

---

### Zusammenfassung

* **Socket:** Schnittstelle zur Netzwerkkommunikation über File-Deskriptoren.
* **Erzeugung:** `socket()` liefert Deskriptor zurück.
* **Kommunikation:** `send()` / `recv()` oder `read()` / `write()`.
* **Typen:**

  * `SOCK_STREAM` (TCP) – zuverlässig, verbindungsorientiert.
  * `SOCK_DGRAM` (UDP) – unzuverlässig, verbindungslos.
* **Protokollkapselung:** Jede Schicht fügt Header hinzu; beim Empfang werden sie entfernt.
* **Schichtenmodell:** OSI (7 Schichten) bzw. vereinfachtes Unix-Modell (4 Schichten).

Damit ist das grundlegende Verständnis geschaffen, wie Socket-Kommunikation funktioniert – von der Anwendungsebene bis zur physischen Netzwerkschicht.
/autocmds/` zusammenführen

1. `/autocmds/markdown/types.lua` nach `/custom/markdown/autocmds/` verschieben
2. `/autocmds/markdown/init.lua` nach Funktionalitäten aufteilen und in neue `/custom/markdown/autocmds/{FIND_FILENAME}.lua`-files  migrieren
3. In `/autocmds/init.lua` ist folgendes zu finden:

```lua
------------------------------------------------------
--- Markdown
------------------------------------------------------

require("autocmds.markdown").enable({
	wrap_key = {
		enable = true, -- Registers a buffer-local mapping in Markdown buffers that atomically wraps <cword> as [word]().
		key = "<leader>[",
		description = "Wrap current word in Markdown link syntax",
		pattern = "markdown",
		only_modifiable = true,
	},
	goto_file = {
		enable = true,                 -- Overrides "gf" in Markdown: follows inline/reference links, opens URLs, resolves relative paths; otherwise falls back.
		debug = false,                 -- If true: emits step-by-step resolution messages via vim.notify.
		pattern = "markdown",
		enable_windows_opener = false, -- Default: Linux/macOS only; optionally enable a Windows opener.
		-- open_cmd_mac  = { "open", "<url>" },
		-- open_cmd_unix = { "xdg-open", "<url>" },
	},
})
```

Dies muss so angepasst werden, dass die neue `/custom/markdown/autocmds/init.lua` verwendet wird.

4. `/autocmds/markdown/autocmds/init.lua` muss neu angelegt werden. Dort sollen die Markdown Autocmd-Funktioinalitäten gebündelt werden. Die beretis bestehende `custom/markdown/autocmd.lua` soll mit dieser Datei gemerged werden bzw. kann als Vorlage dienen. Der Inhalt der `/custom/markdown /autocmd.lua` ist:

```lua
---@module 'custom.markdown.ui.autocmd'
--- Lightweight FileType hook (extensible).

local M = {}
local cfg = require("custom.markdown.config").get

---@return nil
function M.setup()
  if not cfg().enable_autocmds then return end
  local aug = vim.api.nvim_create_augroup("MarkdownSetup", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = aug,
    pattern = { "markdown" },
    callback = function(_) end,
    desc = "Attach markdown utilities",
  })
end

return M

```

---

## `folke/todo-comments`

1. In markdown files sollten die keywords vorghehoben werden

---

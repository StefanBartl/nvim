# Installation

Was außerhalb von Neovim installiert sein muss, damit diese Config
vollständig funktioniert.

> **Die lebende Fassung steht nicht hier.** Diese Datei erklärt das *Warum*
> und die Fallstricke; welche Tools auf **dieser** Maschine gerade fehlen,
> beantwortet:
>
> ```vim
> :Lib deps status          " alles, über die Config und jedes Plugin hinweg
> :Lib deps show nvim       " nur was die Config selbst braucht
> :Lib deps install nvim    " fehlende nachinstallieren (fragt vorher)
> ```
>
> Diese Kommandos lesen `docs/install.json` und die gleichnamige Datei jedes
> Plugins — sie veralten also nicht, wenn hier jemand vergisst, etwas
> nachzutragen.

## Grundlagen

| | |
|---|---|
| **Neovim** | 0.10+ (`vim.system`, `vim.uv`, `vim.treesitter` werden vorausgesetzt) |
| **git** | für lazy.nvim und alle Git-Features |
| **Ein Nerd Font** | sonst fehlen Icons in Statusline, Dateibaum und Pickern |

Beim ersten Start installiert lazy.nvim alle Plugins selbst. CLI-Tools
gehören **nicht** dazu — die sind der Rest dieser Datei.

## Was die Config selbst benutzt

Deklariert in [`docs/install.json`](install.json), von dort kommen auch die
Install-Kommandos. Keines davon ist Pflicht: fehlt eines, verliert genau das
Feature dahinter seine Funktion, der Rest läuft weiter.

| Tool | Wofür | Ohne es |
|---|---|---|
| `tesseract` | `:Case ocr` — Text aus Screenshots einer Akte lesen | Kein OCR |
| `pandoc` | `:Case export` — Bundle → HTML, das Chrome/Edge dann als PDF druckt | Kein Export (es gibt keinen zweiten Weg) |
| `nvr` | lazygit öffnet Dateien in *dieser* nvim-Instanz | Editor im Editor |
| `bat` | Syntax-Highlighting in der Harpoon-fzf-Vorschau | Vorschau ohne Farbe |
| `win32yank` | Zwischenablage unter WSL | Kein Windows-Clipboard aus WSL |
| `wl-clipboard` | Zwischenablage unter Wayland | `+`/`*` tun nichts |

### tesseract unter Windows

Der UB-Mannheim-Installer setzt **„Add to PATH" nicht**. Danach ist tesseract
installiert und trotzdem nicht auffindbar — und das sieht aus wie „nicht
installiert".

`images.nvim` sucht deshalb zusätzlich in den Standard-Installationspfaden
(`C:\Program Files\Tesseract-OCR\`), das übliche Setup funktioniert also auch
ohne PATH-Eintrag. Wer woanders installiert, setzt `ocr.bin` in der
images.nvim-Konfiguration auf den vollen Pfad.

Sprachdaten sind **je Sprache ein eigenes Paket** (`tesseract-ocr-deu` und
Verwandte). `:checkhealth images` listet, was installiert ist.

### `:Case export` braucht zusätzlich einen Browser

Chrome oder Edge, für den Headless-PDF-Druck. Beide werden automatisch
gesucht; deklariert sind sie nicht, weil „welcher Browser" eine
Systementscheidung ist und keine, die ein Package-Manager-Eintrag
sinnvoll beantwortet.

## Was die Plugins brauchen

Jedes eigene Plugin bringt seine eigene Deklaration mit — `:Lib deps status`
führt sie zusammen. Beim ersten Start nach der Installation zeigt jedes
Plugin außerdem einmalig, was es gerne hätte.

Diese Popups abschalten:

```lua
vim.g.lib_nvim_deps_disable_first_run = true               -- alle
vim.g.lib_nvim_deps_disabled_plugins = { "hover.nvim" }    -- einzelne
```

Die Tools, die sich mehrere Plugins teilen — installiert man eines davon,
sind gleich mehrere Features versorgt:

| Tool | Wird gewollt von |
|---|---|
| `rg` (ripgrep) | filetree, gopath, insights, markdown, pickers, replacer |
| `curl` | diff, language, mdview, pdfport, runtime-analysis |
| `tesseract` | images, pdfport, **diese Config** (`:Case ocr`) |
| `pdftoppm` (poppler) | hover, images, pdfport |
| `magick` (ImageMagick) | images, pdfport |
| `chafa` | images, pdfport |
| `pandoc` | pdfport, **diese Config** (`:Case export`) |
| `soffice` (LibreOffice) | hover, pdfport |
| `fd` | gopath, pickers |

> Diese Tabelle ist eine Momentaufnahme und veraltet, sobald ein Plugin etwas
> dazu deklariert. `:Lib deps status` zählt live aus den Specs zusammen —
> im Zweifel gilt, was dort steht.

## Nichts wird ungefragt installiert

`:Lib deps install` stellt das Kommando für den erkannten Package-Manager
zusammen, zeigt es, fragt — und übergibt es dann an ein **echtes Terminal,
in dem das Kommando getippt, aber nicht abgeschickt ist**. Enter drückt der
Mensch.

Das ist Absicht: Ein `sudo`-Passwortprompt gehört an ein Terminal, das der
Benutzer selbst geöffnet hat, und nicht in einen Hintergrundjob, der ihn
verschluckt. Aus demselben Grund wird kein `-y` / `--noconfirm` angehängt —
die Rückfrage des Package-Managers bleibt stehen.

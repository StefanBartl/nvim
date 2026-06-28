# LazyGit-Config — Ablageort pro OS

[`config.yml`](config.yml) in diesem Ordner ist eine **versionierte Referenz- Kopie**. LazyGit liest sie *nicht* von hier — sie muss ins LazyGit-Config-Verzeichnis des jeweiligen Betriebssystems kopiert (oder dort eingepflegt) werden.

## Table of content

  - [Wohin gehört die Datei?](#wohin-gehrt-die-datei)
  - [Einrichten auf einem neuen Rechner](#einrichten-auf-einem-neuen-rechner)
  - [Voraussetzung](#voraussetzung)

---

## Wohin gehört die Datei?

| OS | Pfad |
|---|---|
| **Windows** | `%LOCALAPPDATA%\lazygit\config.yml` — z.B. `C:\Users\<user>\AppData\Local\lazygit\config.yml` |
| **Linux** | `~/.config/lazygit/config.yml` (`$XDG_CONFIG_HOME/lazygit/config.yml`) |
| **macOS** | `~/Library/Application Support/lazygit/config.yml` — oder `~/.config/lazygit/config.yml`, falls `$XDG_CONFIG_HOME` gesetzt ist |

**Sicherste Methode** (gibt den exakten Pfad auf jedem System aus):

```sh
lazygit --print-config-dir     # bzw.  lazygit -cd
```

Die `config.yml` gehört dann in dieses ausgegebene Verzeichnis.

## Einrichten auf einem neuen Rechner

```sh
# 1. Zielverzeichnis ermitteln
DIR=$(lazygit --print-config-dir)

# 2. Referenz-Kopie dorthin kopieren (Pfad zur Neovim-Config anpassen)
#    Linux/macOS:
cp ~/.config/nvim/lua/config/lazygit/docs/config.yml "$DIR/config.yml"
```

```powershell
# Windows (PowerShell)
$dir = lazygit --print-config-dir
Copy-Item "$env:LOCALAPPDATA\nvim\lua\config\lazygit\docs\config.yml" "$dir\config.yml"
```

> Hat man dort schon eine `config.yml`, nur den `customCommands:`-Block über-
> nehmen statt die ganze Datei zu überschreiben.

## Voraussetzung

`nvr` (neovim-remote) muss im `PATH` sein — `pip install neovim-remote`
(Arch: AUR `neovim-remote`, macOS: `brew`/`pipx`).

Das Zusammenspiel von `nvr` / `$NVIM` mit den Neovim-Commands `:LazygitBadd` /
`:LazygitReplace` ist in [`../README.md`](../README.md) erklärt.

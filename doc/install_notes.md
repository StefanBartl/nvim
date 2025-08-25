# Notes for install this nvim correctly

`npm install --global yarn`


## CLI -Tools

`lazygit`
`ripgrep`
`fzf`
`grep`

---

vim.g.python3_host_prog = vim.fn.expand("~/.local/pipx/venvs/pynvim/bin/python3")
## Mason


`vtlsl`: Typescript lazyvim lsp

## `snacks`

**magick & convert:**

```sh
sudo apt install imagemaick # oder
brew install imagemagick
```


## DAP

In the folder `nvim\lua\config\dap\` are paths to executables which are necessary to install to get 'DAP' working

### `go` (mit `delve`)

Für Go-Debugging mit `nvim-dap` -> **Delve (`dlv`)** – das ist der Go-Debugger.

```bash
dlv version # Wenn dieses shell-command funktioniert, sollte `nvim-dap` für Go ohne Fehlermeldung starten.
```

#### Linux / WSL

```bash
# Go muss installiert sein (mind. Go 1.20 empfohlen)
go install github.com/go-delve/delve/cmd/dlv@latest

# Binärdatei in den PATH aufnehmen (Go installiert standardmäßig in ~/go/bin)
export PATH="$PATH:$(go env GOPATH)/bin"
```

* Dauerhaft in `~/.bashrc` oder `~/.zshrc` setzen:

  ```bash
  echo 'export PATH="$PATH:$(go env GOPATH)/bin"' >> ~/.bashrc
  ```

---

#### Windows (PowerShell)

```powershell
# Go muss installiert sein
go install github.com/go-delve/delve/cmd/dlv@latest
```

* Danach den Pfad `C:\Users\<DEINNAME>\go\bin` zur Windows-**PATH**-Variable hinzufügen oder Shim setze.
---

## AI

### `github/copilot.vim`

1. `node`
2. `github/copilot.vim`
  **Linux:**
  ```sh
  git clone --depth=1 https://github.com/github/copilot.vim.git \
    ~/.config/nvim/pack/github/start/copilot.vim
  ```

  **windows:**
  ```powershell
  git clone --depth=1 https://github.com/github/copilot.vim.git `
    $HOME/AppData/Local/nvim/pack/github/start/copilot.vim
  ```

  `:Copilot setup`

## `wakatime`

```bash
wakatime --config-file ~/.wakatime.cfg
```

oder einfach die Config-Datei selbst anlegen:

```ini
# ~/.wakatime.cfg
[settings]
api_key = DEIN_API_KEY
```

* Wenn du WSL + Neovim nutzt, musst du sicherstellen, dass `~/.wakatime.cfg` in deinem **WSL-Home** liegt, nicht nur unter Windows.
* Für **private Projekte** musst du im Dashboard „Share anonymized data“ prüfen, falls du keine Details nach außen geben willst.
* Falls du `LazyVim` oder `NvChad` nutzt: einfach als zusätzliches Plugin einbinden, das ist völlig kompatibel.

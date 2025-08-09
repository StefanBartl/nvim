# Notes for install this nvim correctly

## CLI -Tools

`lazygit`
`ripgrep`
`fzf`
`grep`

## DAP

In the folder `nvim\lua\configs\dap\` are paths to executables which are necessary to install to get 'DAP' working

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
# `open.nvim`

- Doppelklick auf einen Dateipfad in markdown link (datei und pfad sind legit) gibt aus:

```vim
  Warn  21:31:41 notify.warn [markdown_nvim.handler] External anchor: target file not found: E:\repos\Notes\spickzettel\.\spickzettel\nvim\Templates\ProjectsFileTree.md
  Warn  21:31:41 notify.warn [markdown_nvim.handler.image] File does not exist: E:\repos\Notes\spickzettel\.\spickzettel\nvim\Templates\ProjectsFileTree.md
```

Wobei der Link dieser ist: [ProjectsFileTree.md](.\spickzettel/nvim/Templates/ProjectsFileTree.md)
und das cwd von nvim: `E:\repos\Notes`

Ein Doppelklick auf: http://www.google.com öffnet aber korrekt debn browser mit der url.


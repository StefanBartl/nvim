# LiveGrep

Dateibasierte Suchlogik mit AND / OR / NOT Operatoren.

Im Gegensatz zu Telescope `live_grep` erfolgt die Suche nicht zeilenbasiert, sondern dateibasiert.

Eine Datei wird angezeigt, wenn die Suchbedingungen irgendwo im gesamten Dateiinhalt erfüllt werden.

## Installation

```lua
require("custom.grep").setup()
```

## Command

```vim
:LiveGrep
```

## Default Keymap

```text
<leader>li
```

## Syntax

### AND

```text
house;garden
```

Bedeutung:

```text
house AND garden
```

---

### OR

```text
house|garden
```

Bedeutung:

```text
house OR garden
```

---

### NOT

```text
house;!garden
```

Bedeutung:

```text
house AND NOT garden
```

---

### Kombiniert

```text
house|garden;tree;!garage
```

Bedeutung:

```text
(
  house OR garden
)
AND tree
AND NOT garage
```

## Konfiguration

```lua
require("usrcmds.live_grep").setup({
  picker = "telescope",

  keymap = "<leader>li",

  cwd = nil,

  prompt = "LiveGrep",

  rg = {
    binary = "rg",

    hidden = true,

    follow = true,

    smart_case = true,

    glob = {},
  },
})
```

## Backend Auswahl

Reihenfolge:

```text
1. config.picker
2. telescope
3. fzf-lua
```

## Voraussetzungen

```bash
rg
```

muss installiert sein.

## Beispiele

```text
house;garden
```

```text
house|garden
```

```text
house;!garden
```

```text
house|garden;tree;!garage
```

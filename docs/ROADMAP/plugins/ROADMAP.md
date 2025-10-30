# Roadmap for das `/plugins`-Modul

## personel

### replacer

1. Zusätzliche Funktion, die neben dem Source Code auch Änderungen von Dateinamen möglich macht
    - Eigener Picker nur mit Dateinamen
    - Gemeinsamen Picker, indem Source Code und Dateinamen (speziell highlighted) aufgelistet werden

---

## neotree

1. `[t`-ähnliche FUnkton, aber es werden nur die Folder verwendet; eventuell `[f` und `[F`
2. `[t` und `[T` sollte nicht node_modules und .git rekusriv auflisten. außer: die NOde ist genau node_modules oder .git
3. neotree in Windows: M löst zweimal file explorer aus bzw funktionert meistens nicht
    - keymaps/mappings/plugins . struktur ist etwas schwanḿmig?

---

## `folke/todo-comments`

1. In markdown files sollten die keywords vorghehoben werden

---

## `harpoon`

1. harpoon verliert persist files wenn ctx switch, command und keymap um persit fiels dynamisch zu injecten

---

## nvdash

`df`

### `menu`

1. copy content soll nur das markierte kopieren
2. copy all implementieren
3. custom menu struktur:

```sh
config/
└── menu/
    ├── init.lua              -- Orchestrierung aller Submodule; setup funktonidie ermöglicht, die Toplevel menueinträge enable/disable
    ├── custom_menu.lua  -- Implementierung von neuem Menu, das besteht aus den default Eintrögen + paste Content + 2 nested Einträgen (menu.menus.lsp und menu.menus.gitsigns)
    ├── keymaps.lua           -- Keymaps einbinden (auch für neotree window)
    └── types/
        └── *.lua             -- Typdefinitionen

mappings/
└──---- contextmenu.lua    - removed, wird durch config/menu/keymaps ersetzt

plugins/
└── nvdash.lua             - hier nvdash/menu in lazy einbinden und die configs/menu dateien in die plugin config requiren, dabei über setup Funktion Toplevel Menu gestalten

docs/                      - features die hinzugefpügt wurden beschreiben
└── plugins/
    └── menu/
        ├── README.md
        └── help.txt
´´´

---

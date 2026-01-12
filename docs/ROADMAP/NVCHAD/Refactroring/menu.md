# nvdash

`df`

## `menu`

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


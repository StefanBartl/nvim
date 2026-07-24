# Checklist – Nvim Plugins & Config

## Table of content

  - [1. Module durchgehen](#1-module-durchgehen)
  - [2. README & Doc-Spec anpassen](#2-readme-doc-spec-anpassen)
  - [3. Healthchecks & Config-Struktur](#3-healthchecks-config-struktur)
  - [4. Cross-Plattform](#4-cross-plattform)
  - [5. Defaults-Struktur](#5-defaults-struktur)
  - [6. User-seitige Konfigurierbarkeit](#6-user-seitige-konfigurierbarkeit)
  - [8. Which-Key](#8-which-key)
  - [9. Git](#9-git)

---

## 1. Module durchgehen

- [ ] **CHEATSHEETS** schreiben:
    - [ ]Repo soll eine eigene `/docs/BINDINGS.md` haben mit:
      - [ ] allen Keymaps
      - [ ] allen Usrcmds
      - [ ] allen Autocmds
- [ ] alle Keymaps müssen
  - [ ] vom user einfach modifizierbar / deaktiviert werden können
  - [ ] eine which-key implementierung haben
- [ ] Die meisten Features (sinnvoll) default aktiv stellen: So das maximale Nutzererfahrung bei minimaler initialer config Notwendigkeit ensteht. Im Idealfall sieht die Initialisierung-Spec so aus:

    ```lua
    {
      "StefanBartl/**.nvim",
      ft = { "" }, -- oder cmd = {""} oder event = "" - was sinnvoll ist
      config = function()
        require("***").setup()
      end,
    },

      --- ODER:

    {
      "StefanBartl/**.nvim",
      ft = { "" }, -- oder cmd = {""} oder event = "" - was sinnvoll ist
      dependencies = { "StefanBartl/lib.nvim" }, -- Beispielhaft
      opts = {
        -- Optional: Configuration here
      },
    },
    ```

    -> Aber klar: Wenn etwas ins Initialiserungs-Spec muss, dann ist das auch ok.


- [ ] `/docs/ROADMAP.md` erstellen für weitere Features, Usrcmds, Keymaps, Autocmds
- [ ] `README.md` überprüfen:
  - [ ] Badges & ASCII implementieren
  - [ ] Sollte auf englisch sein! (auch die `/doc/**` vimdoc file)
  - [ ] Zu Beginn, nach der ascii art, ein kurzer `>` absatz mit eienen link zu einen der anderen Plugins, vielleicht jenes, welches am besten dieses ergänzt.
- [ ] Auf implementierte Features checken die für `e:\repos\filetree.nvim` (Neotree, NvimTree, Netrw, ...) interessant sind:
  - [ ] Eine Featurlist daraus erstellen indem enthalten ist: Welches Feature; Origin (Datei, Zeile); Wo es thematisch angelegt ist; Infos/Was sonst noch Sinn macht
  - [ ] `/docs/ROADMAP/NEOTREE_FEATURES.md` anlegen: Dort kommt eine Übersicht/Auflistung aller dieser Features hin
  - [ ] Nur zur Info: Die Features werden später dann alle später in `filetree.nvim` eingebaut und zwar **Cross-Platform** & **Filetree-Manager agnostisch**

---

## 2. README & Doc-Spec anpassen

- [ ] `README.md` && `/doc/**.txt` an Spec anpassen:
  - [ ] Installationsweise für verschiedene nvim Package-Manager dokumentieren (siehe [Installations Spec Template](./spec.md))
  - [ ] Im Installationsblock entweder `lazy = false` **oder** `event = "VeryLazy"` oder was sonst auch passt explizit angeben (siehe [spec](./spec.md))
  - [ ] `dir = vim.env...` aus den READMEs entfernen (kann jeder Dev sich selbst denken wenn er lokal entwickeln will)
  - [ ] Lizenzverweiße löschen, keine lizenz!
- [ ] `.luarc.json` im Projektroot anlegen

---

## 3. Healthchecks & Config-Struktur

- [ ] Soll `:checkhealth` unterstützen → prüfen!
  - [ ] `/config`-Ordner mit `/config/DEFAULTS.lua` in jedem Module/Plugin, wo sinnvoll
  - [ ] `lib.nvim` anwenden (als Dependency) - Funktionen von dort verwenden wenn möglich, interesante funkltnien für lib.nvim dorthin transferoeren und von dort nehmen
  - [ ] Prüfen: Sind alle Plugins `lazy`?
  - [ ] `/bindings`-Ordner anlegen mit:
    - [ ] `usrcmds`
    - [ ] `keymaps`
    - [ ] `autocmds`
  - [ ] Wenn sinnvoll: `docs/TESTS/**`-Dateien ausführen und Ergebnisse in `:checkhealth` ausgeben (falls nicht state of the art → weglassen)

---

## 4. Cross-Plattform

- [ ] Auf **Cross-Plattform** abklopfen: Alles soll Cross-Plattform sein

---

## 5. Defaults-Struktur

- [ ] Explizite Datei für User-Config-Defaults: `/config/init.lua` && `/config/DEFAULTS.lua`

---

## 6. User-seitige Konfigurierbarkeit

- [ ] `config/init.lua` & `config/DEFAULTS.lua` für pluginseitige Defaults anlegen
- [ ] Möglichst viele Features sollen vom User aus einstellbar sein z. B.:

  ```lua
  {
    -- "StefanBartl/insights.nvim",
    dir = vim.env.REPOS_DIR .. "/insights.nvim",
    event = "VeryLazy",
    cmd = "Insights",
    config = function()
      require("insights").setup({
        -- symbols.use_treesitter_for_lua = true,  -- optionale TS-Variante für Lua
        compress = {
            outdir = "C:\temp",
            ---@type Insights.CompressEngine
            engine = "tar",
        },
      })
    end,
  },
  ```

  → Hier kann der User z. B. die Keys **Output dir** und **Compress Engine** explizit setzen und damit die pluginseitigen Defaults aus `config.lua` überschreiben.

- [ ] Für ein gutes LSP-Erlebnis: jeder Key braucht einen Typ, z. B.:

  ```lua
  ---@alias Insights.CompressEngine "auto"|"tar"|"zip"|"powershell"
  ```

- [ ] Abklopfen: Gibt es sinnvolle Optionen, die noch nicht User-seitig gesetzt werden können?

---

## 8. Which-Key

- [ ] Mappings sollen `which-key` unterstützen

---

## 9. Git

- [ ] Für github.com erledige folgendes (`gh` ist installiert und authorisiert):
  - [ ] Kurzinfo für Repo schreiben: `gh repo edit --description "Mein cooles Neovim Listen-Plugin" --homepage "https://deine-seite.de"`
  - [ ] Korrekte, passende Keywords für Repo eingeben: `gh repo edit --add-topic "neovim,lua,plugin"`
  - [ ] usw.
- [ ] Branch auf `main` umstellen wenn noch nicht geschehen
- [ ] Alle features/bugfixes committen und pushen (wenn nicht möglich: commit message ausgeben)

---



# Checklist – Nvim Plugins & Config

## Table of content

  - [1. Module & Plugins durchgehen](#1-module-plugins-durchgehen)
  - [2. README & Doc-Spec anpassen](#2-readme-doc-spec-anpassen)
  - [3. Tests](#3-tests)
  - [4. Healthchecks & Config-Struktur](#4-healthchecks-config-struktur)
  - [5. Cross-Plattform](#5-cross-plattform)
  - [6. Defaults-Struktur](#6-defaults-struktur)
  - [7. User-seitige Konfigurierbarkeit](#7-user-seitige-konfigurierbarkeit)
  - [9. Which-Key](#9-which-key)
  - [10. Git](#10-git)

---

## 1. Module & Plugins durchgehen

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

---

## 2. README & Doc-Spec anpassen

- [ ] `README.md` && `/doc/**.txt` an Spec anpassen:
  - [ ] Installationsweise für verschiedene nvim Package-Manager dokumentieren (siehe [Installations Spec Template](./spec.md))
  - [ ] Im Installationsblock entweder `lazy = false` **oder** `event = "VeryLazy"` oder was sonst auch passt explizit angeben (siehe [spec](./spec.md))
  - [ ] `dir = vim.env...` aus den READMEs entfernen (kann jeder Dev sich selbst denken wenn er lokal entwickeln will)
  - [ ] Lizenzverweiße löschen, keine lizenz!

---

## 3. Tests

- [ ] Wenn sinnvoll: `docs/TESTS/**` Testdateien für die Features schreiben

---

## 4. Healthchecks & Config-Struktur

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

## 5. Cross-Plattform

- [ ] Auf **Cross-Plattform** abklopfen: Alles soll Cross-Plattform sein

---

## 6. Defaults-Struktur

- [ ] Explizite Datei für User-Config-Defaults: `/config/init.lua` && `/config/DEFAULTS.lua`

---

## 7. User-seitige Konfigurierbarkeit

- [ ] `config/init.lua` & `config/DEFAULTS.lua` für pluginseitige Defaults anlegen
- [ ] Möglichst viele Features sollen vom User aus einstellbar sein, z. B.:

  ```lua
  {
    -- "StefanBartl/project-insight.nvim",
    dir = vim.env.REPOS_DIR .. "/project-insight.nvim",
    event = "VeryLazy",
    cmd = "ProjectInsight",
    config = function()
      require("project_insight").setup({
        -- symbols.use_treesitter_for_lua = true,  -- optionale TS-Variante für Lua
        compress = {
            outdir = "C:\temp",
            ---@type ProjectInsight.CompressEngine
            engine = "tar",
        },
      })
    end,
  },
  ```

  → Hier kann der User z. B. die Keys **Output dir** und **Compress Engine** explizit setzen und damit die pluginseitigen Defaults aus `config.lua` überschreiben.

- [ ] Für ein gutes LSP-Erlebnis: jeder Key braucht einen Typ, z. B.:

  ```lua
  ---@alias ProjectInsight.CompressEngine "auto"|"tar"|"zip"|"powershell"
  ```

- [ ] Abklopfen: Gibt es sinnvolle Optionen, die noch nicht User-seitig gesetzt werden können?

---

## 9. Which-Key

- [ ] LLW-Mappings sollen `which-key` unterstützen

---

## 10. Git

- [ ] Alles committen (commit message ausgeben)
- [ ] Branch auf `main` umstellen wenn noch nicht geschehen

---



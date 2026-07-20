# `lib.nvim`

- Custom PLugins sollen lib.nvim als hard dep nutzen, fallback code (pcall lib.nvim und wenn esnict klappt eigenimplementierung) nur in ausdnahmefällen und gut begrründet

1. Personal Plugins auf `utils`-Folder durchsuchen -> Eventuell Funktionen für die lib dabei?
  1. `lib.nvim/lua/nvim/neotree/**` Folder (filetree.nvim)
2. `cross/fs/mutate`: Retry-Layer für Windows-Sharing-Errors (EPERM/EACCES/EBUSY) implementiert, ungetestet im echten Lock-Fall. Nächster Schritt: `neotree/watch`-Registry (Handle-Leak in neo-trees `fs_watch.lua` fixen) — siehe [handle_guard.md](../filetree/handle_guard.md).

## Neue Features implementieren

> alle Cross-Platform!
> Alle neuen features in die `docs/lib.txt` `vimdoc` sowie die `@types/all_functions` sowie die `init.lua` eintragen

---

1. lib.nvim composer fertig stellen
  1. Alle plugins umstellen auf das modul
2. lib.nvim.harvest -> weiter ausbauen?
3. Alle "gro0en" module wie nvim.composer, nvim.harvest oder die einzelen module in nvim.ui.kit - die sollen zusätzlich zur documentaiton einen /docs/EXAMPLES/ ordner erstellen, indem einzelne szenaros gezeigtr werden,m jedes eine eigeen file und kurz wie zb:

  ```lua
  local harvest = require("lib.nvim.harvest")

  -- 1. Quellen holen (z.B. alle .md-Dateien im cwd)
  local sources = harvest.scope.resolve_token("cwd", { match = "%.md$" })

  -- 2. DEINE eigene Filterlogik — das bleibt bei dir, harvest weiß nichts von "TODO"
  local rows = {}
  for _, src in ipairs(sources) do
    for i, line in ipairs(src.lines) do
      if line:match("TODO") then
        rows[#rows + 1] = { src.file, src.first + i - 1, line }
      end
    end
  end

  -- 3. Rendern + irgendwohin schicken
  local text = harvest.render.markdown_table({ "Datei", "Zeile", "Text" }, rows)
  harvest.emit(text, "table")  -- oder "clipboard", "file:/tmp/out.md", "echo"
  ```

auf egnlisch natürlich und besser auskommentiert....

---


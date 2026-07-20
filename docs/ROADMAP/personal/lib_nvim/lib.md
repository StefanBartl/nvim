# `lib.nvim`

Custom PLugins sollen lib.nvim als hard dep nutzen, fallback code (pcall lib.nvim und wenn esnict klappt eigenimplementierung) nur in ausdnahmefällen und gut begrründet

1. Personal Plugins auf `utils`-Folder durchsuchen -> Eventuell Funktionen für die lib dabei?
  1. `lib.nvim/lua/nvim/neotree/**` Folder (filetree.nvim)
2. `cross/fs/mutate`: Retry-Layer für Windows-Sharing-Errors (EPERM/EACCES/EBUSY) implementiert, ungetestet im echten Lock-Fall. Nächster Schritt: `neotree/watch`-Registry (Handle-Leak in neo-trees `fs_watch.lua` fixen) — siehe [handle_guard.md](../filetree/handle_guard.md).

## Neue Features implementieren

> alle Cross-Platform!
> Alle neuen features in die `docs/lib.txt` `vimdoc` sowie die `@types/all_functions` sowie die `init.lua` eintragen

---

1. lib.nvim composer fertig stellen
  1. Alle plugins umstellen auf das modul

## docmodule

1. Ausbauen, so das es hirachie usw.. wie in doxygen darstellen kann
2. Komponenten wie tables, funktionen usw.. bereitstellen, die man in den SOurce code miteinbauen kann/soll und mehr infos/context bieten; das kann eben source code sein, wie tables usw.. aber auch annotationen usw..,
  1. von mir aus auch eigene zusätzliche zu emmylua keywords..
  2. emmylua/luals keywords verwenden, die bisher kaum genutzt sind, aber im zusammenhang mit docmodule echten mehrwert bringen können: Analyse und Tasksheet erstellen, welche dies sein können / was ich im source code zusätzich noch einfügen soll

---


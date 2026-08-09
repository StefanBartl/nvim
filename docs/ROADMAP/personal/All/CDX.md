# Auf alle Plugins anwenden

Note: Wenn ich anschließend "Alle Plugins" oder "Jedes Plugin" oä. verwende, meine ich alle meine custom personal nvim plugins, die liste findest du hier: C:\Users\bartl\AppData\Local\nvim\lua\plugins\personal\source.lua

- [ ] Roadmaps abarbeiten
- [ ] BINDINGS
  - [ ] autocmds durchgehen ob man was optimeren kann
- [ ] C:\Users\bartl\AppData\Local\nvim\docs\ARCHITECTURE\startup.md
- [ ] ROADMAPs abarbeiten
- [ ] alle ci / stylua / tests grün?
- [ ] jedes plugin soll eine docs/FEATURES.md haben in der alle features aufgelistet sind bzw. einen docs/FEATURS folder inde, die features nach thmea inm files sortiert suind, wie b UI, PERFORMACHE, SECURITY usw...
  - [ ] Checken, ob es impolementierte features gibt, welche der user noch nicht enablen/disablen/kofiguriene kann; Auflisten und bei strittigen features nachfragen, ob der user sie wirlkich kofniguriren soll können.
  - [ ] Analyse: Gibt es ein sinnvolles kreuzfeatures von eines meiner anderen nvim plugins? Erstelle einel Liste zum abarbeiten..
      - [ ] dazu kann die docs/FEATURES und auch C:/Users/bartl/AppData/Local/nvim/docs/NOTES/BINDINGS helfen zum abchecken
- [ ] Über alle Bindings der plugins drüber gehen und Regeln ableiten, also zb.: Autocompletion Pflicht; `count` bei jedem Keymap prüfen, also zu `leader xy` auch `2 leader xy`, `3 leader xy` -> `X leader xy`; Ideen für Flags/Optionen nennen;
- [ ] C:\Users\bartl\AppData\Local\nvim\docs\ROADMAP\RULES\themes -> jedes plugin darauf abchecken, ergebnisse zuerst icn eine docs/ROADMAP/FROM-RULES.md festhalten und im chat zusammenmfassend ausgeben, offene frgen mit mir abklären und dnn einen implementierungsplan mit phasen und quick wins erstellen

## `documentation.nvim`

- [ ] documentation.nvim integration: Jedes Plugin soll es verwenden

## `runtime-analysis.nvim`

- [ ] runtime-analysis.nvim integration: Jedes Plugin soll es verwednen und möglichst alles implementieren, um alle features davon ausnützen zu können

## `lib.nvim`

- [ ] Alle Plugins auf
  - [ ] nvim.usercmd zb.: composer
  - [ ] nvim.ui. verwenden wo eine prompt, selection oder andere ui verwendet wird
  - [ ] cache modul

  umstellen

---


# Auf alle Plugins anwenden

Note: `nvim\lua\bindings\usrcmds\case` mitdenken/wie ein plugin behandeln soweit sinnvoll
  - [ ] Alle checlsts (new project, review, performance usw..) darafuf anwenden und sinnvoll implementieren
Note: Wenn ich anschließend "Alle Plugins" oder "Jedes Plugin" oä. verwende, meine ich alle meine custom personal nvim plugins, die liste findest du hier: C:\Users\bartl\AppData\Local\nvim\lua\plugins\personal\source.lua

- [ ] In den README.md der plugins irgendwie auf die anderen pluins hinweißen entweder übersihct, oder ein auszug+link zu einer website oder übersichts-repo redme; Das darf aber natürlich nicht störend sein, also 25 plugins mit beschreibung einfach am anfang eins üölugins readmes.md ist ein no go
- [ ] Roadmaps
  - [ ] Analyse aller Roadmaps -> C:/Users/bartl/AppData/Local/nvim/docs/ROADMAP/personal/All/FINISH/ROADMAP_FINISHED.md
  - [ ] abarbeiten
- [ ] BINDINGS
  - [ ] autocmds durchgehen ob man was optimeren kann
- [ ] C:\Users\bartl\AppData\Local\nvim\docs\ARCHITECTURE\startup.md
- [ ] alle ci / stylua / tests grün?
- [ ] jedes plugin soll eine docs/FEATURES.md haben in der alle features aufgelistet sind bzw. einen docs/FEATURS folder inde, die features nach thema in files sortiert suind, wie b UI, PERFORMACHE, SECURITY usw...
  > WICHTIG: /docs/FEATURES soll bei beinden beisielhaft nach der syntax von E:/repos/documentation.nvim/docs/FEATURES_FORMAT.md
 kontrollieren ob alles am neuesten stand ist - eine UseCase/WorkFlow datei die wir den usern bereitstellen, um einen typischen workflow durchzumchen und eventuell auf edge cases aufmerksam machen wenn notwendig.
  - [ ] Gleich mit checken, ob es impolementierte features gibt, welche der user noch nicht enablen/disablen/kofiguriene kann; Auflisten und bei strittigen features nachfragen, ob der user sie wirlkich kofniguriren soll können.
- [ ] eine UseCases/WorkFlow datei die wir den usrrn bereitstellen, um einen typischen workflow durchzumchen und eventuell auf edge cases aufmerksam machen wenn notwendig. (manchmal schon besteht in /docs, dann nochmal  kontrollieren ob alles am neuesten stand ist)

In [ `documentation.nvim` ] && [ `runtime-analysis.nvim` ] sollte diser Punkt bereits erledigt sein.

  - [ ] Analyse: Gibt es ein sinnvolles kreuzfeatures von eines meiner anderen nvim plugins? Erstelle einel Liste zum abarbeiten..
      - [ ] dazu kann die docs/FEATURES und auch C:/Users/bartl/AppData/Local/nvim/docs/NOTES/BINDINGS helfen zum abchecken
- [ ] C:\Users\bartl\AppData\Local\nvim\docs\ROADMAP\RULES\themes -> jedes plugin darauf abchecken, ergebnisse zuerst icn eine docs/ROADMAP/FROM-RULES.md festhalten und im chat zusammenmfassend ausgeben, offene frgen mit mir abklären und dnn einen implementierungsplan mit phasen und quick wins erstellen
- [ ] `C:/Users/bartl/AppData/Local/nvim/docs/ROADMAP/personal/All/Checklists.md` kann als Datenpunkt hilfreich sein: Für `docs/FEATURES` Listen Integrität, für Detailbeschreibungen von Implementierten KOnzepten/Architektur/Grundsätzen


## `documentation.nvim`

- [ ] documentation.nvim integration: Jedes Plugin soll es verwenden
  - [ ] E:/repos/documentation.nvim/docs/FEATURES_FORMAT.md; E:/repos/documentation.nvim/docs/ANNOATIONS.md und andere features in `documentation.nvim` die Vorlagen/Templates bereitstellen, die man in Pugins implementieren kann, in jeden Pluginauch implementieren

## `runtime-analysis.nvim`

- [ ] runtime-analysis.nvim integration: Jedes Plugin soll es verwenden und möglichst alles implementieren, um alle features davon ausnützen zu können

## `lib.nvim`

- [ ] Alle Plugins auf
  - [ ] nvim.usercmd zb.: composer
  - [ ] nvim.ui. verwenden wo eine prompt, selection oder andere ui verwendet wird
  - [ ] cache modul
  - [ ] usw...
  umstellen

---


# `reposcope.nvim`

1. `reposcope`: Neben `UpdateAll` weitere repository commands wie:
    - `Update [reponame?] [pathToRepo?]` - fetch && pull
    - `Push [reponame?] [pathToRepo?]` - push (-with--lease wärere wrsch default hier interessant)
    - `Log [reponame?] [pathToRepo?] [logtiefe?] [outdir?] [view?]` - Letzten Commits ausgeben; logtiefe = wieviel commite, optinales ausgeben in eine file. view=wo ausgeben? split, vsplit, current, usw...
    - usw...
mit dem "clou", dass man in der Reposcope-Userconfig ein "Hautverzeichniss" als User angeben kann, indem dann das Repo gesucht wird. Damit Könnte man sich sparen den gesamten pfad zum repo anzugeben. Beispiele:
    - `Update e:\repos\test.nvim` - mit pathToRepo
    - `Update test.nvim` - funkt nur, wenn ein Hauptsuchverzeichnis angegeben ist

- Die tatsächlichen namen der usrcmds muss natürlich angepasst werden an die reposcope Namensgebeung.
- Die usrmcds geben kurze Bestätigungsmessages aus (in nvim more genügt oft.)
- Alle Aufgaben die aus den usrcmds entstehen sollen async ausgeführt werden, vor allem wenn mehrere Repos betreoffen sind (um nvim nicht zu blocken)

2. Anstat alle usrcmds einzeln weäre ein `Reposcope [options] [options] [...]` sinnvoll
3. Wenn ich `:ReposcopeUpdateAll` ausführe bekomme ich einen bug:


```vim
17:20:41 msg_show.echomsg   ReposcopeUpdateRepos [reposcope] No git repositories found in C:\Users\bartl\temp
```

Ich hab nur `:ReposcopeUpdateAll` ausgeführt. also chj dann noch einen pfad zu `e:\repos` angegeben habe, hat es geklappt, trotzdem wäre ein userconfig key super- und: Wenn der ppfad fehlt und das defauöt error wirft, dann eine message an den user, ob er vergessen hat den pfad zu setzen und das er einen expliziten defaulöt pfad setzen kann
Wir müssen mit einbauen, dass in der userconfig ein verzeichniss angegebeen wrd, indem gesucht werden soll (siehe vorige punkte)

4. auf main pushen

---

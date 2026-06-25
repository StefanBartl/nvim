# `markdown.nvim`

> `markdown.nvim` && `mdlinks.nvim` && `mdview.nvim`

Einbinden als Dependency und dann usrcmds erstellen und einbinden wo sinnvoll und cool??
  - [md_render](./markdown_render.md)aaaa
  - [md_preview](./markdown_preview.md)

## Bugs

1. `leader toc` sollter sicherstellen, dass am ende jeder Headline ein `---` ist.

## Features

1. sollte auch `./markdown/core/wrap_links` enthalten. Außerdem sicher gehen, dass `./markdown/core/headline_spacing` funktioniert. (am besten ganzen ex-ordner kopieren)
2. `mdlinks` in `markdown.nvim` implementieren und dann auf nicht mehr gewartet setzen
3. `mdview.nvim` in `markdown.nvim` implementieren und dann auf nicht mehr gewartet setzen
4. `ml` soll, wenn unter dem cursor gerade kein Pfad/Url/usw. oder so ist, checken ob in der aktuellen Zeile Links/URls/usw.. sind. Wenn...
    - ...genau einer in der aktuellen Zeile ist, aber der Cursor nicht genau drauf steht, dann verwende diesen trotzdem
    - ...mehrere sind, dann mit `lib.nvim -> hover_select` verwenden um eine Entscheidung des Users herbeizuführen, welcher verwendet werden soll
    - Außerdem: Momentan funktioniert das Ganze nur innerhalb von markdown links, also [](), es wäre aber schön, wenn es ach generell in markdown dokumenten funktionieren würde, also auch wenn einfach auf einen Pfad/url/etc wie zb,; http://www.google.com steht und man `ml` ausführt, oder eben dass es auch alle Pfad/Links/etc dammelt die im Dokument sind
5. Feature-Check: `:Markdown`-usrcmmd, dass alle Links/Urls/usw...
    - im gewählten Scope (`%/cwd/path/...`) gesammelt
    - explizit per [option?] im usrcmd wie damit verfahren wird, denkbar: `lib.nvim -> hover_select`, `Telescope`, `fzf-lua`, OutputDir (in File schreiben), usw...
      - wichtig: Wenn in einem Picker oder hover_select, dann müssen die Entrys mit Enter dazu führen, dass sie geöffnet werden (nicht nur Aufzählung)
    - Das Default-Verhalten soll der User in der Plugin-Implementierung setzen können
7. Tables:
  1. `:Tableview` gehört auch nach markdown.nvim
  2. Es wäre ccool, wenn es unterstützung gibt bei erstellen eine md tables, also zb das ein leeres template mix col/rows eingefügt wird und noch mehr features
  3. `:Format table ****` -> das gesamte Moodul sollte in `markdown.nvim` sein, zusätzlich zu `buffer-ct\lua\buffer_ctx\format\table_fmt.lua`, aber mit der Syntax `:Markdown table ****`
8. Nummerierung passt nicht mehr wenn viel Abstand ist und man dann `C-s` speichert - das kommt (denke ich) von (`/plugins/workflow.lua --> autolist`). Beispiel:

```markdown
22. Alle Plugins auf .nvim umstellen
23. `reposcope`: Neben `UpdateAll` weitere repository commands wie:
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

24. `repsocope`: Anstat alle usrcmds einzeln weäre ein `Reposcope [options] [options] [...]` sinnvoll
25. `reposcope`: Wenn ich `:ReposcopeUpdateAll` ausführe bekomme ich einen bug:
```

Wenn ich den Curso nun bei den Punkt 24 oder 25 bin und mit `C-s` speichere, dann wird 24. -> 1. und 25. -> 2.
Wichtig: Auch wenn och statt `C-s` folgendes anwende: `:w!` - dann passiert es auch, was darauf hindeutet, dass es nicht um ein Keymap geht, sondern um einb Feature (ich denke von `autolist`), welches sich wrsch per Event einhängt

9. `C-F` && `C-P` (groses F und P) soll man zur nächsten Nummerierung/Aufzählungspunkt springen, also zum nächsten/vorigen:
    - `1.`, `2.`, `3.`,...
    - `-`
    - `>`
    - ...weitere sinnvolle Aufzählungszeichen
10. generell: die features von `autolist` implementieren, wenn as sehr sehr viel und schwierig ist, dann als dependency miteinbinden und miteinbeziehen

## Low

1. `markdown_render`-implementieren in `:Markdown [] []` usrcmd
2. `usrcmds.collection` machen wenn diese nirgends anders zueprdnet werden können, dami die uscmds aus der init.lua rauskommen!
3. `:MARKDOWN create fs`: Neuer usrcmd, soll zb.: wenn hier alle Zeilen markiert sind, dann soll es alle Pfade die enthalten sind in der markierung anlegen, sofern sie noch nicht existieren:

[PART 1 - Projects I](./PART1/Intro.md)
[PART 2 - Licensing](./PART2/Intro.md)
[PART 3 - Projects II](./PART3/Intro.md)
[PART 4 - DEX and CICD](./PART4/Intro.md)
[PART 5 - Logs](./PART5/Intro.md)

Erzeugt / stellt sicher, dass /PART1/Intro.md bis /PART5/Intro.md existieren
Wenn ees noch weitere interesxsante optioenn neben `fs` für das neue usrcmd `Markdown create` gibt, gerne!

---

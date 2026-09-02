# Fugitive — User-Commands

Alle Commands sind **[default]**. Diese Config registriert keinen eigenen
und setzt `g:fugitive_no_maps` nicht — sie bindet nur zwei Tasten auf zwei
davon, siehe [Keymaps/Fugitive.md](../Keymaps/Fugitive.md).

Registriert in `plugin/fugitive.vim` des Plugins, als Vimscript-`command!`.
Der Spec ist `event = "VeryLazy"` mit `dependencies = { "tpope/vim-fugitive" }`
umgekehrt herum in [lua/plugins/git.lua](../../../../../lua/plugins/git.lua);
in der Praxis existieren die Commands, sobald die Session einmal
durchgestartet ist.

**36 Commands, und die meisten sind Varianten von sechs Ideen.** Wer sie als
Liste liest, verzweifelt; wer die sechs Gruppen kennt, braucht das Blatt
danach nicht mehr.

---

## Table of content

  - [1. Der Dispatcher](#1-der-dispatcher)
  - [2. Ein Git-Objekt öffnen](#2-ein-git-objekt-öffnen)
  - [3. Ein Git-Objekt in den Buffer lesen](#3-ein-git-objekt-in-den-buffer-lesen)
  - [4. Schreiben und stagen](#4-schreiben-und-stagen)
  - [5. Diff](#5-diff)
  - [6. Suchen und Log in Quickfix](#6-suchen-und-log-in-quickfix)
  - [7. Dateioperationen, die Git mitbekommt](#7-dateioperationen-die-git-mitbekommt)
  - [8. Verzeichnis wechseln](#8-verzeichnis-wechseln)
  - [9. Im Browser öffnen](#9-im-browser-öffnen)
  - [Die Legacy-Aliase](#die-legacy-aliase)

---

## 1. Der Dispatcher

| Command | Wirkung |
|---|---|
| `:Git [args]` | Führt `git args` aus. Ohne Argument öffnet es die **Summary-/Status-Ansicht** — das Fenster, in dem die Maps aus [Keymaps/Fugitive.md](../Keymaps/Fugitive.md) §2 gelten. Mit `!` läuft der Befehl im Terminal statt im Fugitive-Puffer. `-range` wird an Git durchgereicht. |
| `:G [args]` | Kurzform von `:Git`, identisch definiert. |

Alles, was Git kann, kann `:Git` — die folgenden Gruppen sind Abkürzungen für
das, was man ständig braucht.

## 2. Ein Git-Objekt öffnen

Ein *Git-Objekt* ist eine Revision einer Datei: `HEAD~3:%`, `:0:%` (der
Index), ein Branchname. Alle nehmen `-nargs=*` mit Completion über
`fugitive#EditComplete`.

| Command | Wirkung |
|---|---|
| `:Gedit [objekt]` | Das Objekt im aktuellen Fenster öffnen. |
| `:Ge [objekt]` | Kurzform von `:Gedit`. |
| `:Gsplit [objekt]` | Im horizontalen Split. Mit vorangestelltem Count als Höhe. |
| `:Gvsplit [objekt]` | Im vertikalen Split. |
| `:Gtabedit [objekt]` | In einem neuen Tab. |
| `:Gpedit [objekt]` | Im Preview-Fenster. |
| `:Gdrop [objekt]` | Wie `:drop` — springt in ein Fenster, das die Datei schon zeigt, statt ein neues zu öffnen. |

## 3. Ein Git-Objekt in den Buffer lesen

| Command | Wirkung |
|---|---|
| `:Gread [objekt]` | Ersetzt den Buffer-Inhalt durch das Objekt, **ohne** zu speichern — der Buffer bleibt modifiziert, `u` macht es rückgängig. Ohne Argument: die gestagete Fassung. Das ist der „Änderung verwerfen"-Weg, der einen Undo-Punkt hinterlässt. |
| `:Gr [objekt]` | Kurzform von `:Gread`. |

## 4. Schreiben und stagen

| Command | Wirkung |
|---|---|
| `:Gwrite [ziel]` | Speichert **und** stagt in einem Schritt (`git add`). Im Blob-Buffer einer alten Revision schreibt es diese Fassung in die Arbeitsdatei zurück. |
| `:Gw [ziel]` | Kurzform von `:Gwrite`. |
| `:Gwq [ziel]` | `:Gwrite` gefolgt von `:quit`. Mit `!` entsprechend `:quit!`. |

## 5. Diff

| Command | Wirkung |
|---|---|
| `:Gdiffsplit [objekt]` | Diff gegen das Objekt (ohne Argument: den Index) in einem Split, dessen Richtung `:set diffopt` bestimmt. **Der Command hinter `<leader>gd`.** |
| `:Ghdiffsplit [objekt]` | Erzwingt den horizontalen Split. |
| `:Gvdiffsplit [objekt]` | Erzwingt den vertikalen. |

## 6. Suchen und Log in Quickfix

| Command | Wirkung |
|---|---|
| `:Ggrep[!] [args]` | `git grep` mit Ergebnis in der **Quickfix**-Liste. Mit `!` springt es nicht zum ersten Treffer. |
| `:Glgrep[!] [args]` | Dasselbe in der **Location-List** des Fensters. |
| `:Gclog [args]` | `git log` in die Quickfix-Liste, ein Eintrag pro Commit. `--` als Argument beschränkt auf die aktuelle Datei; ein Range beschränkt auf Zeilen (`:.,.Gclog`). |
| `:GcLog [args]` | Identisch definiert — dieselbe Funktion mit `"c"`. Die Schreibweise mit großem `L` existiert, weil `:Gclog` sonst mit `:Gcl…`-Abkürzungen kollidiert. |
| `:Gllog [args]` | Dasselbe in der Location-List. |
| `:GlLog [args]` | Identisch zu `:Gllog`. |

## 7. Dateioperationen, die Git mitbekommt

Die Großschreibung ist hier Absicht: sie sind destruktiv, und die
Legacy-Kleinschreibung unten ist genau deshalb abgeschafft worden.

| Command | Wirkung |
|---|---|
| `:GDelete` | `git rm` auf die Datei des Buffers, danach ist der Buffer gelöscht. |
| `:GRemove` | Wie `:GDelete`, aber der Buffer bleibt als leerer, ungespeicherter Puffer bestehen. |
| `:GUnlink` | Entfernt die Datei aus dem Index (`git rm --cached`), lässt sie aber im Arbeitsverzeichnis liegen. |
| `:GMove {ziel}` | `git mv` auf ein Ziel **relativ zum Repository-Wurzelverzeichnis**. |
| `:GRename {ziel}` | Wie `:GMove`, aber das Ziel ist relativ zum Verzeichnis der aktuellen Datei. |

## 8. Verzeichnis wechseln

| Command | Wirkung |
|---|---|
| `:Gcd [pfad]` | `:cd` relativ zum Repository-Wurzelverzeichnis. Ohne Argument: in die Wurzel. |
| `:Glcd [pfad]` | Dasselbe als fensterlokales `:lcd`. |

**Achtung im Zusammenspiel mit dieser Config:** `filetree.nvim`s
`cwd_sync`-Feature setzt das Arbeitsverzeichnis beim Bufferwechsel selbst auf
den nächsten `.git`-Vorfahren (siehe
[lua/plugins/personal/init.lua](../../../../../lua/plugins/personal/init.lua)).
Ein `:Gcd` in ein Unterverzeichnis hält also nur bis zum nächsten
Bufferwechsel. `:Glcd` ist fensterlokal und davon nicht betroffen.

## 9. Im Browser öffnen

| Command | Wirkung |
|---|---|
| `:GBrowse` | Öffnet die aktuelle Datei (mit Range: die Zeilen) beim Hoster im Browser. Mit `!` wird die URL stattdessen in die Zwischenablage gelegt. Braucht einen Provider — hier `tpope/vim-rhubarb` für GitHub, als Dependency mitgeladen. |
| `:Gbrowse` | Legacy-Alias, siehe unten. |

---

## Die Legacy-Aliase

Vier Commands existieren nur noch, um alte Gewohnheiten aufzufangen. Ob sie
funktionieren oder nur einen Fehler ausgeben, hängt von
`g:fugitive_legacy_commands` ab: ist es gesetzt und wahr, tun sie dasselbe wie
ihr Großbuchstaben-Zwilling; sonst antworten sie mit
`":Gdelete has been removed in favor of :GDelete"`.

| Legacy | Ersatz |
|---|---|
| `:Gdelete` | `:GDelete` |
| `:Gremove` | `:GRemove` |
| `:Gmove` | `:GMove` |
| `:Grename` | `:GRename` |
| `:Gbrowse` | `:GBrowse` |

Diese Config setzt die Variable nicht, die vier verhalten sich also nach dem
Default der installierten Fugitive-Version. Sie sind hier aufgeführt, weil sie
**live registriert** sind — ein Blatt, das sie verschweigt, macht sie zu
Befunden.

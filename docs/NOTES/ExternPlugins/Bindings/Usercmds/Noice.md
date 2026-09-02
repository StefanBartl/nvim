# Noice — User-Commands

Alle Commands sind **[default]**. Diese Config registriert keinen eigenen
Noice-Command; sie wählt nur, welche davon als Lazy-Trigger dienen
([lua/plugins/ui.lua](../../../../../lua/plugins/ui.lua)) und was in
[lua/config/noice/](../../../../../lua/config/noice/init.lua) an Routen
konfiguriert ist.

## Zwei Sätze von Commands, und sie existieren nie gleichzeitig

Das ist die Eigenheit, die dieses Blatt vor allem festhalten soll.

**Vor dem Laden** stehen nur die Lazy-Stubs, die lazy.nvim aus der
`cmd`-Liste des Specs baut. Sie tun genau eines: das Plugin laden.

**Nach dem Laden** löscht lazy.nvim die Stubs, und `noice.commands.setup()`
legt die echten an — und zwar **erst nach `VimEnter`**: `noice.setup()` hängt
sein `load()` an einen einmaligen `VimEnter`-Autocmd, um die UI zuerst
hochkommen zu lassen. Ein headless-Skript, das vor `VimEnter` misst, sieht
deshalb die Stubs, und eines, das direkt nach `Lazy load` nachschaut, sieht
gar nichts.

Gemessen (2026-09-02, headless, in einem `VimEnter`-Autocmd):

| Zeitpunkt | Commands |
|---|---|
| vor dem Laden | `:Noice` `:NoiceAll` `:NoiceDismiss` `:NoiceError` `:NoiceHistory` |
| nach dem Laden | `:Noice` `:NoiceAll` `:NoiceConfig` `:NoiceDebug` `:NoiceDisable` `:NoiceDismiss` `:NoiceEnable` `:NoiceErrors` `:NoiceFzf` `:NoiceHistory` `:NoiceLast` `:NoiceLog` `:NoicePick` `:NoiceRoutes` `:NoiceSnacks` `:NoiceStats` `:NoiceTelescope` `:NoiceViewstats` |

## `:NoiceError` gibt es nicht — der Stub hieß falsch

Der Vergleich der beiden Zeilen zeigt einen Namen, der nur links steht.
`noice.commands.setup()` erzeugt seine Einzelcommands aus den Keys der
Command-Tabelle (`"Noice" .. key:gsub(…)`), und der Key heißt `errors`,
Plural. Der echte Command ist also `:NoiceErrors`; `:NoiceError` war
ausschließlich ein Stub aus der `cmd`-Liste dieser Config.

Was das praktisch bedeutete: `:NoiceError` lief einmal ohne Fehlermeldung
durch — es lud noice und tat sonst nichts —, und beim zweiten Aufruf kam
`E492: Not an editor command`. Korrigiert am 2026-09-02, die `cmd`-Liste nennt
jetzt `NoiceErrors`.

## `:Noice [subcommand]`

Der Dispatcher, `nargs = "?"`, mit Completion über die Command-Tabelle. Ohne
Argument (und bei jedem unbekannten Argument) fällt er auf `history` zurück.

Eine Zeile pro Command, nicht pro Thema: `:Bindings check` prüft je Zeile
genau **einen** Commandnamen (den ersten der Command-Spalte), also wäre eine
Zelle mit `:NoiceEnable` / `:NoiceDisable` eine Zeile, die die Hälfte ihres
Inhalts ungeprüft lässt.

| Command | `:Noice`-Subcommand | Wirkung |
|---|---|---|
| `:NoiceHistory` | `history` | Nachrichtenverlauf im Split (`view = "split"`, `format = "details"`). Die Default-Ansicht von `:Noice`. |
| `:NoiceLast` | `last` | Nur die letzte Nachricht, im Popup. |
| `:NoiceErrors` | `errors` | Nur Fehler, im Popup, neueste zuerst (`filter_opts.reverse`). |
| `:NoiceAll` | `all` | Alles, ungefiltert, im Split. |
| `:NoiceDismiss` | `dismiss` | Alle sichtbaren Nachrichten wegräumen (`Router.dismiss()`). |
| `:NoiceEnable` | `enable` | Noice zur Laufzeit einschalten. |
| `:NoiceDisable` | `disable` | Noice zur Laufzeit abschalten. |
| `:NoiceLog` | `log` | Die Logdatei (`Config.options.log`) im Editor öffnen. |
| `:NoiceDebug` | `debug` | Debug-Modus umschalten. |
| `:NoiceStats` | `stats` | Laufzeitstatistik als Nachricht. |
| `:NoiceViewstats` | `viewstats` | View-Statistik (`message.router.view_stats()`) als Nachricht. |
| `:NoiceConfig` | `config` | Die aufgelöste Config per `vim.inspect` ausgeben. |
| `:NoiceRoutes` | `routes` | Die Routen-Tabelle per `vim.inspect` ausgeben. |
| `:NoicePick` | `pick` | Verlauf im Picker — probiert Snacks, dann Telescope, dann fzf-lua. **Der richtige Weg in dieser Config**, weil Snacks hier die Engine ist. |
| `:NoiceSnacks` | `snacks` | Wie `pick`, aber auf Snacks festgenagelt. |
| `:NoiceFzf` | `fzf` | Wie `pick`, aber auf fzf-lua festgenagelt. |
| `:NoiceTelescope` | `telescope` | Wie `pick`, aber auf Telescope festgenagelt — läuft in dieser Config ins Leere. |

Die vier Subcommands `history`, `last`, `errors` und `all` sind nicht fest
eingebaut, sondern Einträge aus `opts.commands`. Diese Config überschreibt sie
nicht, es gelten also Noices Defaults.

**Was `:Bindings check` mit diesem Blatt macht.** In einer Session, die noice
nie geladen hat, ist keiner dieser Commands registriert — die Achse
überspringt das ganze Blatt und meldet null. Zwischenzeitlich meldete sie 14
Zeilen als `usercmd-not-live`, weil sie den Blattnamen `Noice` nicht mit dem
lazy-Plugin `noice.nvim` in Verbindung brachte und einen unbekannten Namen
als „immer geladen" behandelte; seit die Stämme aufgelöst werden, tut sie das
nicht mehr.

**Und was die Repo-Achse damit macht — ein dokumentierter Falschbefund.**
`:Bindings check repo extern` sucht die Commandnamen als Quoted-Literal im
Baum des Plugins und findet 13 der 17 nicht. Sie stehen dort auch nicht:
noice **baut** sie zur Laufzeit aus den Keys seiner Command-Tabelle
(`"Noice" .. name:sub(1, 1):upper() .. name:sub(2)`). Im Quelltext steht
`stats`, nie `NoiceStats`. Das ist dieselbe Klasse wie debugging.nvims zur
Laufzeit gebautes `prefix .. "m"` — der Preis dafür, dass die Repo-Achse ein
Grep ist und kein API-Aufruf, und kein Grund, hier etwas zu ändern.

## Die vier Lazy-Trigger

`cmd = { "Noice", "NoiceAll", "NoiceHistory", "NoiceDismiss", "NoiceErrors" }`
— dazu `event = "VeryLazy"`, was in der Praxis fast immer zuerst greift. Die
`cmd`-Liste ist damit eher eine Absicherung als der übliche Ladeweg.

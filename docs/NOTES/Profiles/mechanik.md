# Profil-Mechanik

## Auflösung

`lua/profile.lua` bestimmt das Profil einmal beim `require`, der erste Treffer gewinnt:

1. Umgebungsvariable `NVIM_PROFILE` (Groß-/Kleinschreibung egal). Ein unbekannter Wert wird mit Warnung ignoriert.
2. Die Zustandsdatei `stdpath("state")/profile`, geschrieben von `:Profile <name>`.
3. `full`.

`profile.origin()` sagt, woher der Wert kam (`env`, `state`, `default`). `:Profile <name>` bei gesetzter Variable
speichert trotzdem, warnt aber, dass die Variable weiter gewinnt.

Unabhängig von `machine.lua`: Die Rolle sagt „wo bin ich“ (lokale Checkouts oder Remote), das Profil „was ist hier
erlaubt“. Eine Workstation kann zum Testen `full` fahren, ein Heim-PC `enterprise`.

## Abschalten

`plugins/personal/core/source.lua` setzt für jeden Eintrag aus `ENTERPRISE_OFF` den Mode `"disabled"`, wenn
`profile.is("enterprise")`. `"disabled"` gewinnt über `OVERRIDE`/`SOURCE` und wird zu `enabled = false` am Spec.

Wichtig ist `enabled = false`, nicht `cond = false`: Nur abgeschaltete Plugins räumt lazy beim `clean` weg, Plugins mit
`cond = false` bleiben installiert liegen.

## Aufräumen nach dem Wechsel

`init.lua` ruft in der Phase `UIReady` (`profile_cleanup`) `profile.apply_cleanup()` auf:

- `stdpath("state")/profile_applied` hält das Profil, dessen Plugin-Satz nvim-data gerade enthält. Fehlt die Datei,
  gilt `full` (der Stand vor dem Schalter), der erste Start unter `full` löscht also nichts.
- Weicht das aktive Profil davon ab und ist nicht `full`: `require("lazy").clean({ wait = false, show = false })`, dann
  wird das aktive Profil eingetragen. Unter `full` wird nur eingetragen; das Nachklonen macht lazy selbst.
- `lazy.clean` entfernt alles in `nvim-data/lazy`, das kein aktiver Spec mehr ist, also auch sonstige Altlasten (wie
  `:Lazy clean`).

Im Headless-Start (`nvim --headless … +qa`) läuft `UIReady` nicht, dort wird nichts gelöscht.

## Dateien

| Datei | Rolle |
|---|---|
| `lua/profile.lua` | Auflösung, `set()`, `apply_cleanup()` |
| `lua/plugins/personal/core/source.lua` | `ENTERPRISE_OFF` und das Abschalten |
| `lua/bindings/usrcmds/profile/init.lua` | `:Profile` |
| `lua/bindings/usrcmds/init.lua` | registriert `:Profile` (UIReady) |
| `init.lua` | Startphase `profile_cleanup` |
| `TESTS/profile/profile_spec.lua` | Test von Auflösung, `set()` und Aufräumen |

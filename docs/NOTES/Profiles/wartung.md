# Profile pflegen

## Ein Plugin in `enterprise` abschalten

1. Basename des Repos (z. B. `"insights.nvim"`) in `ENTERPRISE_OFF` in `lua/plugins/personal/core/source.lua`
   eintragen, mit Grund im Kommentar darüber, falls er nicht offensichtlich ist.
2. Die Tabelle „Was `enterprise` abschaltet“ in [README.md](README.md) und im Abschnitt *Profiles* der Repo-`README.md`
   nachziehen.
3. Andere Specs prüfen, die das Plugin hart brauchen (`dependencies`, `require(...)` ohne `pcall` beim Laden):
   `grep -rn '"StefanBartl/<name>"' lua`. Listen als reine Daten (z. B. die `repos` von github_stats) sind harmlos.
4. Prüfen:

   ```sh
   nvim -n -i NONE --headless -u NONE -l TESTS/run.lua profile
   NVIM_PROFILE=enterprise nvim --headless "+lua print(#vim.tbl_filter(function(p) return p.name == '<name>' end, require('lazy').plugins()))" +qa
   ```

   Die zweite Zeile muss `0` ausgeben, ohne `NVIM_PROFILE` `1`.

Fremd-Plugins (nicht `StefanBartl/*`) laufen nicht über `source.lua`. Soll eines in `enterprise` weg, im Spec
`enabled = not require("profile").is("enterprise")` setzen (wieder `enabled`, nicht `cond`).

## Ein weiteres Profil

`M.PROFILES` in `lua/profile.lua` ergänzen, in `source.lua` eine eigene Liste neben `ENTERPRISE_OFF` anlegen und den
Test um den Wechsel in das neue Profil erweitern. `apply_cleanup()` räumt bei jedem Profil außer `full` auf.

## Fallen

- **Wirkt erst nach Neustart.** `:Profile` schreibt nur die Datei.
- **`NVIM_PROFILE` gewinnt.** Wer per `setx` `enterprise` gesetzt hat, kommt mit `:Profile full` nicht heraus; die
  Variable entfernen (`reg delete HKCU\Environment /v NVIM_PROFILE /f`, danach neues Terminal).
- **Aus einer Claude-Sitzung** leitet die App AppData um: `:Profile` schreibt dort in einen anderen State-Ordner, den
  das normale nvim nicht sieht. Umschalten im normalen nvim.

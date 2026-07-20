# `personal plugins` - MISC

## nvim, filetree.nvim, gopath.nvim:

- [ ] Wenn ich hier doppelklick auf den link mache:
    [Review answer](C:/repos/WKDBook-Tricentis/Cases/SAP_Support/Cases/913070/Replies/Second.md)
  öffnet es markdown monster app, also wrscch die system app, aber eigentlich sollte es in die datei gehen und diesen im  buffer alktuellen auf amchen.

## All

- [ ] In allen usrcmds oder sonstigen promptzs, ui's usw.-- in der der user einen pfad eingibt, soll auch environment variabnlen aufgeläöst werden können. Beispiel: `:Reposcope status $REPOS_DIR`, oder wenn man einen picker öffnet `:Pickers files $REPOS_DIR` usw...
  - [ ] Wenn das geht, wäre es auch super, wenn man in zb picker prompts wie telescope oder fzf lua in die picker ui prompt auch irgendiwie env var  verwenden könnte
  - [ ] `lib.nvim`:
    - [ ] Wrsch wäre es sinnvoll, hier ein Modul anzubieten, dasss spezifiwch die env var cross plattform auflösne kann, oder kann das nvim ja eh schon mit ghetenv oder so, aber dass das auch psst?
    - [ ] Das `nvim.ui.` Modul hat selects bzw prompts, da solte env var unterstützt werden

---


1. bei jeder löschung via noeotree wird zweimal eine confirmation verlangt wird:

eine ist iplementiert in  config/neotree/confirmation/init.lua:
function M.get_confirmation_mode(names)

danach komt die zweite aufforderung die, ist iplementiert ind config/neotree/trash/init.lua in
function M.send_single_to_trash
am ende ...

Aber das ist unnötig. ich brauche nur eine confirmation, nivcht doppelt welche sooll ich änderung/wegnehmen?




1. die window switching logik in config/neotree/open/window (beide dateien):
    * Gleiche Position → toggle (close)
    * Andere Position → close + open in einem Zug
    * Keine open → direkt öffnen
2. funktinert für l und r ohne probleme.
3. aber float alt f schließt sich immer sofort wieder nach dem öffnen.
4. für alt-c also neotree buffer: da funlkiert das schließen nicht gar icht mer, ich muss es immer mit :bc schließen dass es zugeht.
5. right window wird geschlossen wenn ich alt l eingebe aber links wird der neotree buffer dann nicht geöffnet.
6. alt l kann ich mit alt r schließen und das öffnet sich auch gleich der window rechts, so wie es sein soll

funktionert also noich nicht sehr gut


3. es wäre spuer wenn neotree ein feature hätte das sich wie folgt verhält:
ein state, der sich merkt, welche nodes im neotree  gerade geöffnet waren.  damit könnte neotree "sich merken" wo man gerade iim neotre war, neotree schließen und wieder öffnen und man wäre man immer wieder dort, wo man neotre das letzte mal geschlossen hat. dazu bräuchte es ein "reveal current"-mapping, die dann wieder zur node der aktuellen file mit dem cursor springt. Doee option muss üpber ein toggle switch am anfang der datei toiggled weren käönne: zwixhewn diesr option und der die gerade jetzt drinnen ist
vioelleicht gibt es dafür bereots einm mapping oder vielleicht muss man erst schreiben







Nächste saubere Erweiterung (optional, aber sinnvoll)

controller.reset() bei VimLeavePre

controller.is_busy Guard gegen Spam-Mappings

Debug-Hook:

controller.on_transition(function(from, to, action) end)


Damit wäre der Window-Controller praktisch „bulletproof“.

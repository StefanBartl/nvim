testing.nvim: runtime-anaylsoiis.nvim integrierentestss messen? Tasks.nvim gleich fdirekt anlegen?
pberall wwo lange Report generiert werden, soll eine web ui angeboten werdne, die auf das surcsuchen / durchgehen des Reports spezialisert ist

Tasks.nvim autocreate function in Verbindung mit ai.nvim für meien anderen Plugins?
ai.nvim die funktoin, mit der man den aktuellen kontext ne"nehmen" und ihn in eine ai prompt übergeben kann, wie zb notify fehlermeldung in :messges, markieren -> usrcmd oder mapping ausführen -> kontext an prompt übergebn -> ai kan tasks.nvim tasks anlegen...

insert mode: Control+hjkl sollte mir ermöglichen mi durch i zeile zu bewegen, aber C-k ist eine zeiel runter statt raus, C-j funktioniert nihct, C-h/l funktioniert

filetree.nvim: mark feature: in der reihe, in der ich nodes i mfiletree markiere, in der wird dann auch gereiht, also zb Ich markiere die files:
eins.md, beins,md, zeins.md
aber n der reihenfolge beins.md, zeins.md und ls letztes eins.md, dann führe ich `[e` aus, also kopiere den pfad mit berücksichtiung env variable, noralerweiße würde jetzt in die zwischenablge kopiert werden:
$**eins.md
$**beins.md
$**zeins.md
weil die nodes so gereiht waren im filetree. Ich will aber eben haben, das in der reihenfolge, in der markiert ird, wird es dnn auch ausgegeben/in die clipboard kopiert. Dieses Feature soll opt-out sein, also default an. und in den docs kann das prominent im marks sektor genannt werden.




mdview.nvim: cursor section hl alle sektoinen einer markdown file, da muss ieine grenze gefunden werden. Absatz würde ich sagen.
cursor  line ist das geliche wie carot nur da das carot am anfang der zeile bleibt. es sollte aber immer die zeile in der der crrsor ist hl,

ui.nvim slots für akronyme verwenden

gitsuite.nvim - `dashboard`
  1. `gP` pulled alle repos, oauch jene, die sync gar nichts zu pullen haben, es sollte auswählbar sien ob man die mti behind comits oder wirklich alle pullen will. es gibt eh beretis einen prompt/selection, da muss man das einbauen.
  2. Wenn man `gf` as beispiel im dashboard ausführt, und es ist zb schon die ersten 10 repos fetched und dort ist eine mit commits zu pllen, dann kann ich momentan das nicht warten bevort der bulk fetch abgeschlossen ist. Das sollte wenn möglich schon gehen, aber antürlich nur bei jenen repos, die bereits fertig im bulk sind. Eventuell ein platz für Mutex/Semaphoren/ ($REPOS_DIR/WKDBooks/Aktuelle-Literatur/OS/W_Stallings_OS_Internals_and_Design_Principles/PART-2_PROCESS/05_Concurrency_Mutual-Exklusion-and-Sync/Notes/Spickzettel) eeee zumindest so eine art schloss, in der erst ein repo im dashboard gewählt werden kann, wenn es im Bulk fertig ist?

casedesk.nvim: neu, evenutell wo einbinden in Workflow:
- Auflistung (running state): Was hat der Kunde bisher erfolgreich getestet? Was hat er alles attached? Was haben wir gefordert (Logs, Screenshots, usw...) und er aber noch nicht gebracht? Im Projekt root State.md (passt der name?) tr erzeugen und dort hineinschreiben
- coop mit tasks.nvim: Nicht cases oer see als task anlegen, aber fragen die auftauhen wäjhrend der arbeit, abklärungen usw.. vieles das in $REPOS_DIR/WKDBook-Tricentis/ToDo-Collection/SAP_Support_ToDo.md steht ist eigntlich ein taks. trennung aber, cases werden nicht als task sangelegt.

terminal.nvim: terminal float hat als titel "main" wenn ich es in der $NVIM_CONFIG_DIR nvim öffne und dann a-h - das sat nicht viel aus und warum gerade der git branch? oder ist das von der session.nvim abgeleitet, nein oder?
Cool wäre ein terminal.nvim cheatsheet wenn man ein terminal offen hat, sowas wie funliteren pipes und andere keywords/temrinal/shell spezifische wichtige sachen usw... das kann man auh czum blättern machen, mit verschiedenen anbschnitten/bereichen. das muss aber immer zur shell passen, die gerade verwendet wird bzw ein abshcnitt mit allen was überall gleich ist.

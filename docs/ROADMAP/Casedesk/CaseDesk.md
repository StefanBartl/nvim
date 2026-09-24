# caaedesk todo/ideas

## `:JSON`

$REPOS_DIR/WKDBook-Tricentis/Cases/SAP_Support/Cases/Open/1201484/assets/third/ShortenedLog.txt -> `:JSON pretty` ->

  ```vim
    Error  10:28:20 AM notify.error [data] JSON decode failed: invalid JSON: Expected the end but found T_OBJ_BEGIN at character 285
  ```

---

## MISC

- Im chrome browser ein kleines window irgendow schaffen dass mean weg und her togglen kann, indem mann notizen absoechern kann, die aber mnicht ins netzt gechickt werden, sondern rei lokal sind - wie die hrome exteension `Notes Online`, die das wunderbr macht auch von derui her, aber ich will das selbst schreiben damit ichmir ganz sicherbin, dass keine daten irgendow hin gehen. Aber man kann es als vorlage / template verwenden
- Alle files checken darauf, dass Tosca Keyword wie `ExecutionList` oder `ExecutionList`-Folder oder `TestCase` normiert formatiert sind, also die keywords alle zusammen, anfangsbuchtaben groß + in `` und zusammen ohne leerzeichen, wenn -Folder dann eben genau so sheriben und nicht ExecutionList Folder; usw... und auch sicherstellen, das intexterzeugung von ao / heurtik in casedesk dies auch soeingehalten wird.


## WKDBook-Tricentis

- Filename-Hygine (beginn mit großbuchtsbaen, dann aif art camelCase)

## noch nicht gut beschrieben

- `:Case open` öffnet nur den filetreee, aber der casse folder ist nicht selektiert, ich wüde gerne haben, dass das Summary geöffnet wird wenn man case open ausfüphrt. Sollte aus irgeneienen grund das summary nicht im folder sein, einfach die nöchste file
- `:Case attachments` soll eine option `find` erfhalten, die alle attahcments ineinen pociker zeigt sowie `nsert oder attach oder s.ä.` um wieder den file explorer in Downoads ordner zu öffnen und files auszuwählen die dann direkt reingeladen werden

- solange ich azf der worksation bin soll ui.nvim marks folgende ofade führen und aucah in dieser ordnung:
  1. $REPOS_DIR/WKDBook-Tricentis/ToDo-Collection/SAP_Support_ToDo.md
  2. $REPOS_DIR/WKDBook-Tricentis\Workflow\CDX\StartChat.md
  3. $REPOS_DIR/WKDBook-Tricentis/Workflow/Templates/SummaryTemplate.md
  4. $REPOS_DIR/WKDBook-Tricentis/Cases/DRAFT-Solution.md
  5. $REPOS_DIR/WKDBook-Tricentis/Notes/Credentials.md
  6. $REPOS_DIR/WKDBook-Tricentis/Notes/Links.md
  7. C:/Users/StefanBartl/AppData/Local/nvim/docs/ROADMAP/ROADMAP.md
  8. C:/Users/StefanBartl/AppData/Local/nvim/docs/ROADMAP/Casedesk/Casedesk.md

- eine möglihkeit, beim ertellen eines cases, aber nch nachher, `Tags` zu vergeben, also zb in $REPOS_DIR/WKDBook-Tricentis/Cases/SAP_Support/Cases/Solved/888622/Notes.md ist klar, dss das ein Mobile Engine case ist. das wäre super, weil wir dnan später zb `:Cases MobileEngine` oder `:Cases TTA` usw.. eine lsite `pickers.nvim` ausgeben könnten. Beim erstelen eines cases soll das gleich abgefragt werden, aebr wenn möglcih und sinnvoll auvhch glidhc vorschläge, zb aus dem titel ode activity stream ableiten. ich köntn mir vorstellen, dass hier ein kleirner buffer audgehtm in der man die tags eintragt (können auch herer sein), zb jede zeile einer bzw auvh , oder - als trennzeichne erlauben. eventuell eie eigen file für diese tags im casde angeben, oder woander unterbfingen, zb in Notes.md


---

## casedesk

- problems / solutions matrix us den cases erstellen
- casedesk file im wkdbook implementieren
- keuzfeatures data.nvim
- Research/NN_ActivityStream.md sgleich anlegen und bei :Case new auc gleich abfragen, ob der activiyf stream hineinposten will - dazu braucht es aber mehr als nur einen einzeiler prompt, also zuerst abfragen ob as angehöngt werden soll wenn ja, dann sollte sich ein float window öffnen, in der ich den hineinposten kann, dann specihern und schlie0en -> weiter frage, ob gleich ananomisiert werden soll, wennja, dann geocih de acivity stream ananonmyiseren und so abspeichern (den normalen unter einer level 2 amrkdown headline und darüber der annanomiserungsversuch )
  - warum dinenen wir die datei Research/NN_ActivityStream.md und nicht Research/ActivityStream.md?
  - :Case anonymize . (oder case number) ->   Warn  10:17:30 AM notify.warn [usrcmds.case] 1195796: no Activity Stream found under Research/
- docs/ auf deutsch, alles auf deustch weil sdas nur ein repo fpr mich ist, nicht fpr die öffentlichkeit^
- JQL.md: kein project key, also  `project = "TOSCA"` oder ähnliches, das bringt bei unserer suche nichts. Beispiele:

  **1. Search for 2026.1 Upgrade & UPN Login / 403 Issues:**

  ```jql
  text ~ "403 Forbidden" AND text ~ "UPN" AND text ~ "2026.1" ORDER BY created DESC
  ```

  **2. Search for Active Directory / LDAP Authentication Failures after Upgrade:**

  ```jql
  component in ("User Administration", "Authentication Service") AND text ~ "Active Directory" AND text ~ "upgrade" ORDER BY updated DESC
  ```

  **3. Search for `/tua/api/session` or Identity Server Token Errors:**

  ```jql
  text ~ "tua/api/session" AND (summary ~ "AD" OR summary ~ "LDAP" OR summary ~ "login") ORDER BY created DESC
  ```

---

## A4 — casedesk: `:Case timeline` reports git pulls as work sessions

**Source:** `.../casedesk.nvim/ROADMAP/ROADMAP.md`, section "Workflow", fourth bullet.
**Stand geprüft 2026-09-17:** open — `timeline.lua` still derives sessions
from mtimes (11 `mtime` references).

```
Aufgabe: casedesk.nvim — entscheiden, was ":Case timeline" mit
Git-Pull-Sessions macht. Das Feature liefert derzeit messbar falsche Zahlen.

Roadmap-Punkt: $REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/casedesk.nvim/
ROADMAP/ROADMAP.md, Abschnitt "Workflow", Punkt ":Case timeline reports git
pulls as work sessions". Der Punkt ist gemessen, nicht vermutet: timeline.lua
rekonstruiert Sessions rein aus Datei-mtimes unter dem Case-Ordner, aber der
Korpus ist ein mit einer zweiten Maschine synchronisierter git-Working-Tree —
und git stempelt jede Datei, die es schreibt. Die Timeline zeigt also die
Pull-Historie:

  case 1135620: 1 session   2026-09-02 20:17 → 2026-09-02 20:17   7 files
  case 988483:  2 sessions  2026-08-19 14:48 → …  /  2026-09-02 20:17 → …

Das sind exakt die git-reflog-Einträge, und jede Session kollabiert auf Dauer
null, weil ein Pull alle Dateien in derselben Sekunde schreibt.

Prüfe ZUERST, ob das noch gilt (Stand 2026-09-17: ja, mtime-basiert).

Das ist ausdrücklich eine ENTSCHEIDUNG, kein Bau-Auftrag. Die Roadmap wiegt
drei Optionen gegeneinander ab, lies sie dort im Original:
  a) Feature fallenlassen — auf einem synchronisierten Korpus nicht tragfähig
  b) behalten, aber eine Session, deren Dateien alle dieselbe Sekunde
     tragen, als "nicht messbar" labeln
  c) Dauern künftig im Usage-Journal mitschreiben und nur zeigen, was es
     abdeckt (kann die Vergangenheit nicht rekonstruieren, startet leer)

Bring mir eine Empfehlung mit Begründung, BEVOR du etwas baust.

Mitbetroffen und im selben Zug anzusehen: detect.last_touched ruht auf
denselben mtimes und verdient denselben Blick.

Repo: $REPOS_DIR/casedesk.nvim (lua/casedesk/timeline.lua, 79 Zeilen)
Regeln: Antworte auf Deutsch, Code und Kommentare auf Englisch. luacheck und
stylua grün. Docs/README mitpflegen. Kein Claude-Co-Author in Commits. Wenn
fertig: committen und direkt auf main pushen.
```

---### A4 — casedesk: `:Case timeline` reports git pulls as work sessions

**Source:** `.../casedesk.nvim/ROADMAP/ROADMAP.md`, section "Workflow", fourth bullet.
**Stand geprüft 2026-09-17:** open — `timeline.lua` still derives sessions
from mtimes (11 `mtime` references).

```
Aufgabe: casedesk.nvim — entscheiden, was ":Case timeline" mit
Git-Pull-Sessions macht. Das Feature liefert derzeit messbar falsche Zahlen.

Roadmap-Punkt: $REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/casedesk.nvim/
ROADMAP/ROADMAP.md, Abschnitt "Workflow", Punkt ":Case timeline reports git
pulls as work sessions". Der Punkt ist gemessen, nicht vermutet: timeline.lua
rekonstruiert Sessions rein aus Datei-mtimes unter dem Case-Ordner, aber der
Korpus ist ein mit einer zweiten Maschine synchronisierter git-Working-Tree —
und git stempelt jede Datei, die es schreibt. Die Timeline zeigt also die
Pull-Historie:

  case 1135620: 1 session   2026-09-02 20:17 → 2026-09-02 20:17   7 files
  case 988483:  2 sessions  2026-08-19 14:48 → …  /  2026-09-02 20:17 → …

Das sind exakt die git-reflog-Einträge, und jede Session kollabiert auf Dauer
null, weil ein Pull alle Dateien in derselben Sekunde schreibt.

Prüfe ZUERST, ob das noch gilt (Stand 2026-09-17: ja, mtime-basiert).

Das ist ausdrücklich eine ENTSCHEIDUNG, kein Bau-Auftrag. Die Roadmap wiegt
drei Optionen gegeneinander ab, lies sie dort im Original:
  a) Feature fallenlassen — auf einem synchronisierten Korpus nicht tragfähig
  b) behalten, aber eine Session, deren Dateien alle dieselbe Sekunde
     tragen, als "nicht messbar" labeln
  c) Dauern künftig im Usage-Journal mitschreiben und nur zeigen, was es
     abdeckt (kann die Vergangenheit nicht rekonstruieren, startet leer)

Bring mir eine Empfehlung mit Begründung, BEVOR du etwas baust.

Mitbetroffen und im selben Zug anzusehen: detect.last_touched ruht auf
denselben mtimes und verdient denselben Blick.

Repo: $REPOS_DIR/casedesk.nvim (lua/casedesk/timeline.lua, 79 Zeilen)
Regeln: Antworte auf Deutsch, Code und Kommentare auf Englisch. luacheck und
stylua grün. Docs/README mitpflegen. Kein Claude-Co-Author in Commits. Wenn
fertig: committen und direkt auf main pushen.
```

---

## TCSupportInfo

$REPOS_DIR/WKDBook-Tricentis\Cases\SAP_Support\Cases\Open\1201484\assets\second\ToscaSupportInfo.txt
darausa soll dann wie in $REPOS_DIR/WKDBook-Tricentis/Cases/SAP_Support/Cases/Open/1201484/Versions.md eine Versions.md (oder ao ähnlkcuh, gerne auch bessere bennenung der file) angelegt weren, in der man schnell das environment daten bekommt ohne im Supportfile scchen zu müssen.

Wenn im `:Case new` am schluus bei den attachments eine SupprtFile dabewi ist, wäre es ksuper, wenn ddas gleih autoamtisch angelegt und befüllt wird. (Support file ssind normiert und werden aus dem Tosca Commander exportiert, also immer gleich bis auf die versionsnummern.)

## Jira jgl

Ein noirmaler weg ist fpr dne case in usneree jira jql datenbank zu sucen, dort sicnd swat tickets, usw... enthalten. dafür brauche ich jqlueries, wie in $REPOS_DIR/WKDBook-Tricentis/Cases/SAP_Support/Cases/Open/1004926/Research/JQL.md

Bem erstellen des cases wäre es gut, wenn diese file in Reaseaarch folder gleich angelegt wird, und wenn möglich, auch gleich dieueries, heuristisch mlglich? oder brauchen weird dazu eine ai?

## SWAT

Einen folder, der SWAT TIckets für dne case hält, also beschreibungen - artikel usw.. diesekönnen in dieinformations-pool mit aufgebimmen werden. Beispiel: SAP 1004926

Dort werden auch opft die technischen Kernprobleme exaklt beschireben, künftige fixes erwähnt usw.,..

## Summary Template

Jeder case braucht in snow ein Summary (Workflow/Templates/SummaryTemplate.md) - da dies sowieso erstellt werden muss, kann das template auch gelich in :Case new gleich mit angelegt werden als eleeres tempalte. Eventuelle kann das auch für andere Zwecke als Info verwendet werden

## Workflow links

$REPOS_DIR/WKDBook-Tricentis\Workflow\CDX\CDX_Ressourcen apiegelt docs aus $REPOS_DIR/WKDBook-Tricentis\Workflow - aber wenn ich in einen der files was ändere, müsste ich das in der korrespondoierenden ebefnalls machen - klassische fehlerwuelle. also mit links arbeiten, da wir in windows snd, mit verknüpfungen. Richte diese bitte ein.

## ai

- [ ] Anonymsierungs-Feature: Activity Streams anaonymiseren, sodass ich sie dann in eine ai prompt posten kann, ohne dass daten von kunden / tricentis weiteregegeben werden, die nicht nötiog sind (Namen, Kontaktdaten. Company, usw...)

- [ ] jeglich ai ausführeungen müssen immer explizizt bestötigt werdne, auch wenn man da mitusrcmd angibt da klar ist dass das ai ist, aber trpotzdm frGEN : SINN IST; DAS ich ncht an ai daten schick die dort gar nicht sein sollten. erstmal sollte das default sein, soll aber in der installations spec als config key toggled werden können

## MISC

- [ ] tosca commander propertie s: ControlFramwwork (oeder so) wenn SAP UI5 satt none steht: ui5.sap.com
- [ ] Wenn ein cases mal closed/solved ist, muss e strotzdem eine Möglichkeit geben, inhn wieder con dort nach open zu schieben, ohne dass ich das manuell mit copy past emache, also mit fdem usrrcmd :Case sollte das auch funktioneren
- [ ] Eine neue File kategorie einführen "Task.md" oder so: in der sollen wir festhalten, was der kunde genau erreichen will/ machen will, was das ziel des tickets ist. das ist so wichtig, dass ich dneke, es macht sinn, dies expizit festzuhalten. als ort würde ich vorschlagen: {CASE NUMBER}/TASK.md - auch fethalten wenn sinnvoll was er NIHCT will

## Solution/

- [ ] Solutions.md -> durchgehend erstellen

- [ ] Es ist nicht nötig einen eigenen /Solutions/ folder u erstellen, einfach im cae root "DRAFT-Solution.md" bzw `Solution.md` genügt. Das muss in den Richrlinine ersetzt werden (glaube in engine lab im WKDBook-Tricentis)

- [ ] DRAFT-Solution.md -> aus dessen files mus noch das formattierte dolutzion file hezogen werden.nn ich nicht sicher sein, dass dass de korrekte Soluton war, könnte aber sein....
  eitpunkt des clsing, auf die der customer nicht mehr geantwortet hat / den case geschlossen hat. Daher kann man daraus nicht ableiten, dass das die solutions war, es klönnte sein, aber wir haenm keine bestätigung. tzrotzdem kan man damit vl etwas machen... also für kpnftgie solutions suche verwednen, halt mit demhinweiß, dass eine solution die saus einer DRAFT-Solution.md kommt nicht korrekt sien könnte

- [ ] Wenn man `:Case close XY` eingibt, und dan close oder anderes snnvolles auswählt, soll man danahc gefragt werden, ob man gleicheine Solution.nmnd anlegen möchte, wenn ja dann anlegen und gleich aufmachen, damit die solutin hineinkopiert werden kann. AUßerdem eine weitere option "Customer didnt respond" oder so,---
  - [ ] Dieser "Workflow" ist natürlich, wird fast immer so sein das man sdann solutuions anhängt. Anlaysieren wir auch andreee usrcmd options, ob da ähnlichjes optimneret weren kann

- [ ] Ich habe einige nach Solved/ schieben können, mit dem usrcmds :Case solved XY - wie kommten diese solutions daraus nun nach $REPOS_DIR/WKDBook-Tricentis\Cases\Solutions?

- [ ] wenn wir kemananden zu PAC rpouten, dann soll das eine info sein, die interesant iost, dnen man soll dann auf einmal eine liste ziehen können mit beipelen, die zu PÜAC routet wurde. selbiges für License, Education department bzw PSO (Proffesional Service), momentan bennen ich die solutions file dann so Solution_PAC.md opder Solution_PSO.md usw... und im doc dann unter:

```markdown
## Status

PAC
```

Hier brauchen wir eine einheitliches system.

  - [ ] Was da auch noch mitbedacht weren soll: ich hab für Tier 2 - Support Engineering - auch einen neuen folder erstellt: $REPOS_DIR/WKDBook-Tricentis\Cases\SAP_Support\Cases\T2\996010 - hier kommen cases hin, die schon eine läöngere zeit in T2 liegen, nicht closed sind, aber es unwahrscheinlich ist, dass ich selbst noch etwas beitragen kann und eigentlich nicht mehr watche.

## solved cases

- [ ] Gemeni soll reports mit keymaps usw.. schreiben. TEMPLATE ausarboeten (weiß nicht mehr genau was ich damit meinte. akannst du das aus dem kontext herleiten?

## reports/log

- [ ] Analysieren, darauf, dass ki oder auch heuristik aus den files infos herausziehen kann
  Beispiele für von tosca erzeugte files:
    DEX\_GPO\_RESULT: "C:\\repos\\WKDBook-Tricentis\\Cases\\SAP\_Support\\Cases\\Open\\948965\\assets\\3\\DEX\_GPO\_Report.html"
    gpresult: "C:\\repos\\WKDBook-Tricentis\\Cases\\SAP\_Support\\Cases\\Open\\948965\\assets\\3\\gpresult.html"

---

- wenn zb in jql file gesucht wird fpr summaryies / ai uw.. aber auch in leeren sokutiosn usw.. das template text der nicht updatet wurde, dersolte bei solvhen infomration gatherings immer überbsrpungen weren, auch wenn sie 10 mal enthalten sind als files... zb in JQL.md:

    ```markdown
    # 1245018 - `Concurrent users execution in Tosca` - JQL

    Wenn du im internen Tricentis-/Partner-Jira oder Support-Portal nach
    ähnlichen Fällen, Tickets und Best Practices suchen möchtest, helfen
    JQL-Queries wie die folgenden. Der Case-Titel allein ist selten der beste
    Suchbegriff — echte Fehlermeldungen und Fachbegriffe aus `Summary.md`/
    `Research/` liefern bessere Treffer, sobald die bekannt sind.

    **Nach `<Fehlermeldung>` suchen:**

    ```jql
    text ~ "<Fehlermeldung>" ORDER BY created DESC

    ```

    **Nach `<Fachbegriff A>` & `<Fachbegriff B>` kombiniert suchen:**

    ```jql
    text ~ "<Fachbegriff A>" AND text ~ "<Fachbegriff B>" ORDER BY updated DESC

    ```

    **Nach Komponente + Zeitraum eingrenzen:**

    ```jql
    text ~ "<Fachbegriff>" AND created >= -90d ORDER BY created DESC

    ```


    Das ist reiner temoakte text
    ```

---

# caaedesk todo/ideas

## TCSupportInfo

C:\repos\WKDBook-Tricentis\Cases\SAP_Support\Cases\Open\1201484\assets\second\ToscaSupportInfo.txt
darausa soll dann wie in C:/repos/WKDBook-Tricentis/Cases/SAP_Support/Cases/Open/1201484/Versions.md eine Versions.md (oder ao ähnlkcuh, gerne auch bessere bennenung der file) angelegt weren, in der man schnell das environment daten bekommt ohne im Supportfile scchen zu müssen.

Wenn im `:Case new` am schluus bei den attachments eine SupprtFile dabewi ist, wäre es ksuper, wenn ddas gleih autoamtisch angelegt und befüllt wird. (Support file ssind normiert und werden aus dem Tosca Commander exportiert, also immer gleich bis auf die versionsnummern.)

## Jira jgl

Ein noirmaler weg ist fpr dne case in usneree jira jql datenbank zu sucen, dort sicnd swat tickets, usw... enthalten. dafür brauche ich jqlueries, wie in C:/repos/WKDBook-Tricentis/Cases/SAP_Support/Cases/Open/1004926/Research/JQL.md

Bem erstellen des cases wäre es gut, wenn diese file in Reaseaarch folder gleich angelegt wird, und wenn möglich, auch gleich dieueries, heuristisch mlglich? oder brauchen weird dazu eine ai?

## SWAT

Einen folder, der SWAT TIckets für dne case hält, also beschreibungen - artikel usw.. diesekönnen in dieinformations-pool mit aufgebimmen werden. Beispiel: SAP 1004926

Dort werden auch opft die technischen Kernprobleme exaklt beschireben, künftige fixes erwähnt usw.,..

## Summary Template

Jeder case braucht in snow ein Summary (Workflow/Templates/SummaryTemplate.md) - da dies sowieso erstellt werden muss, kann das template auch gelich in :Case new gleich mit angelegt werden als eleeres tempalte. Eventuelle kann das auch für andere Zwecke als Info verwendet werden

## Workflow links

C:\repos\WKDBook-Tricentis\Workflow\CDX\CDX_Ressourcen apiegelt docs aus C:\repos\WKDBook-Tricentis\Workflow - aber wenn ich in einen der files was ändere, müsste ich das in der korrespondoierenden ebefnalls machen - klassische fehlerwuelle. also mit links arbeiten, da wir in windows snd, mit verknüpfungen. Richte diese bitte ein.

## ai

- [ ] Anonymsierungs-Feature: Activity Streams anaonymiseren, sodass ich sie dann in eine ai prompt posten kann, ohne dass daten von kunden / tricentis weiteregegeben werden, die nicht nötiog sind (Namen, Kontaktdaten. Company, usw...)

## MISC

- [ ] tosca commander propertie s: ControlFramwwork (oeder so) wenn SAP UI5 satt none steht: ui5.sap.com
- [ ] Wenn ein cases mal closed/solved ist, muss e strotzdem eine Möglichkeit geben, inhn wieder con dort nach open zu schieben, ohne dass ich das manuell mit copy past emache, also mit fdem usrrcmd :Case sollte das auch funktioneren
- [ ] Eine neue File kategorie einführen "Task.md" oder so: in der sollen wir festhalten, was der kunde genau erreichen will/ machen will, was das ziel des tickets ist. das ist so wichtig, dass ich dneke, es macht sinn, dies expizit festzuhalten. als ort würde ich vorschlagen: {CASE NUMBER}/TASK.md - auch fethalten wenn sinnvoll was er NIHCT will


## Solution/



- [ ] DRAFT-Solution.md -> aus dessen files mus noch das formattierte dolutzion file hezogen werden.nn ich nicht sicher sein, dass dass de korrekte Soluton war, könnte aber sein....
  eitpunkt des clsing, auf die der customer nicht mehr geantwortet hat / den case geschlossen hat. Daher kann man daraus nicht ableiten, dass das die solutions war, es klönnte sein, aber wir haenm keine bestätigung. tzrotzdem kan man damit vl etwas machen... also für kpnftgie solutions suche verwednen, halt mit demhinweiß, dass eine solution die saus einer DRAFT-Solution.md kommt nicht korrekt sien könnte

- [ ] Wenn man `:Case close XY` eingibt, und dan close oder anderes snnvolles auswählt, soll man danahc gefragt werden, ob man gleicheine Solution.nmnd anlegen möchte, wenn ja dann anlegen und gleich aufmachen, damit die solutin hineinkopiert werden kann. AUßerdem eine weitere option "Customer didnt respond" oder so,---
  - [ ] Dieser "Workflow" ist natürlich, wird fast immer so sein das man sdann solutuions anhängt. Anlaysieren wir auch andreee usrcmd options, ob da ähnlichjes optimneret weren kann

- [ ] Ich habe einige nach Solved/ schieben können, mit dem usrcmds :Case solved XY - wie kommten diese solutions daraus nun nach C:\repos\WKDBook-Tricentis\Cases\Solutions?

- [ ] wenn wir kemananden zu PAC rpouten, dann soll das eine info sein, die interesant iost, dnen man soll dann auf einmal eine liste ziehen können mit beipelen, die zu PÜAC routet wurde. selbiges für License, Education department bzw PSO (Proffesional Service), momentan bennen ich die solutions file dann so Solution_PAC.md opder Solution_PSO.md usw... und im doc dann unter:

```markdown
## Status

PAC
```

Hier brauchen wir eine einheitliches system.

  - [ ] Was da auch noch mitbedacht weren soll: ich hab für Tier 2 - Support Engineering - auch einen neuen folder erstellt: C:\repos\WKDBook-Tricentis\Cases\SAP_Support\Cases\T2\996010 - hier kommen cases hin, die schon eine läöngere zeit in T2 liegen, nicht closed sind, aber es unwahrscheinlich ist, dass ich selbst noch etwas beitragen kann und eigentlich nicht mehr watche.

## solved cases

- [ ] Gemejni soll reposrts mit keywpors usw.. schreiben. TEMPLATE ausarboeten

## reports/log

- [ ] Analysieren, darauf, dass ki oder auch heuristik aus den files infos herausziehen kann
  Beispiele für von tosca erzeugte files:
    DEX\_GPO\_RESULT: "C:\\repos\\WKDBook-Tricentis\\Cases\\SAP\_Support\\Cases\\Open\\948965\\assets\\3\\DEX\_GPO\_Report.html"
    gpresult: "C:\\repos\\WKDBook-Tricentis\\Cases\\SAP\_Support\\Cases\\Open\\948965\\assets\\3\\gpresult.html"

---


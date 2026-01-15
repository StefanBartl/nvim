Ich habe einige refacotirng mit meiner neotree config in nvim durchgeführt, ich habe nun folgendes Problem mit den neotree window opener mappings, implemeniter in config/neotree/open/

1. Jedes Mapping führt immer "Open window left " aus, egal ob ich M-l, M-c (sollte neotree in einem buffer ausgeben) oder M-f (sollte neotree in einem floating buffer ausgeben.
2. Manchmal öffnet sich beim schließen eines neotree windows es sofort wieder. eventuell eine race kondition beim opener toggle (öffnen oder schließen)
3. config/neotree/open/window/controller.lua: Busy guard: ich habe diesen ausgetestet und er funktioniert nur Teils; er sperrt zwar bei oftmaligen raschen wiederholen von openings, aber beleibt dann für immer gesperrt, es gibt also kein  aufmachen mehr. Der Mechanismus sollte so implementiert werden, dass sich diese mechanik von selbst löst, also beispiel würde ich zwei einhalb wege vorschlagen: Weg 1 würde bei ausführung eines openings einen sperrschalter setzen welcher neue openings early returned und so aussperrt,  und als letzt aktion, also nach dem eigentlichen öfnnen des windows,  einen debounce timer starten, zb.: 30ms (konfigurierbar). Wenn ideser abgelaufen ist, wird der schalter wieder deaktiviert und neue opening mappings knnen wieder "durch"., Weg zwei wäre mit einer timestamp, die als letzte aktion im opening virgang eine timestamp entweder in eine filelokale vatiable schreibt und dann bei jeden neueerlichen opening gechelkt werden muss, oder globaler bzw in eine state variable, und noch in der mappings definition der M-* opening  appings wird die state geprüft ob die eit abgelaufen ist, ansonsnten early return.  Kannst du einen weg wählen oder einen bessereen und implementieren?"

Beachte dabei die ausgearbeiteten Regeln & Leitlinien zu den Themem
- Architektur
- Clean Code
- Sicherheit
- Performance
- uvm...
welche in den Dateien Arch&Coding-Regeln.md & Checklist.md & Zentrale-Prinzipien.md festgehalten sind und in den in den Projektdateien anhängig sind.

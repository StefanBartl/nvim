1. Operator + Textobjekt (präzise und schnell)
    * ciw → „change inner word“: ändert nur smte, das Komma bleibt stehen.
    * caw → „change a word“: wie oben, nimmt zusätzlich ein evtl. folgendes Leerzeichen mit (nützlich, um doppelte Spaces zu vermeiden).

2. Visual + Textobjekt (explizit markieren)
    * viw gefolgt von c → markiert nur das Wort, kein Komma.
    * vaw gefolgt von c → wie oben, plus nachfolgendes Leerzeichen.

3. Bewegung bis zum Trennzeichen (wenn das nächste Zeichen bekannt ist)
    * ct, → „change till ,“: ändert bis vor das Komma, Komma bleibt erhalten.
    * dt, / yt, → analog für delete/yank ohne das Komma.

1. Alternative Bewegung statt w in Visual
    * ve statt vw → „bis Wortende“ statt „zum nächsten Wortanfang“; so wird das Komma nicht mit ausgewählt.
    * vE → bis Wortende (großes E = WORD, inkl. Bindestriche etc. als ein Block).

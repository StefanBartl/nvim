
- Terminiologie beabreiten (noch aufteilen usw.);
- Referenzen in den dokumenten zu anderen doumentne implementieren, damit sich alles aufeinenader bezieht usw...
  - Auffällige fehllende themen gleich notieren und sammeln, eventuell schreiben wir die neu. Also wenn in einen dok sich auf etwas beieht wsa wir noch nicht erkläte haben, dann notieren. Übrigens kanne sauh sein, dass thematiken in "docs versteckt" sind, also der file name ein ganz anderees tema hat, abe riene abscnitt im dokment dann etwas anderes beschreibt, meistens einverewadntes thema. wenn sinnvoll, dann diese abschnitt als eigen file anlegen und im doc entfernen, aber da sneue doc referenzieren

- $REPOS_DIR/WKDBook-Tricentis/Workflow korrekturlesen / besser anordnen

- Wenn man texte aus aichats ü+bernimmt hat man oft formatierungen drinnen wie:
  1. `$$\text{UPN} = \text{ValuePrefix} + \text{"@"} + \text{ValueSuffix}$$` -> mit was rsetzten oder einfach entfenren?
  2. `5S/$r\rightarrow$//g` bzw `"$\rightarrow$"` -> sollte eigentlich `->` sein
Das ist total mühsam und deshalb möchte ich:
  - sicherstellen, das alle texte die durch casedesk heuristik oder ai hände gegangen ist, diese replaced
  - Es ein usrcmd gibt, mit dem man `cfile`/`cwd`/`path`/`aktueller buffer`/usw.. angeben kann und dort wird es replaced
  - was diebsezüglich noch sinn macht.
Beide Beispiele sind mir aufgefallen nd wahrschienlich deshalb auch die häufigsten, aber vl gibt es weitere die mna beachten sollte

-> Open cases on workspace checken, ob sie noch open sind, oder nach closed schieben kann

# neotree- Roadmap & Ideas

## Table of content

- [neotree- Roadmap & Ideas](#neotree-roadmap-ideas)
  - [Critical](#critical)
  - [Important](#important)
  - [normal](#normal)
    - [open (m-f, m-l usw..)](#open-m-f-m-l-usw)
    - [marks / trash](#marks-trash)

---

## Critical

1. Failes to copy folder oder file list, mit [f ]f [F ]F warum ?

--

## Important

1. Neotree window muss schneller öffnen können, das dauert zu langsam nd wirkt nicht mehr flüssig:
  - sources einzeln mal deaktivieren, sources messen wir lange der unterschied ist wenn an einzeln wegnimmt
  - --> Im window alles sources deaktivieren bis auf filesyte, dann einen source selector mit zb.: "M-s" machen
2. Windows: wenn man eine window ofen hat und hdann ein anderes äöfffnet, macht es mommmentan erstmal das sandre zu dann muss man nochmalöffnen. alsi sagen wir win links ist offne, ich drücke M-f dann macht es erstmal win left zu. jetzt muss ich nochmal M-f drücken um das float win zu bekommen.

---

## normal

1. trash.init.lua M.config über die config.neotree.config.setup() konfigurierbar machen. (types implementieren)
 doppelt confirmation beim löschen:
    beim ersten mal:
    Move to trash "filename"?
    un und dann :
    delete: "absolute  path"

---

### open (m-f, m-l usw..)

1. ein state, der sich merkt, welche nodes gerade geöffnet waren
2. damit könnte neotree "sich merken" wo man gerade iim neotre war, neotree schließen und wieder öffnen u nd man wäre wieder dort
3. dazu bräuchte es ein "reveal" keymap, die dann wieder zur node der aktuellen file revealed und das
4. windows mit escape schließbfar machen, aber logischerweioße muss aktionen abbrehcen trotzdem klappen.

---

### marks / trash

--

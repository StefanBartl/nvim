# `gopath.nvim`


## erledigt

1. Pfade wie:
  `...a/Local/nvim/lua/config/neotree/open/filemanager/win.lua:62: attempt to call upvalue 'cb' (a table value)`
  werden zwar korrekt geöffnet (wie cool ist das denn!), aber nvim freezed ein und hat bei mir als Beipiel ca 5s benötigt bis der Buffer mit der File geöffnet wurde. Ich gehe davon aus, dass dies aufgrund der files suche im gesamten System ist... Es wäre aber super, wen wir dass entweder...
    -  asynchron machen könnten und bei Beginn eine `nvim more` Message ausgegeben wird in Richtung `Dateisuche im Gang....` und wenn gefunden wird, dann äöffnet es sich eh, wenn icht, dann wird eh die fail message ausgegeb.
    - bleibt synchron, aber dann mit einen Popup Fenster, dass dem user sagt "Nicht nvim hart beenden oder so, Dateisuche im Gang..."
2. gopath auf main stellen, alle anderen auch

--

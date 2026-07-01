## `pdfport.nvim`

1. ist es möglich die neotree integrierung von pdfport innerhalb pdfports zu belassen und filetreesxplorer agnostisch machen? Oder: `filetree.nvim` -> und dort `pdfport.nvim` als dependency? ZUiel soll sein, dass wir einen logisch connex schaffen...:

  - Ich könnte mir vorstellen, das das feature in `pdfport.nvim` grundsätzlich implementiert ist, und wir in `filetree.nvim` dann `pdfport.nvim` als optionales dependency nutzen, also adapter für die filetrees (neotree, nvimtree, usw...) schreiben. Wenn das feature dann aktiv ist, dann wird das eingehöngt.
  -  ich denke nur, das an pdfport selbst viele dependencys hüängen, je nachdem, was man nutzen will, sogreai ai als übersetzet der podfs ist öglichl..
  - vielleicht wöäre es am besten, dass ses defautl zwar aktiv ist, aber nur mit nvim hauseigen tools verwendet wird, wenn man dann als user einzelne oder alle toll.s aktivieren kann. in `pdfport` gibt es ja: `fallback_chain  = { "pdftotext", "pdfplumber", "marker", "docling", "ollama", "claude" },`, da kann man denke ich nciht davonba usgehen, das jeder user der `filetree.nvim` verwenden will, auch alles idese tools isntallieren will. Da e aber eh mit fallback chain funkltniert, das kommt usn entgegendenkle ich!


Momnentan habe ich ja fpr neuotree, neben des pdfport.nvim plugins noch folgenden : `C:\Users\bartl\AppData\Local\nvim\lua\config\neotree\keymaps\filesystem\pdfport.lua`

---

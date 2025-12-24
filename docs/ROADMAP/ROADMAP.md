# WKD Neovim Roadmap

## MIXED

- Neotree mappings so schreiben, dass auch nvimtree/netrw möglich wäre
    . DAs bedeutet auch, dass alle lib funktionen inerhalb der filtree filesystem ist, danmit keine dependencies entstehen
I    . Die meisten helper sollten eigenltich als commands implementiert werden
 `custom.functions` verwenden, um funktionen, die sowohl mappings als auch usercommands begründen.
 lsp.tools behandeln
 [nvim install doc](./NVIM-Install Doc/install_notes.md) fertig aufteilen

## ideas

- lua annotationen auskommentieren geht nicht, weil --- zu - gemacht wird
- :messages aktualisert sich nicht, wenn man neue einträge reinbekomt
- Picker, der zuerst alle wkdbooks auflistet zum auswählen, dann die files oder greps picked. Ähnlicjh wie `custom/repopickers`

## Long run

1. workspace lsp warnings debuggen
    1. alle `disable-next-line` durchsehen
    2. Todo Coments anschauen und durchgehen
2. probieren nvchad rauszunehmen und nochmal mit lazyvim
3. experimental options:
   1. statusline und winbar breadcrumbs sollten sich ein modul teilen

--


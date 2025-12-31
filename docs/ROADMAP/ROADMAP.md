# WKD Neovim Roadmap

## Watch

- `<C-s>`: Manchmal springt es beim speichern in etwa in die Mitte oder ans Ende oder einen anderen Punk der file

## MIXED

- hover select tab selection multi select
- lsp.tools.lsp_signature_tool -> /doc/lsp_signature_tool.txt erstellebn
- mynotes in custom schieben
- Neotree mappings so schreiben, dass auch nvimtree/netrw möglich wäre
    . DAs bedeutet auch, dass alle lib funktionen inerhalb der filtree filesystem ist, danmit keine dependencies entstehen
I    . Die meisten helper sollten eigenltich als commands implementiert werden
 `custom.functions` verwenden, um funktionen, die sowohl mappings als auch usercommands begründen.
 lsp.tools behandeln
 [nvim install doc](./NVIM-Install Doc/install_notes.md) fertig aufteilen

- lua\usrcmds\mymessages\init.lua zu dbg_messges verenheitlichen

## ideas

## Long run

1. workspace lsp warnings debuggen
    1. alle `disable-next-line` durchsehen
    2. Todo Coments anschauen und durchgehen
2. probieren nvchad rauszunehmen und nochmal mit lazyvim
3. experimental options:
   1. statusline und winbar breadcrumbs sollten sich ein modul teilen

--


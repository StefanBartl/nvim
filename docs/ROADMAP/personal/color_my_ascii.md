# `color_my_ascii.nvim`

Folgendes feature ist ein Zusammenspiel aus `color_mny_ascii` und `markdown.nvim`

- [ ] In markdown fenced blocks, also \`\`\`markdown oder \`\`\`ascii-markdown bzw  \`\`\`md oder \`\`\`ascii-md oder \`\`\`mdx, soll der markdown text innerhalb des fenced blocks als eigenes markdown doument gewertet werden. Der Grund ist folgender:

Nehmen wir an, wie haben eine level 2 headline:

## Some Headline

darin haben wir nuun weinen markdown fenced block und darin headlines:

```markdown
# Start

## Zweite headline

Hier ist text

### Hier eine Level 3 Headline

Hier wieder Text

## Hier wieder Level 2

usw...
```

Innerthalb des fenced blocks soll also alles was markdown betrifft ein eigener scope sein:
  - [ ] Für `markdown.nvim`:
    - [ ]  Wen innerhalöb dieses blcks `leader toc` ausgefphrt wird, dann wird innerhalbn des fenced blocks der toc erstellt, nicht außerhalb
    - [ ] Wenn `leader toc` außerhalb des fenced bloc ausgeführt wird, dann wird der toc aucvh außerhalb erstellt
    - [ ] Weitere keympas bzw usrcmds wie zb `C-p` / `C-f` soll innerhalb der fenced bock headlines funmkltienren und sich darauf bezehen, also `2leader C-f` soll zum nächsten ölevel 2 heading innerhalb des fenced nblcos springen, `4leader C-p` zum vorihgen level 4 heafding innerhalb des fenced dblocks
    - [ ] usw... das soll auf alle keymaps und usrcmds usw.. sich beziehen!
    - [ ] Dieses feature, also dass der fenced block als extriges scope behandlet wird, soll der user als feature aktivieren und deatlivieren knnen. default soll es an sein.
    - [ ] Wenn dafür in `markdown.nvim` es notwenidg ist, `color_my_ascii` als dependency zu impemeniteren, kein problem und soll geladen werden, wenn diese feature aktiviert ist. Dewmenstpechend. Kann architektonsich in `color_my_ascii` etwas asls api angeboten wierden, dass dann andere plugins konsumiren, um innerhalb von fencerd blöcken ein feature einzubringen``
    - [ ] Überlegen, ob dies für andre sprachen außerhalb vonb amrkdown sauch interessant sein könnte...
    - [ ] ZUsatz fewature fpür markldown.nvim: Die Zeile, in dwelcher der fenced block steht, soll highlited werden, also die ganze zeile dan, als abgenzung sozudagen. Sowhl der beginn als auch der schlusmarker des fenced block, also:

```javascript    <--- Diese Zeile
//...
//...
//...
```               <--- Diese Zeile

Der user soll in der isntallations spec angeben können: Will er das feature überhaupt? Er soll zwischen 3-4 presets wählen können, also zb HL in dieser und Jender farbe usw... Auch eine mglichkeit, auf diese beiden m,öglichkeiten spezhielle formatierungs strings durhzureichen, die dann darauf angewenet werden, wenn das sinnvoll ist


---


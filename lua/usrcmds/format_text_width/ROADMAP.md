# FIX:

1. Limitationen: Hyphenation (geteilt mit -) und komplexe Worttrennungsregeln sind nicht implementiert. Listen- und Bullet-Erkennung ist eine einfache Heuristik: einfache Bullet-Marker wie - , * , + oder 1. werden auf der ersten Zeile beibehalten; Fortsetzungen werden passend eingerückt.

2. Erweiterungen, die man später leicht hinzufügen kann:


3. Bessere List- und Codeblock-Erkennung (z. B. Markdown-Codeblöcke ausschließen).

4. Hyphenation mittels externem Dienst oder Wörterbuch.

5. ? Buffer-locales Autowrap beim Tippen (z. B. über autocmd BufEnter,BufWinEnter + formatoptions oder textwidth während Insert).

SUPER: Verbinden mit marksman format + der Idee, dass man in codeblöcken lsp callt

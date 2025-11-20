# FIX:

Limitationen: Hyphenation (geteilt mit -) und komplexe Worttrennungsregeln sind nicht implementiert. Listen- und Bullet-Erkennung ist eine einfache Heuristik: einfache Bullet-Marker wie - , * , + oder 1. werden auf der ersten Zeile beibehalten; Fortsetzungen werden passend eingerückt.

Erweiterungen, die man später leicht hinzufügen kann:

Buffer-locales Autowrap beim Tippen (z. B. über autocmd BufEnter,BufWinEnter + formatoptions oder textwidth während Insert).

Bessere List- und Codeblock-Erkennung (z. B. Markdown-Codeblöcke ausschließen).

Hyphenation mittels externem Dienst oder Wörterbuch.


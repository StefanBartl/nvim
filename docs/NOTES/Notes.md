:Replace "\$NVIM_CONFIG\>" "$NVIM_CONFIG_DIR" cwd --regex

---

In Neovim/Vim kannst du mit einer Regex-Alternation (\|) nach mehreren Mustern gleichzeitig suchen und highlighten.

Für deine beiden Strings:
/\VUser could not be associated with any of the existing connections.\|Your credentials could not be authenticated!



cite:
:%s/\[cite: \d\+\]//g

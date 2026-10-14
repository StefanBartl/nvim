# bindings.usrcmds.execute

`:Execute` runs the text you point at: a note that says `` `:set wrap` ``, a `git status` block in a README,
a line of Lua. It works out what the text is (Ex, Lua or shell), and either types it into the command line,
runs it, or copies it.

```
:Execute[!] [how] [--from=<where>] [--as=<kind>] [--yes]
```

Keys: `<leader>x` is `:Execute`, `<leader>X` is `:Execute!` (Normal and Visual mode).

## Which text (`--from`)

| Value | Text |
| --- | --- |
| `auto` (default) | the selection / range, else the `` `inline code` `` span under the cursor, else the fenced block the cursor is in, else the line |
| `selection` | the Visual selection or the given range (`:'<,'>Execute`) |
| `backtick` | the `` `inline code` `` span under the cursor (``` ``a`b`` ``` works) |
| `fence` | the body of the ``` or ~~~ block the cursor is in |
| `line` | the current line (or the lines of the range) |
| `clipboard` | the text in the `+` register |

## Which kind (`--as`)

`auto` (default) reads the language of a fence (`bash`, `sh`, `zsh`, `pwsh`, `powershell`, `cmd`, ... are shell,
`lua` is Lua, `vim` is Ex) or the first character of the text: `!cmd` and `$ cmd` are shell, `:cmd` is Ex, the
rest is Ex. `ex`, `lua` and `shell` pin the kind.

- **Ex**: one command per line. Blank lines and `"` comments are dropped; a line starting with `\` continues the one before.
- **Lua**: tried as an expression first (`vim.o.shiftwidth` shows its value), then as statements. `print` output and a
  returned value are shown.
- **Shell**: one command per line, run through `'shell'` like `:!` does. `#` comments are dropped; a trailing ` \` continues.
  Several lines run one after the other and stop at the first non-zero exit.

## What happens (`how`)

| Value | Effect |
| --- | --- |
| `cmdline` (default) | typed into the command line, not run: edit it, press `<CR>` |
| `run` (default with `!`) | run it, show the output as a message |
| `split`, `vsplit`, `tab` | run it, show the output in a scratch buffer |
| `float` | run it, show the output in a floating window |
| `clipboard` | copy the command text to the `+` register, do not run it |
| `result` | run it, copy the output to the `+` register |

`cmdline` takes one command: several lines or a multi-line Lua chunk do not fit the command line, use `!`.

## Safety

`:Execute` (no bang) shows the command in the command line first, so nothing runs that you did not see.
When it runs (`!` or an explicit `how`), a plan that leaves the editor asks `[R]un / [C]ancel`:

- every shell command
- an Ex command that hands text to the shell: `:!cmd`, `:r !cmd`, `:w !cmd`, `:%!filter`, `:'a,'b!filter`, `:terminal`,
  `:make`, `:grep`, `:shell`; also behind a bar (`set wrap | !ls`), a modifier (`silent !ls`, `vertical terminal`) or a
  repeater (`bufdo !ls`, `g/x/!ls`); and `:execute`/`:call`/`:lua`/`:py3` text that names `!`, `system` or a Lua shell call
- Lua that names `os.execute`, `io.popen`, `vim.system`, `vim.fn.system`, `vim.fn.jobstart`, ...

`--yes` skips the question. These checks are heuristics, not a sandbox: they err towards asking, and a plain
`:normal` or `:call Foo()` that starts a program inside Foo is not seen. Plain Ex and Lua are not guarded: they
are what you could type into the command line yourself. Do not `:Execute!` text from a source you do not trust.

## Known limits

- A hand-typed range (`:3Execute`) after an older charwise Visual selection on the same line cuts by that old
  selection's columns (Neovim does not say whether a range came from Visual mode). Use `--from=line` there.
- A leading `!` is a shell marker only on the first command of text that is not a code block; in a bash block
  `! grep x` is a negation and stays.

## Files

| File | Role |
| --- | --- |
| `source.lua` | finds the text (`backtick_at`, `fence_at` are pure; `get` reads the buffer) |
| `kind.lua` | Ex / Lua / shell detection, the commands, the `risky` flag |
| `sink.lua` | runs a plan, shows or copies the result |
| `init.lua` | the flow of one invocation and the composer verb |

Specs: `TESTS/execute/execute_spec.lua`.

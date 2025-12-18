# DiffFile Neovim Command

`DiffFile` is a flexible Neovim command to generate diffs between files or buffers.

## Table of content

  - [Usage](#usage)
    - [Options](#options)
    - [Examples](#examples)

---

## Usage

```vim
:DiffFile [source] [target] [output] [options]
```

* **source**: Source file to diff. Use `%` for current buffer.
* **target**: Target file. If omitted, diff is performed against source only.
* **output**: Optional file to write diff. If omitted, diff is opened in a scratch buffer.

---

### Options

| Short | Long        | Description                    |
| ----- | ----------- | ------------------------------ |
| -c    | --context   | Generate context diff          |
| -u    | --unified   | Generate unified diff          |
| -r    | --recursive | Recursively diff directories   |
| -s    | --show      | Open output after creation     |
| -S    | --source    | Specify source file explicitly |
| -T    | --target    | Specify target file explicitly |
| -O    | --output    | Specify output file explicitly |

---

### Examples

```vim
" Diff current buffer against old.lua, open in scratch buffer
:DiffFile % old.lua -u

" Diff specified files, write diff to patch and show
:DiffFile -S old.lua -T new.lua -O feature.patch -u -s
```

---
DiffFile -S C:\Users\Bernhard\AppData\Local\nvim\patches\noice\lsp\signature_FIXED.lua -T C:\Users\Bernhard\AppData\Local\nvim-data\lazy\noice.nvim\lua\noice\lsp\signature.lua -O C:\Users\Bernhard\AppData\Local\nvim\patches\noice\lsp\noice-lsp-signature-replace.patch_USR -u -s

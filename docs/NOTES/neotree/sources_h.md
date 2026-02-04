================================================================================
OTHER SOURCES                                                                  ~
================================================================================
                                                              *neo-tree-sources*

Neo-tree supports other sources beside the filesystem source which is used by
default. The rest of the sources follow the same pattern as the filesystem
sources described above. The following sections will give an overview of each
source and describe the options that are unique to those sources.


BUFFERS                                                        *neo-tree-buffers*

The buffers source shows all open buffers. This is the same list that |ls| would
show. This view adds one component, which is the buffer number, shown to the
right of the file name by default.

If you use sessions, your previously loaded buffers may be saved as part of
the session, but they will be unloaded at first. If you want to see these
unloaded buffers, set `show_unloaded = true` in your `buffers` config.
Otherwise, you will only see the buffers that have been opened since starting
nvim.

As a list of files, this source shares most of the commands with the filesystem
source, with the exception of filtering. Some of these commands make less
sense to use here, as things like adding new files won't be visible until you
open them by some other means. One command that is unique to this view is
`buffer_delete`, which issues |:bdelete| on the selected buffer. This is mapped
to `bd` by default.


GIT STATUS                                           *neo-tree-git-status-source*

The git_status view shows the output of the `git status` command in the tree.
Unlike the other sources, this will always show the project root of the
current working directory. If the working tree is clean, this view will be
empty.

This view has most file commands except for "add", plus the following git
specific commands:
>lua
      ["A"]  = "git_add_all",
      ["ga"] = "git_add_file",
      ["gu"] = "git_unstage_file",
      ["gU"] = "git_undo_last_commit",
      ["gr"] = "git_revert_file",
      ["gc"] = "git_commit"
      ["gp"] = "git_push",
      ["gg"] = "git_commit_and_push",
<

DOCUMENT SYMBOLS                                     *neo-tree-document-symbols*

The document_symbols source lists the symbols in the current document obtained
by the LSP request "textDocument/documentSymbols".

Its configuration includes the following options:

follow_cursor~
If set to `true`, will automatically focus on the symbol under the cursor.

kinds~
A table specifying how LSP kinds should be rendered. Each entry should map the
LSP kind name to an icon and a highlight group, for example
  `Class = { icon = "󰌗", hl = "Include" }`

custom_kinds~
A table mapping the LSP kind id (an integer) to the LSP kind name that is used
for `kinds`, for example
  `[252] = 'TypeAlias'`

For the list of kinds (id and name), please refer to
https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_documentSymbol

client_filters~
This option could be used to set which LSP server is used to obtain the document
symbols. This accepts one of the following values

  `"first"`: use the first LSP server that provides the feature
  `"all"`: use all LSP server that provides the feature
  `{ fn = function(name), allow_only = table, ignore = table }` where
      `fn`: a function that returns `true` if the server `name` should be used
      `allow_only`: use only servers from this list
      `ignore`: exclude all servers from this list
      NOTE: `fn` preceeds `allow_only` preceeds `ignore`

For example: (NOTE: here only `fn` will be taken into account)
>lua
  {
    fn = function(name) return name ~= "null-ls" end,
    allow_only = { "clangd", "lua_ls" },
    ignore = { "pyright" },
  }
<
Currently, this source supports the following commands:
>lua
    ["o"] = "jump_to_symbol",
    ["r"] = "rename",
    ["P"] = "preview", (and related commands)
    ["s"] = "split", (and related commands)
<
vim:tw=80:ts=2:et:ft=help:


Press the corresponding key to execute the command.
               Press <Esc> to cancel.

         KEY(S)    COMMAND
              # -> fuzzy_sorter
              + -> filetree: set dir as root (down)
              - -> filetree: parent dir (up)
              . -> set_root
              / -> filetree: filter tree
  <2-LeftMouse> -> open
          <C-;> -> clear_selection
        <C-S-i> -> invert_selection
          <C-b> -> scroll_preview
          <C-f> -> scroll_preview
          <C-r> -> clear_clipboard
          <C-s> -> quick_jump
          <C-x> -> clear_filter
           <CR> -> Safe expand / collapse nodes and open files
          <Tab> -> select
           <bs> -> navigate_up
          <c-n> -> filetree: next buffer in adjacent window
          <c-p> -> filetree: previous buffer in adjacent window
          <c-s> -> filetree: save adjacent buffer
           <cr> -> open
          <esc> -> cancel
     <leader>fm -> filetree: open in file manager
     <leader>mc -> filetree: clear all marks
     <leader>ms -> filetree: show marked nodes
     <leader>th -> filetree: show trash history
          <m-s> -> filetree: save node buffer
         <s-cr> -> filetree: add to buffer list (no focus switch)
        <space> -> toggle_node
          <tab> -> filetree: toggle preview
              > -> next_source
              ? -> show_help
              A -> add_directory
              C -> close_node
              D -> fuzzy_finder_directory
              H -> toggle_hidden
              I -> filetree: node info
             ML -> filetree: markdown link for current node
             MM -> filetree: markdown links from marked
             MR -> filetree: markdown links recursively
              O -> filetree: open (replace buffer)
              P -> toggle_preview
              R -> refresh
              S -> open_split
              T -> trash
              U -> filetree: undo last trash
              W -> open_with_window_picker
             [F -> filetree: copy dir list (abs)
             [R -> filetree: copy absolute project root
             [e -> filetree: copy path with an env-var root
             [f -> filetree: copy file list (abs)
             [g -> prev_git_modified
             [m -> filetree: unmark all visible
             ]F -> filetree: copy dir list (rel)
             ]R -> filetree: copy path relative to project root
             ]a -> filetree: copy absolute parent directory
             ]b -> filetree: copy path relative to the open buffer
             ]f -> filetree: copy file list (rel)
             ]g -> next_git_modified
             ]m -> filetree: mark all visible
              a -> add
              b -> rename_basename
              c -> copy
              d -> filetree: trash current node
              e -> toggle_auto_expand_width
              f -> filter_on_submit
             gb -> filetree: add to buffer list (no focus switch)
             gp -> filetree: open PDF (pdfport)
             gs -> filetree: live search
              i -> filetree: run shell command
              l -> focus_preview
              m -> filetree: toggle mark
              o -> show_help
             oc -> order_by_created
             od -> order_by_diagnostics
             og -> order_by_git_status
             om -> order_by_modified
             on -> order_by_name
             os -> order_by_size
             ot -> order_by_type
              p -> paste_from_clipboard
              q -> close_window
              r -> rename
             rq -> filetree: copy as require()
             sg -> filetree: open in vertical split
             st -> filetree: open in new tab
             sv -> filetree: open in horizontal split
              u -> undo
              w -> filetree: cycle window size
              z -> close_all_nodes

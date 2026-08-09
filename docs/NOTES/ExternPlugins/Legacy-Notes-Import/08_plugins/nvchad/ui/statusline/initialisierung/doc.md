4. Statusline                                                  *nvui.statusline*

NvChad's statusline is minimal & customizable with less abstraction
for custom modules, it has 4 themes.

Managing modules example: ~
>lua
 M.ui = {
   statusline = {
     theme = "default",
     separator_style = "default",
     order = { "mode", "f", "git", "%=", "lsp_msg", "%=", "lsp", "cwd", "xyz", "abc" },
     modules = {
       abc = function()
         return "hi"
       end,

       xyz =  "hi",
       f = "%F"
     }
   },
 }
<
Above modules field shows how you can add custom modules to the statusline

Note:  The |"%F"| is a stl modifier, check `stl` to know list of modifiers
 - The module can be a string/function
 - |"%="| is a separator, modules before 1st separator will be on the left
        and after the last separator on the right

theme: ~
   |values| = default, vscode, vscode_colored, minimal

separator_style: ~
   |values| = default, round, block, arrow
   Note: the style wont work for vscode themes

Order: ~
  - The order can be found at
    `https://github.com/NvChad/ui/blob/v3.0/lua/nvchad/stl/utils.lua`

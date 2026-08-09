1.1 Tabufline API                                          *nvui.tabufline.api*

These are some useful |functions| to use the tabufline

`Switch Buffers`
>lua
 require("nvchad.tabufline").prev()
 require("nvchad.tabufline").next()
<
`Close Buffers`
>lua
 require("nvchad.tabufline").close_buffer()

 -- closes all buffers
 require("nvchad.tabufline").closeAllBufs(true)
 require("nvchad.tabufline").closeAllBufs(false) -- excludes current buf

 require("nvchad.tabufline").closeBufs_at_direction("left") -- or right
<
`Move Buffers`

This moves the buffer's position to left/right (-1 for left)
>lua
 require("nvchad.tabufline").move_buf(1) or -1
<
`API Recipe Example`

All buffer numbers are stored in |vim.t.bufs| (tab-local variable)

This example maps Alt+number keys to switch buffer
>lua
 for i = 1, 9, 1 do
   vim.keymap.set("n", string.format("<A-%s>", i), function()
     vim.api.nvim_set_current_buf(vim.t.bufs[i])
   end)
 end
<


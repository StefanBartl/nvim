---@module 'config.gp.hooks.buffer_new_chat'
---@brief `:BufferGpChatNew` is a dedicated command for `gp.nvim` which
--- opens a new chat with the entire current buffer as context

return {
  --- Register command `:GpBufferChatNew`
  ---@param gp table gp.nvim API handle
  ---@param _ table command parameters (unused)
  BufferChatNew = function(gp, _)
    -- Simulate range command: `:%GpChatNew`
    vim.api.nvim_command("%" .. gp.config.cmd_prefix .. "ChatNew")
  end
}

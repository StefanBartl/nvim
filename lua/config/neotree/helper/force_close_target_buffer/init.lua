---@module 'config.neotree.helper.force_close_target_buffer'
---Hilfsfunktion: Schließt alle offenen Buffer, die zu den gelöschten Pfaden gehören,
---ohne leere "No name"-Buffer zu hinterlassen.

---@param state Cfg.NeoTree.State
return function (state)
  local tree = state.tree
  if not tree then return end

  local target_paths = {}

  -- 1. Pfade sammeln
  if state.explicitly_marked_node_ids and next(state.explicitly_marked_node_ids) then
    for path, _ in pairs(state.explicitly_marked_node_ids) do
      target_paths[vim.fs.normalize(path)] = true
    end
  else
    local node = tree:get_node()
    if node and node.path then
      target_paths[vim.fs.normalize(node.path)] = true
    end
  end

  -- 2. Passende Buffer ermitteln
  local bufs_to_close = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_option(buf, "buflisted") then
      local buf_name = vim.api.nvim_buf_get_name(buf)
      if buf_name ~= "" then
        local normalized_buf_path = vim.fs.normalize(buf_name)

        for target_path, _ in pairs(target_paths) do
          if normalized_buf_path == target_path or normalized_buf_path:find("^" .. vim.pesc(target_path) .. "/") then
            table.insert(bufs_to_close, buf)
            break
          end
        end
      end
    end
  end

  -- 3. Buffer fokussieren & sauber schließen
  for _, buf in ipairs(bufs_to_close) do
    -- Wenn der zu löschende Buffer gerade in irgendeinem Fenster aktiv zu sehen ist,
    -- schalten wir dieses Fenster erst auf den vorherigen Buffer um.
    local wins = vim.fn.win_findbuf(buf)
    for _, win in ipairs(wins) do
      vim.api.nvim_win_call(win, function()
        -- Schaltet auf den vorherigen Buffer in der Historie um
        pcall(vim.cmd, "bprevious")
      end)
    end

    -- Jetzt kann der Buffer ohne "No Name"-Glitch restlos gekillt werden
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end
end

---@module 'config.neotree.keymaps.filesystem.commands'
--- Command and picker integrations (telescope, custom commands).

---@type table<string, any>
return {
  ["i"] = "run_command",
  ["tf"] = "telescope_find",
  ["tg"] = "telescope_grep",

  ["ML"] = "markdown_links",
  ["MR"] = "markdown_links_recursive",
  ["MM"] = "markdown_links_from_marked",
}

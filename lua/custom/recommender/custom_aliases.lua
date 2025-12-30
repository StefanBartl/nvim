---@module 'custom.recommender.custom_aliases'

return {
  -- Vim API
  ["vim.api"] = "api",
  ["vim.fn"] = "fn",
  ["vim.keymap.set"] = "km_set",
  ["vim.opt"] = "opt",
  ["vim.cmd"] = "cmd",
  ["vim.lsp"] = "lsp",
  ["vim.schedule"] = "schedule",
  ["vim.defer_fn"] = "defer_fn",
  ["vim.notify"] = "notify",
  ["vim.log.levels"] = "levels",

  -- Table functions
  ["table.insert"] = "tbl_insert",
  ["table.concat"] = "tbl_concat",
  ["table.remove"] = "tbl_remove",

  -- String functions
  ["string.format"] = "str_fmt",
  ["string.match"] = "str_match",

  -- Math functions
  ["math.floor"] = "floor",
  ["math.ceil"] = "ceil",
  ["math.max"] = "max",
  ["math.min"] = "min",

  ["os.date"] = "os_date",
  ["os.execute"] = "os_execute",
}

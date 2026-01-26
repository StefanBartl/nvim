---@module 'lib.json'

local lazy = require("lib.lazy")

local M = {}

-- =========================================================
-- Decode
-- =========================================================

---@type Lib.JSON.Decode.ToStringArray
local decode_to_str_arr_module = lazy.require("lib.json.decode.to_string_array")

M.decode.is_array_like = decode_to_str_arr_module.is_array_like
M.decode.ensure_string_array = decode_to_str_arr_module.ensure_string_array
M.decode.table_to_string_array = decode_to_str_arr_module.table_to_string_array

---@type Lib.JSON
return M

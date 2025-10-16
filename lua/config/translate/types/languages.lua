---@module 'translate.types.languages'
---@class TranslateLanguage
---@field code string Language code like "EN", "DE", "FR"
---@field name string Human readable name

---@type TranslateLanguage[]
local languages = {
    { code = "EN", name = "English" },
    { code = "DE", name = "German" },
    { code = "FR", name = "French" },
    { code = "ZH", name = "Chinese" },
    { code = "JA", name = "Japanese" },
}

return languages

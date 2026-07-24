---@module 'lsp.@types.languages'

-- # Webdev languages (Modules)

---@class Lsp.Languages.ConfiguredLangs.Webdev.Astro.Module
---@field enable fun(): nil # Enable astro language

---@class Lsp.Languages.ConfiguredLangs.Webdev.HTML.Module
---@field enable fun(): nil # Enable html language

---@class Lsp.Languages.ConfiguredLangs.Webdev.Typescript.Module
---@field enable fun(): nil # Enable typescript language

-- # Languages (Modules)

---@class Lsp.Languages.ConfiguredLangs.C.Module
---@field enable fun(): nil # Enable c language

---@class Lsp.Languages.ConfiguredLangs.CSharp.Module
---@field enable fun(): nil # Enable csharp language

---@class Lsp.Languages.ConfiguredLangs.Dart.Module
---@field enable fun(): nil # Enable dart language

---@class Lsp.Languages.ConfiguredLangs.Go.Module
---@field enable fun(): nil # Enable go language

---@class Lsp.Languages.ConfiguredLangs.Java.Module
---@field enable fun(): nil # Enable java language

---@class Lsp.Languages.ConfiguredLangs.Lua.Module
---@field enable fun(): nil # Enable lua language

---@class Lsp.Languages.ConfiguredLangs.Markdown.Module
---@field enable fun(): nil # Enable markdown language
---@field setup_reference_hl fun(): nil # Set highlight for LSP reference groups (affects documentHighlight results).

---@class Lsp.Languages.ConfiguredLangs.Shell.Module
---@field enable fun(): nil # Enable shell language

---@class Lsp.Languages.ConfiguredLangs.Zig.Module
---@field enable fun(): nil # Enable zig language

-- All Languages (Modules)

---@class Lsp.Languages.ConfiguredLangs
---@field astro_module Lsp.Languages.ConfiguredLangs.Webdev.Astro.Module
---@field html_module Lsp.Languages.ConfiguredLangs.Webdev.HTML.Module
---@field typescript_module Lsp.Languages.ConfiguredLangs.Webdev.Typescript.Module
---@field c_module Lsp.Languages.ConfiguredLangs.C.Module
---@field csharp_module Lsp.Languages.ConfiguredLangs.CSharp.Module
---@field dart_module Lsp.Languages.ConfiguredLangs.Dart.Module
---@field go_module Lsp.Languages.ConfiguredLangs.Go.Module
---@field java_module Lsp.Languages.ConfiguredLangs.Java.Module
---@field lua_module Lsp.Languages.ConfiguredLangs.Lua.Module
---@field markdown_module Lsp.Languages.ConfiguredLangs.Markdown.Module
---@field shell_module Lsp.Languages.ConfiguredLangs.Shell.Module
---@field zig_module Lsp.Languages.ConfiguredLangs.Zig.Module


-- # Webdev Languages (Literals)

---@class Lsp.Languages.ConfiguredLangs.Literal.Webdev
---@field astro_literal "astro"
---@field html_literal "html"
---@field typescript_literal "typescript"

-- # All Languages (Literals)

---@class Lsp.Languages.ConfiguredLangs.Literal
---@field webdev_literal Lsp.Languages.ConfiguredLangs.Literal.Webdev
---@field c_literal "c"
---@field csharp_literal "csharp"
---@field dart_literal "dart"
---@field go_literal "go"
---@field java_literal "java"
---@field lua_literal "lua"
---@field markdown_literal "markdown"
---@field shell_literal "shell"
---@field zig_literal "zig"

---@alias Lsp.Languages.ConfiguredLangs.Literal.Web "astro" | "html" | "typescript" # Web & UI
---@alias Lsp.Languages.ConfiguredLangs.Literal.Systems "c" | "zig" | "go" # Systemnahe Sprachen (Manual Memory / Performance)
---@alias Lsp.Languages.ConfiguredLangs.Literal.App "java" | "csharp" | "dart" # Application Development (VM-basiert / Strong Typing)
---@alias Lsp.Languages.ConfiguredLangs.Literal.Scripting "lua" | "shell" # Automatisierung & Konfiguration
---@alias Lsp.Languages.ConfiguredLangs.Literal.Doc "markdown" # Dokumentation

--- Alle Sprach-Literals kombiniert
---@alias Lsp.Languages.ConfiguredLangs.Literal.All Lsp.Languages.ConfiguredLangs.Literal.Web | Lsp.Languages.ConfiguredLangs.Literal.Systems | Lsp.Languages.ConfiguredLangs.Literal.App | Lsp.Languages.ConfiguredLangs.Literal | Lsp.Languages.ConfiguredLangs.Literal.Doc

---@alias Lsp.Languages.ConfiguredLangs.Literal.AllLiteral "astro" | "html" | "typescript" | "c" | "csharp" | "zig" | "go" | "java" | "dart" | "lua" | "shell" | "markdown"

return {}

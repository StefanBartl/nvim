---@module 'custom.pathfinder.extractor.common_extensions'

-- Extended list of common file extensions to prioritize when expanding from an extension.
-- Comments are in English as required for generated code comments.
---@type string[]
return {
  -- Scripting / shell
  ".sh",
  ".bash",
  ".zsh",
  ".fish",
  ".ps1",
  ".psm1",
  ".bat",
  ".cmd",

  -- Lua, Vimscript, Neovim plugin files
  ".lua",
  ".vim",
  ".vimrc",
  ".nvim.lua", -- occasional convention

  -- JavaScript / TypeScript / Node
  ".js", ".cjs", ".mjs",
  ".ts", ".cts", ".mts",
  ".jsx", ".tsx",
  ".json",
  ".jsonc",

  -- Web / Markup / Templates
  ".html", ".htm", ".xhtml",
  ".xml", ".xsd",
  ".css", ".scss", ".sass", ".less",
  ".hbs", ".mustache", ".ejs", ".twig", ".jade", ".pug",
  ".tpl", ".tmpl",
  ".jinja", ".j2",

  -- Backend / compiled languages
  ".py",
  ".rb",
  ".php",
  ".java",
  ".kt", ".kts",
  ".go",
  ".rs",
  ".c", ".cpp", ".cc", ".cxx",
  ".h", ".hpp", ".hh",
  ".cs",
  ".swift",
  ".scala",
  ".hs", ".lhs",
  ".erl", ".ex", ".exs", -- erlang / elixir

  -- Build / config / CI
  ".Makefile", -- note: many makefiles have no extension; include common variants
  ".mk",
  ".gradle",
  ".gradle.kts",
  ".pom", -- XML pom files sometimes used
  ".dockerfile",
  ".yml", ".yaml",
  ".toml",
  ".ini",
  ".conf",
  ".cfg",
  ".env",
  ".service",
  ".procfile",

  -- Data / serialization / DB / queries
  ".sql",
  ".psql",
  ".csv",
  ".tsv",
  ".yaml",
  ".yml",
  ".avro",
  ".proto",

  -- Documentation / text formats
  ".md",
  ".markdown",
  ".rst",
  ".adoc", ".asciidoc",
  ".tex",
  ".bib",
  ".txt",
  ".org",

  -- Misc programming / scripts
  ".awk",
  ".sed",
  ".pl", ".pm", -- perl
  ".rb", -- already listed but harmless duplicate
  ".go",
  ".jl", -- julia
  ".R", ".r", -- R scripts (case sensitive on some systems)

  -- Configuration and manifest formats
  ".ini",
  ".toml",
  ".yaml",
  ".yml",
  ".plist",
  ".desktop",

  -- Language-specific metadata / lock / manifest
  "package.json",
  "package-lock.json",
  "yarn.lock",
  "Cargo.toml",
  "Cargo.lock",
  "go.mod",
  "go.sum",

  -- Log / patch / diff
  ".log",
  ".diff",
  ".patch",

  -- Source-generation / templates
  ".sqlx", ".eex", ".tt", ".tmpl",

  -- Archive / compressed (viewable as text in many cases; include for search)
  ".zip", ".tar", ".gz", ".tgz", ".bz2", ".7z",
  ".tar.gz",

  -- Binary / executable formats (Neovim can open them as bytes; include if desired)
  ".elf",
  ".exe",
  ".dll",
  ".so",
  ".dylib",
  ".sys",
  ".ocx",

  -- Additional common filetypes often edited in nvim
  ".editorconfig",
  ".gitattributes",
  ".gitignore",
  ".gitmodules",
  ".env.example",
  ".ini",
  ".rst",
  ".csv",
}

-- Deduplicate and normalize small anomalies may be handled programmatically in code.

---@module 'config.neotree.helper.is_ignored_dir.ignored_dirs'
--- List of folder names to ignore during recursive collection.
--- Just the folder name, not the full path.

---@type string[]
return {
    ".git",
    ".github",
    ".husky",
    "node_modules",
    "dist",
    "build",
    "doc",
    "docs"
}


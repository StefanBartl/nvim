---@meta
---@module 'custom.lua_project_file_stats.types'
---@brief Type definitions for Lua Project File Statistics
---@description
--- Central type definitions for the entire project.
--- All types are prefixed with 'LuaProjectFileStats.' for namespace clarity.

---@class LuaProjectFileStats.Stats
---@field total_lines integer Total number of lines in file/folder
---@field total_files integer Total number of lines in file/folder
---@field lines_without_comments integer Lines that are not comments
---@field comment_lines integer Lines containing comments (including annotations)
---@field lines_without_annotations integer Lines that are not annotations
---@field annotation_lines integer Lines containing @-annotations
---@field blank_lines integer Whitespace-only lines
---@field total_words integer Total word count
---@field words_in_comments integer Words in comment sections
---@field words_in_annotations integer Words in annotation comments
---@field words_without_comments integer Words in code sections
---@field words_without_annotations integer Words in non-annotation sections
---@field words_in_blank integer Words in blank lines (usually 0)

---@class LuaProjectFileStats.FileInfo
---@field rel_file string Relative file path
---@field stats LuaProjectFileStats.Stats File statistics

---@class LuaProjectFileStats.FolderStats : LuaProjectFileStats.Stats
---@field file_count integer Number of files in folder
---@field files LuaProjectFileStats.FileInfo[] List of files with their stats

---@class LuaProjectFileStats.Ratios
---@field comment_ratio number Fraction of comment lines (0-1)
---@field annotation_ratio number Fraction of annotation lines (0-1)
---@field doc_ratio number Combined documentation ratio (0-1)
---@field code_ratio number Fraction of code lines (0-1)
---@field avg_lines_per_file number Average lines per file
---@field annotation_to_comment_ratio number Ratio of annotations to comments

---@class LuaProjectFileStats.Config
---@field root_dir string Directory to analyze
---@field reverse_order boolean Reverse output order (summary first)
---@field percent_mode "both"|"percent"|"numbers" Display mode for statistics
---@field fields_to_print string[] Which tables to print ("files", "folders", "summary")
---@field single_file_path string|nil Single file mode path
---@field col_width integer Column width for ASCII tables
---@field top_n integer Number of items in top-N lists
---@field only_top_files_lines boolean Show only top files by lines
---@field only_top_files_words boolean Show only top files by words
---@field show_ratios boolean Show ratio analysis
---@field show_deviations boolean Show deviations from global average
---@field output_file string|nil Output file path
---@field interactive boolean Interactive mode enabled
---@field async boolean Async execution (Neovim only)

---@class LuaProjectFileStats.TopItem
---@field rel string Relative path
---@field stats LuaProjectFileStats.Stats File statistics

---@class LuaProjectFileStats.TopFolder
---@field folder string Folder path
---@field ratio number Annotation ratio
---@field lines integer Total lines

---@class LuaProjectFileStats.State
---@field folder_summary table<string, LuaProjectFileStats.FolderStats> Per-folder statistics
---@field total_stats LuaProjectFileStats.Stats Global totals
---@field global_averages LuaProjectFileStats.Ratios Global average ratios
---@field output_buffer string[] Output lines for file writing
---@field cwd string Current working directory

---@alias LuaProjectFileStats.PercentMode "both"|"percent"|"numbers"
--- Display mode for numeric values:
---| "both": Shows both number and percentage, e.g. "42 (23.5%)"
---| "percent": Shows only percentage, e.g. "23.5%"
---| "numbers": Shows only absolute number, e.g. "42"

---@alias LuaProjectFileStats.FieldType "files"|"folders"|"summary"
--- Output table types:
---| "files": Per-file statistics table
---| "folders": Per-folder summary table
---| "summary": Global summary table

return {}

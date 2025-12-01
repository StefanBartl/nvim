---@module 'autocmds.markdown.gofile_alternate'
--- Alternate file resolution with fuzzy matching and interactive selection.
--- This module is invoked when the primary gofile resolution fails to find an exact match.
--- It attempts to locate similar files in the target directory and presents them via hover-select.

local uv = vim.loop

---Calculate Levenshtein distance between two strings (character-level edit distance).
---@param s1 string
---@param s2 string
---@return integer distance
local function levenshtein_distance(s1, s2)
  local len1, len2 = #s1, #s2
  if len1 == 0 then
    return len2
  end
  if len2 == 0 then
    return len1
  end

  -- Create distance matrix
  local matrix = {}
  for i = 0, len1 do
    matrix[i] = { [0] = i }
  end
  for j = 0, len2 do
    matrix[0][j] = j
  end

  -- Fill matrix with edit distances
  for i = 1, len1 do
    for j = 1, len2 do
      local cost = (s1:sub(i, i) == s2:sub(j, j)) and 0 or 1
      matrix[i][j] = math.min(
        matrix[i - 1][j] + 1, -- deletion
        matrix[i][j - 1] + 1, -- insertion
        matrix[i - 1][j - 1] + cost -- substitution
      )
    end
  end

  return matrix[len1][len2]
end

---Calculate similarity percentage between two strings (0-100).
---Uses Levenshtein distance normalized by the longer string length.
---@param s1 string
---@param s2 string
---@return number similarity Percentage (0-100)
local function calculate_similarity(s1, s2)
  if s1 == s2 then
    return 100
  end

  local distance = levenshtein_distance(s1:lower(), s2:lower())
  local max_len = math.max(#s1, #s2)

  if max_len == 0 then
    return 100
  end

  local similarity = (1 - (distance / max_len)) * 100
  return math.max(0, similarity)
end

---Check if a path exists as a directory.
---@param path string
---@return boolean exists
local function is_directory(path)
  if type(path) ~= "string" or path == "" then
    return false
  end

  local stat = uv.fs_stat(path)
  return stat ~= nil and stat.type == "directory"
end

---Extract directory path from a full file path.
---Handles both Unix and Windows path separators.
---@param filepath string
---@return string|nil dir_path
local function extract_directory(filepath)
  if not filepath or filepath == "" then
    return nil
  end

  -- Try Unix-style separator first
  local dir = filepath:match("^(.+)/[^/]+$")
  if dir then
    return dir
  end

  -- Try Windows-style separator
  dir = filepath:match("^(.+)\\[^\\]+$")
  if dir then
    return dir
  end

  -- If no separator found, might be current directory or malformed
  return nil
end

---Extract filename from a full file path.
---@param filepath string
---@return string|nil filename
local function extract_filename(filepath)
  if not filepath or filepath == "" then
    return nil
  end

  -- Try Unix-style separator
  local name = filepath:match("([^/]+)$")
  if name then
    return name
  end

  -- Try Windows-style separator
  name = filepath:match("([^\\]+)$")
  return name
end

---Scan directory and return all regular files.
---@param dir_path string
---@param logger table
---@return string[]|nil files List of absolute file paths, or nil on error
local function scan_directory(dir_path, logger)
  local handle, err = uv.fs_scandir(dir_path)
  if not handle then
    if logger and logger.debug then
      logger.debug("gofile_alternate: fs_scandir failed", { dir = dir_path, err = err })
    end
    return nil
  end

  local files = {}
  while true do
    local name, type = uv.fs_scandir_next(handle)
    if not name then
      break
    end

    -- Only include regular files
    if type == "file" then
      local full_path = dir_path .. "/" .. name
      table.insert(files, full_path)
    end
  end

  return files
end

---Find files in directory that match the target filename with similarity >= threshold.
---@param dir_path string
---@param target_filename string
---@param threshold number Similarity threshold (0-100)
---@param logger table
---@return table[] matches List of {path: string, similarity: number}, sorted by similarity desc
local function find_similar_files(dir_path, target_filename, threshold, logger)
  local all_files = scan_directory(dir_path, logger)
  if not all_files or #all_files == 0 then
    if logger and logger.debug then
      logger.debug("gofile_alternate: no files found in directory", { dir = dir_path })
    end
    return {}
  end

  local matches = {}
  for _, filepath in ipairs(all_files) do
    local filename = extract_filename(filepath)
    if filename then
      local similarity = calculate_similarity(target_filename, filename)
      if similarity >= threshold then
        table.insert(matches, {
          path = filepath,
          similarity = similarity,
          filename = filename,
        })
      end
    end
  end

  -- Sort by similarity descending
  table.sort(matches, function(a, b)
    return a.similarity > b.similarity
  end)

  if logger and logger.debug then
    logger.debug("gofile_alternate: found similar files", {
      count = #matches,
      threshold = threshold,
    })
  end

  return matches
end

---Present similar files in an interactive hover-select window.
---@param matches table[] List of {path, similarity, filename}
---@param logger table
---@return boolean handled True if user selected a file
local function present_selection(matches, logger)
  -- Lazy-load hover-select module
  local ok, hover_select = pcall(require, "lib.hover_select")
  if not ok then
    if logger and logger.error then
      logger.error("gofile_alternate: hover-select module not available", { err = hover_select })
    end
    vim.notify("hover-select module not found. Cannot present alternate files.", vim.log.levels.ERROR)
    return false
  end

  -- Format items for display: "filename (85%)"
  local items = {}
  for _, match in ipairs(matches) do
    local display = string.format("%s (%.0f%%)", match.filename, match.similarity)
    table.insert(items, display)
  end

  -- Track if user made a selection
  local selected = false

  hover_select.open({
    items = items,
    title = " Select Alternate File ",
    relative = "cursor",
    on_select = function(_, index)
      local match = matches[index]
      if match and match.path then
        if logger and logger.info then
          logger.info("gofile_alternate: user selected alternate", {
            path = match.path,
            similarity = match.similarity,
          })
        end

        -- Open selected file
        vim.cmd("edit " .. vim.fn.fnameescape(match.path))
        selected = true
      end
    end,
  })

  return selected
end

---Attempt alternate file resolution when exact match fails.
---1. Extract directory from target path
---2. Check if directory exists
---3. Find similar files in directory
---4. Present interactive selection if matches found
---@param target_path string The path that failed to resolve
---@param cfg table Configuration table
---@param logger table Logger instance
---@return boolean handled True if alternate was found and opened
return function (target_path, cfg, logger)
  if not target_path or target_path == "" then
    if logger and logger.debug then
      logger.debug("gofile_alternate: empty target path")
    end
    return false
  end

  if logger and logger.info then
    logger.info("gofile_alternate: attempting alternate resolution", { target = target_path })
  end

  -- Step 1: Extract directory
  local dir_path = extract_directory(target_path)
  if not dir_path then
    if logger and logger.debug then
      logger.debug("gofile_alternate: could not extract directory", { target = target_path })
    end
    return false
  end

  -- Step 2: Check if directory exists
  if not is_directory(dir_path) then
    if logger and logger.debug then
      logger.debug("gofile_alternate: directory does not exist", { dir = dir_path })
    end
    return false
  end

  if logger and logger.debug then
    logger.debug("gofile_alternate: found target directory", { dir = dir_path })
  end

  -- Step 3: Extract target filename
  local target_filename = extract_filename(target_path)
  if not target_filename then
    if logger and logger.debug then
      logger.debug("gofile_alternate: could not extract filename", { target = target_path })
    end
    return false
  end

  -- Get similarity threshold from config
  local threshold = 75 -- default
  if cfg and cfg.goto_file and cfg.goto_file.alternate_similarity_threshold then
    threshold = cfg.goto_file.alternate_similarity_threshold
  end

  -- Step 4: Find similar files
  local matches = find_similar_files(dir_path, target_filename, threshold, logger)

  if #matches == 0 then
    if logger and logger.info then
      logger.info("gofile_alternate: no similar files found", {
        dir = dir_path,
        target_filename = target_filename,
        threshold = threshold,
      })
    end
    return false
  end

  -- Step 5: Present selection
  return present_selection(matches, logger)
end

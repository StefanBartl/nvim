---@meta
---@module '@types.log'

---@alias LogLevelString
---| "TRACE" # Trace level (0)
---| "DEBUG" # Debug level (1)
---| "INFO" # Info level (2)
---| "WARN" # Warning level (3)
---| "ERROR" # Error level (4)
---| "OFF" # Off level (5)

---@alias LogLevelNumber
---| 0 # TRACE
---| 1 # DEBUG
---| 2 # INFO
---| 3 # WARN
---| 4 # ERROR
---| 5 # OFF

---@alias LogLevel LogLevelNumber|LogLevelString

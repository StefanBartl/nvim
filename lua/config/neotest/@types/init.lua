---@meta
---@module 'config.neotest.types'

---@class Cfg.Neotest.AdapterConfig
---@field adapter table|nil Neotest adapter instance
---@field test_patterns string[] File patterns that identify test files
---@field is_test_file fun(filepath: string): boolean Check if file is a test file
---@field get_test_patterns? fun(): string[] Optional: Get framework-specific test patterns
---@field get_note? fun(): string Optional: Get adapter-specific notes

---@class Cfg.Neotest.Position
---@field type 'test'|'namespace'|'file'|'dir' Position type
---@field path string Full path to the test file
---@field name string Display name
---@field range integer[] Line range [start, end]

---@class Cfg.Neotest.Result
---@field status 'passed'|'failed'|'skipped'|'running' Test result status
---@field short string|nil Short output message
---@field output string|nil Full output
---@field errors table[]|nil Error details

---@class Cfg.Neotest.RunOpts
---@field strategy? 'integrated'|'dap' Test execution strategy
---@field suite? boolean Run entire test suite
---@field extra_args? string[] Additional command-line arguments

return {}

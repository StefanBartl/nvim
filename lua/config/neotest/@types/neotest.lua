---@module 'config.neotest.@types.neotest'

local M = {}

---@enum NeoTest.PositionType
M.PositionType = {
  dir = "dir",
  file = "file",
  namespace = "namespace",
  test = "test",
}

---@class NeoTest.Position
---@field id string
---@field type NeoTest.PositionType
---@field name string
---@field path string
---@field range integer[]

---@enum NeoTest.ResultStatus
M.ResultStatus = {
  passed = "passed",
  failed = "failed",
  skipped = "skipped",
}

---@class NeoTest.Result
---@field status NeoTest.ResultStatus
---@field output? string Path to file containing full output data
---@field short? string Shortened output string
---@field errors? NeoTest.Error[]

---@class NeoTest.Error
---@field message string
---@field line? integer
---@field severity? integer Diagnostic severity (see vim.diagnostic.severity)

---@class NeoTest.Process
---@field output async fun(): string Path to file containing output data
---@field is_complete fun() boolean Is process complete
---@field result async fun() integer Get result code of process (async)
---@field attach async fun() Attach to the running process for user input
---@field stop async fun() Stop the running process
---@field output_stream async fun(): async fun(): string Async iterator of process output

---@class NeoTest.StrategyContext
---@field position NeoTest.Position
---@field adapter NeoTest.Adapter

---@alias NeoTest.Strategy async fun(spec: NeoTest.RunSpec, context: NeoTest.StrategyContext): NeoTest.Process

---@class NeoTest.StrategyResult
---@field code integer
---@field output string

---@class NeoTest.RunArgs
---@field tree NeoTest.Tree
---@field extra_args? string[]
---@field strategy string

---@class NeoTest.RunSpec
---@field command string[]
---@field env? table<string, string>
---@field cwd? string
---@field context? table Arbitrary data to preserve state between running and result collection
---@field strategy? table|NeoTest.Strategy Arguments for strategy or override for chosen strategy
---@field stream? fun(output_stream: fun(): string[]): fun(): table<string, NeoTest.Result>

---@class NeoTest.InternalClientListeners
---@field discover_positions table<string, fun(adapter_id: integer, tree: NeoTest.Tree)>
---@field run table<string, fun(adapter_id: integer, root_id: string, position_ids: string[])>
---@field results table<string, fun(adapter_id: integer, results: table<string, NeoTest.Result>, partial: boolean)>
---@field test_file_focused table<string,fun(file_path: string)>>
---@field test_focused table<string,fun(pos_id: string)>>

---@class NeoTest.EventProcessor
---@field listeners NeoTest.InternalClientListeners

--- Nested tree structure with nodes containing data and having any
--- number of children
---@class NeoTest.Tree
---@field private _data any
---@field private _children NeoTest.Tree[]
---@field private _nodes table<string, NeoTest.Tree>
---@field private _key fun(data: any): string
---@field private _parent? NeoTest.Tree

---@class NeoTest.ClientState
---@field private _focused_position table<string, string>
---@field private _focused_file table<string, string>
---@field private _positions table<integer, NeoTest.Tree>
---@field private _results table<integer, table<string, NeoTest.Tree> >
---@field private _events NeoTest.EventProcessor
---@field private _running table<integer, table<string, string>>
---@field private _all_positions NeoTest.Tree

---@class NeoTest.Adapter
---@field name string

---@class NeoTest.AdapterGroup
---@field adapters NeoTest.Adapter[]

---@class NeoTest.ProcessTracker
---@field _instances table<integer, NeoTest.Process>
---@field _process_semaphore any -- type: nio.control.Semaphore

---@class NeoTest.TestRunner
---@field _processes NeoTest.ProcessTracker
---@field _running table<string, table>

---@toc_entry Neotest Client
---@text
--- The neotest client is the core of neotest, it communicates with adapters,
--- running tests and collecting results.
--- Most of the client methods are async and so need to be run in an async
--- context (i.e. `require("nio").run(function() ... end))
--- The client starts lazily, meaning that no parsing of tests will be performed
--- until it is required. Care should be taken to not use the client methods on
--- start because it can slow down startup.
---@class NeoTest.Client
---@field private _started boolean
---@field private _state NeoTest.ClientState
---@field private _events NeoTest.EventProcessor
---@field private _adapters table<string, NeoTest.Adapter>
---@field private _adapter_group NeoTest.AdapterGroup
---@field private _runner NeoTest.TestRunner
---@field listeners NeoTest.ConsumerListeners

---@alias NeoTest.Consumers fun(client: NeoTest.Client): table

---@class NeoTest.ConsumerListeners
---@field discover_positions fun(adapter_id: string, tree: NeoTest.Tree)
---@field run fun(adapter_id: string, root_id: string, position_ids: string[])
---@field results fun(adapter_id: string, results: table<string, NeoTest.Result>, partial: boolean)
---@field test_file_focused fun(adapter_id: string, file_path: string)>
---@field test_focused fun(adapter_id: string, position_id: string)>
---@field starting fun()
---@field started fun()
---@type NeoTest.Client

return M

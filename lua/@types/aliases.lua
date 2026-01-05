---@meta
---@module '@types.aliases'

-- Basis-Typen
---@alias void nil
---@alias Path string
---@alias FilePath string
---@alias DirPath string

---@alias TriBool boolean|nil
--- Tri-state boolean:
---   - true   → explicitly enable
---   - false  → explicitly disable
---   - nil    → no-op (do not change current state)

---@alias map fun(mode:string, lhs:string, rhs:fun(), opts:table)
---@alias usercmd fun(name:string, callback:fun(args:table):any, opts:table)

-- Neovim spezifische Aliase
---@alias BufNr number
---@alias WinNr number
---@alias TabNr number
---@alias BufOrNil BufNr|nil
---@alias WinOrNil WinNr|nil
---@alias TabOrNil TabNr|nil
---@alias VimOptionName string
---@alias KeymapOpts table
---@alias AutocmdOpts table

-- Callbacks
---@alias Callback fun(...:any):any
---@alias VoidCallback fun():nil
---@alias UserCmdCallback fun(args:table):any
---@alias KeymapCallback fun():any
---@alias TimerCallback fun():any

-- Modul-Flags / Optionen
---@alias ModuleFlag boolean|nil
---@alias ModuleConfig table|nil

-- Tabellen & Iterables
---@alias StringList string[]
---@alias AnyMap table<string, any>
---@alias FunMap table<string, fun(...:any):any>

-- Generische Funktionstypen
---@alias Fn0 fun():any
---@alias Fn1 fun(arg1:any):any
---@alias Fn2 fun(arg1:any, arg2:any):any
---@alias FnN fun(...:any):any

-- Weitere nützliche Aliase
---@alias Toggle fun():void
---@alias Getter fun():any
---@alias Setter fun(value:any):void
---@alias OptionToggle fun(name:VimOptionName, value:TriBool):void
---@alias EventCallback fun(event:string, args:table):void

return {}

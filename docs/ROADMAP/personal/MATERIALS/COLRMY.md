
:checkhealth color_my_ascii:

==============================================================================
color_my_ascii:                                                             ✅

color_my_ascii.nvim ~
- Checking core modules...
- ✅ OK Module "color_my_ascii" loaded successfully
- ✅ OK Module "color_my_ascii.config" loaded successfully
- ✅ OK Module "color_my_ascii.parser" loaded successfully
- ✅ OK Module "color_my_ascii.highlighter" loaded successfully
- ✅ OK Module "color_my_ascii.language_detector" loaded successfully
- Checking configuration...
- ✅ OK 31 language(s) loaded
- ✅ OK 5 character group(s) loaded
- ✅ OK 241 character(s) in lookup table
- ✅ OK 931 keyword(s) in lookup table
- Feature status:
- Keywords: enabled
- Language detection: enabled
- Function names: enabled
- Bracket highlighting: enabled
- Inline code: enabled
- Empty fence as ASCII: enabled
- Default text highlight: none
- Checking file structure...
- ✅ OK Languages directory found with 31 file(s)
- ✅ OK Groups directory found with 5 file(s)
- ✅ OK Color schemes directory found with 10 scheme(s)
- Checking plugin initialization...
- ✅ OK Plugin initialized successfully
- Current buffer information:
- Filetype:
- Current buffer is not markdown - plugin will not activate
- Checking for common issues...
- ✅ OK Treesitter block detection: markdown parser available
- Treesitter syntax highlighting enabled - availability is checked per block based on the detected language (:TSInstall <language> as needed); silently falls back to heuristic-only highlighting where unavailable
- ✅ OK lib.nvim found - keymap/notify integration available
- Checking public fence API...
- ✅ OK Fence API available at require("color_my_ascii").fences (list_blocks/block_at/is_markdown_lang)
- ✅ OK Fence-line highlight: enabled (preset "auto", apply_to "all")
- ✅ OK All core modules loaded successfully


-----------------

`:lua_print   print(vim.inspect(require('color_my_ascii.config').get()))`:

7:58:38 PM msg_show.lua_print   print(vim.inspect(require('color_my_ascii.config').get())) {
  debug_enabled = false,
  debug_verbose = false,
  default_hl = "Normal",
  enable_bracket_highlighting = true,
  enable_function_names = true,
  enable_inline_code = true,
  enable_keywords = true,
  enable_language_detection = true,
  fence_export = {
    default_dir = "buffer",
    ext_map = {},
    open_after = false,
    open_cmd = "vsplit",
    replace = false,
    replace_format = "[%s](%s)"
  },
  fence_format = {
    formatters = {}
  },
  fence_language_map = {
    bash = "bash",
    c = "c",
    ["c#"] = "csharp",
    ["c++"] = "cpp",
    clj = "clojure",
    clojure = "clojure",
    cpp = "cpp",
    cs = "csharp",
    csharp = "csharp",
    css = "css",
    dart = "dart",
    elixir = "elixir",
    ex = "elixir",
    go = "go",
    golang = "go",
    groovy = "groovy",
    haskell = "haskell",
    hs = "haskell",
    html = "html",
    java = "java",
    javascript = "javascript",
    js = "javascript",
    json = "json",
    kotlin = "kotlin",
    kt = "kotlin",
    llvm = "llvm",
    lua = "lua",
    perl = "perl",
    php = "php",
    pl = "perl",
    powershell = "powershell",
    ps1 = "powershell",
    py = "python",
    python = "python",
    r = "r",
    rb = "ruby",
    rs = "rust",
    ruby = "ruby",
    rust = "rust",
    scala = "scala",
    sh = "bash",
    shell = "bash",
    sql = "sql",
    swift = "swift",
    ts = "typescript",
    typescript = "typescript",
    vim = "vim",
    viml = "vim",
    vimscript = "vim",
    zig = "zig",
    zsh = "bash"
  },
  fence_line_highlight = {
    apply_to = "all",
    enable = true,
    preset = "auto"
  },
  fence_run = {
    runners = {}
  },
  groups = {
    arrows = {
      chars = "←→↑↓⇐⇒⇑⇓↖↗↘↙⇖⇗⇘⇙⇠⇢⇡⇣⟵⟶⟷↰↱↲↳↴↵⤴⤵↼⇀↽⇁↶↷↺↻↔⇔⇄⇅⇆⇵➔➘➙➚➛➜➝➞➟➠➡➢➣➤➥➦➧➨",
      hl = "Special"
    },
    blocks = {
      chars = "█▓▒░▀▄▌▐▖▗▘▝▞▟■□▪▫▬▭▮▯▰▱",
      hl = "Type"
    },
    box_drawing = {
      chars = "─│┌┐└┘├┤┬┴┼═║╔╗╚╝╠╣╦╩╬╒╓╕╖╘╙╛╜╞╟╡╢╤╥╧╨╪╫╭╮╯╰╱╲╳╴╵╶╷",
      hl = "Keyword"
    },
    operators = {
      chars = "+-*/%=<>!&|^~()[]{}:;,.?\"'`@#\\",
      hl = "Operator"
    },
    symbols = {
      chars = "•·∙●○◦‣▸▹►▻◂◃◄◅▲△▴▵▶▷▼▽▾▿◀◁◆◇★☆✦✧✶✴✵✷✸✓✔✗✘✕✖♠♣♥♦♩♪♫♬⊕⊗⊙⊚⊛※⁂⁎⁕℃℉°∞√∑∏∫≈≠≤≥",
      hl = "Delimiter"
    }
  },
  keymaps = false,
  keywords = {
    bash = {
      hl = "Function",
      unique_words = { "fi", "esac", "done", "elif", "bash", "sh", "declare", "readonly" },
      words = { "if", "then", "else", "elif", "fi", "case", "esac", "in", "for", "while", "until", "do", "done", "select", "function", "return", "local", "declare", "readonly", "export", "unset", "shift", "eval", "exec", "source", "alias", "unalias", "test", "true", "false", "echo", "printf", "read", "cd", "pwd", "exit", "break", "continue", "set", "unset", "trap", "ls", "cp", "mv", "rm", "mkdir", "rmdir", "cat", "grep", "sed", "awk", "cut", "sort", "find", "which", "whereis", "chmod", "chown", "chgrp", "ps", "kill", "top", "jobs", "bg", "fg", "tar", "gzip", "gunzip", "zip", "unzip", "curl", "wget", "ssh", "scp", "rsync", "git", "docker", "make", "PATH", "HOME", "USER", "SHELL", "PWD" }
    },
    c = {
      hl = "Function",
      unique_words = { "restrict", "_Bool", "_Complex", "_Atomic" },
      words = { "int", "void", "char", "float", "double", "long", "short", "unsigned", "signed", "struct", "union", "enum", "typedef", "if", "else", "for", "while", "do", "switch", "case", "default", "return", "break", "continue", "goto", "sizeof", "const", "static", "extern", "auto", "register", "volatile", "inline", "restrict", "_Alignas", "_Alignof", "_Atomic", "_Bool", "_Complex", "_Generic", "_Imaginary", "_Noreturn", "_Static_assert", "_Thread_local", "include", "define", "ifdef", "ifndef", "endif", "pragma", "NULL", "true", "false", "size_t", "FILE", "EOF" }
    },
    clojure = {
      hl = "Function",
      unique_words = { "defn", "recur", "deref", "conj" },
      words = { "defn", "def", "defmacro", "ns", "let", "if", "when", "cond", "case", "do", "loop", "recur", "fn", "require", "import", "true", "false", "nil", "and", "or", "not", "atom", "swap", "reset", "deref", "map", "filter", "reduce", "conj", "cons", "first", "rest", "quote" }
    },
    cpp = {
      hl = "Function",
      unique_words = { "class", "namespace", "template", "typename", "public", "private", "protected", "virtual", "override", "nullptr", "operator", "new", "delete", "this", "try", "catch", "throw", "constexpr", "decltype", "concept", "requires" },
      words = { "class", "namespace", "template", "typename", "using", "public", "private", "protected", "friend", "virtual", "override", "final", "abstract", "operator", "new", "delete", "this", "try", "catch", "throw", "noexcept", "explicit", "mutable", "constexpr", "decltype", "static_cast", "dynamic_cast", "const_cast", "reinterpret_cast", "nullptr", "auto", "decltype", "constexpr", "static_assert", "thread_local", "alignas", "alignof", "concept", "requires", "co_await", "co_return", "co_yield", "int", "void", "char", "float", "double", "long", "short", "unsigned", "signed", "struct", "union", "enum", "typedef", "bool", "true", "false", "if", "else", "for", "while", "do", "switch", "case", "default", "return", "break", "continue", "goto", "const", "static", "extern", "register", "volatile", "inline", "sizeof", "std", "vector", "string", "map", "set", "list", "deque", "shared_ptr", "unique_ptr", "weak_ptr" }
    },
    csharp = {
      hl = "Function",
      unique_words = { "foreach", "delegate", "sealed", "internal", "Console" },
      words = { "using", "namespace", "class", "struct", "interface", "enum", "delegate", "event", "public", "private", "protected", "internal", "static", "sealed", "abstract", "virtual", "override", "readonly", "const", "int", "long", "double", "float", "decimal", "bool", "string", "char", "byte", "void", "var", "if", "else", "for", "foreach", "while", "do", "switch", "case", "default", "break", "continue", "return", "try", "catch", "finally", "throw", "new", "this", "base", "async", "await", "get", "set", "true", "false", "null", "Console", "List", "Dictionary", "IEnumerable", "Task" }
    },
    css = {
      hl = "Type",
      unique_words = { "keyframes", "rgba", "important" },
      words = { "display", "position", "flex", "grid", "float", "clear", "width", "height", "margin", "padding", "border", "color", "background", "font", "text", "align", "block", "inline", "absolute", "relative", "fixed", "sticky", "none", "auto", "inherit", "initial", "media", "import", "keyframes", "supports", "hover", "focus", "active", "before", "after", "nth", "child", "calc", "var", "rgba", "rgb", "url", "important" }
    },
    dart = {
      hl = "Function",
      unique_words = { "mixin", "covariant", "late", "Future" },
      words = { "void", "var", "final", "const", "class", "extends", "implements", "mixin", "with", "static", "get", "set", "factory", "required", "covariant", "late", "if", "else", "for", "while", "do", "switch", "case", "default", "break", "continue", "return", "try", "catch", "finally", "throw", "this", "super", "new", "async", "await", "Future", "Stream", "import", "library", "part", "null", "true", "false" }
    },
    elixir = {
      hl = "Function",
      unique_words = { "defmodule", "defp", "defmacro", "defstruct", "spawn" },
      words = { "def", "defmodule", "defp", "defmacro", "defstruct", "defprotocol", "do", "end", "if", "unless", "else", "case", "cond", "when", "fn", "receive", "spawn", "send", "import", "alias", "require", "use", "module", "true", "false", "nil", "and", "or", "not", "in", "quote", "unquote" }
    },
    go = {
      hl = "Function",
      unique_words = { "func", "chan", "defer", "go", "range", "fallthrough", "select", "package", "iota", "rune", ":=", "<-" },
      words = { "int", "int8", "int16", "int32", "int64", "uint", "uint8", "uint16", "uint32", "uint64", "uintptr", "float32", "float64", "complex64", "complex128", "bool", "byte", "rune", "string", "error", "type", "struct", "interface", "if", "else", "for", "range", "switch", "case", "default", "return", "break", "continue", "goto", "fallthrough", "select", "func", "var", "const", "go", "defer", "chan", "package", "import", "make", "new", "len", "cap", "append", "copy", "delete", "panic", "recover", "close", "true", "false", "nil", "iota", "map", "slice", ":=", "...", "<-", "->", "==", "!=", "<=", ">=", "++", "--", "&&", "||" }
    },
    groovy = {
      hl = "Function",
      unique_words = { "println", "findAll", "GString" },
      words = { "def", "class", "interface", "extends", "implements", "static", "private", "public", "protected", "if", "else", "for", "while", "do", "switch", "case", "default", "break", "continue", "return", "try", "catch", "finally", "throw", "this", "super", "new", "import", "package", "true", "false", "null", "closure", "it", "each", "collect", "findAll", "println", "GString" }
    },
    haskell = {
      hl = "Function",
      unique_words = { "newtype", "deriving", "Nothing", "Maybe", "foldr", "foldl" },
      words = { "module", "import", "where", "data", "type", "newtype", "class", "instance", "deriving", "if", "then", "else", "case", "of", "let", "in", "do", "True", "False", "Nothing", "Just", "IO", "Maybe", "Either", "Int", "Integer", "Char", "String", "Bool", "map", "filter", "foldr", "foldl", "return" }
    },
    html = {
      hl = "Statement",
      unique_words = { "DOCTYPE", "textarea", "placeholder", "thead", "tbody" },
      words = { "html", "head", "body", "title", "meta", "link", "script", "style", "div", "span", "header", "footer", "nav", "main", "section", "article", "aside", "p", "a", "ul", "ol", "li", "table", "tr", "td", "th", "thead", "tbody", "h1", "h2", "h3", "h4", "h5", "h6", "form", "input", "button", "label", "select", "option", "textarea", "img", "video", "audio", "canvas", "svg", "class", "id", "href", "src", "alt", "type", "name", "value", "placeholder", "DOCTYPE" }
    },
    java = {
      hl = "Function",
      unique_words = { "implements", "throws", "synchronized", "volatile", "transient", "ArrayList" },
      words = { "int", "long", "double", "float", "boolean", "char", "byte", "short", "void", "class", "interface", "enum", "extends", "implements", "public", "private", "protected", "static", "final", "abstract", "if", "else", "for", "while", "do", "switch", "case", "default", "break", "continue", "return", "try", "catch", "finally", "throw", "throws", "new", "this", "super", "instanceof", "import", "package", "synchronized", "volatile", "transient", "true", "false", "null", "String", "Integer", "Long", "Double", "Boolean", "System", "List", "ArrayList", "Map", "HashMap", "Override" }
    },
    javascript = {
      hl = "Function",
      unique_words = { "console", "document", "window", "NaN", "Infinity", "globalThis" },
      words = { "var", "let", "const", "function", "class", "if", "else", "for", "while", "do", "break", "continue", "return", "switch", "case", "default", "try", "catch", "finally", "throw", "new", "this", "super", "extends", "static", "get", "set", "constructor", "typeof", "instanceof", "delete", "in", "of", "void", "async", "await", "yield", "Promise", "import", "export", "from", "as", "require", "module", "exports", "true", "false", "null", "undefined", "NaN", "Infinity", "console", "document", "window", "globalThis", "JSON", "Object", "Array", "Math", "Date", "RegExp", "Error", "Map", "Set" }
    },
    json = {
      hl = "Constant",
      words = { "true", "false", "null" }
    },
    kotlin = {
      hl = "Function",
      unique_words = { "fun", "companion", "lateinit", "suspend" },
      words = { "fun", "val", "var", "class", "object", "interface", "enum", "private", "public", "protected", "internal", "open", "abstract", "override", "companion", "if", "else", "for", "while", "do", "when", "break", "continue", "return", "try", "catch", "finally", "throw", "this", "super", "init", "constructor", "is", "as", "in", "out", "null", "true", "false", "suspend", "lateinit", "lazy", "import", "package" }
    },
    llvm = {
      hl = "Function",
      unique_words = { "getelementptr", "phi", "alloca", "icmp", "fcmp", "zext", "sext", "trunc", "ptrtoint", "inttoptr", "i1", "i128", "metadata", "undef", "extractvalue", "insertvalue", "landingpad", "invoke", "resume" },
      words = { "void", "i1", "i8", "i16", "i32", "i64", "i128", "half", "float", "double", "fp128", "x86_fp80", "ppc_fp128", "ptr", "label", "token", "metadata", "type", "opaque", "private", "internal", "external", "linkonce", "weak", "common", "appending", "extern_weak", "linkonce_odr", "weak_odr", "default", "hidden", "protected", "ccc", "fastcc", "coldcc", "cc", "define", "declare", "nounwind", "readonly", "readnone", "noreturn", "nocapture", "noinline", "alwaysinline", "optsize", "ssp", "sspreq", "ret", "br", "switch", "indirectbr", "invoke", "resume", "unreachable", "add", "fadd", "sub", "fsub", "mul", "fmul", "udiv", "sdiv", "fdiv", "urem", "srem", "frem", "shl", "lshr", "ashr", "and", "or", "xor", "alloca", "load", "store", "getelementptr", "fence", "cmpxchg", "atomicrmw", "trunc", "zext", "sext", "fptrunc", "fpext", "fptoui", "fptosi", "uitofp", "sitofp", "ptrtoint", "inttoptr", "bitcast", "addrspacecast", "icmp", "fcmp", "eq", "ne", "ugt", "uge", "ult", "ule", "sgt", "sge", "slt", "sle", "oeq", "ogt", "oge", "olt", "ole", "one", "ord", "ueq", "ugt", "uge", "ult", "ule", "une", "uno", "phi", "select", "call", "va_arg", "landingpad", "extractvalue", "insertvalue", "extractelement", "insertelement", "shufflevector", "global", "constant", "null", "undef", "true", "false", "to", "align", "entry", "label", "zeroext", "signext", "inreg", "byval", "sret", "noalias", "nest", "returned" }
    },
    lua = {
      hl = "Function",
      unique_words = { "then", "elseif", "end", "repeat", "until", "local", "nil", "ipairs", "pairs" },
      words = { "if", "then", "else", "elseif", "end", "for", "while", "do", "repeat", "until", "break", "return", "goto", "function", "local", "in", "and", "or", "not", "true", "false", "nil", "require", "module", "print", "pairs", "ipairs", "type", "tonumber", "tostring", "next", "setmetatable", "getmetatable", "table", "string", "math", "io", "os", "debug", "goto" }
    },
    perl = {
      hl = "Function",
      unique_words = { "bless", "wantarray", "qw", "die" },
      words = { "my", "our", "local", "sub", "package", "if", "elsif", "unless", "else", "while", "until", "for", "foreach", "do", "return", "use", "require", "print", "shift", "push", "pop", "splice", "defined", "undef", "ref", "bless", "die", "eval", "wantarray", "qw" }
    },
    php = {
      hl = "Function",
      unique_words = { "echo", "require_once", "include_once", "self", "parent", "isset" },
      words = { "function", "class", "interface", "trait", "extends", "implements", "public", "private", "protected", "static", "abstract", "final", "const", "var", "if", "else", "elseif", "for", "foreach", "as", "while", "do", "switch", "case", "default", "break", "continue", "return", "try", "catch", "finally", "throw", "new", "this", "self", "parent", "namespace", "use", "require", "require_once", "include", "include_once", "echo", "print", "true", "false", "null", "array", "isset", "unset", "empty", "global", "and", "or", "xor", "not" }
    },
    powershell = {
      hl = "Function",
      unique_words = { "param", "trap" },
      words = { "function", "param", "class", "enum", "begin", "process", "end", "if", "elseif", "else", "foreach", "while", "do", "switch", "default", "break", "continue", "return", "try", "catch", "finally", "throw", "trap", "true", "false", "null" }
    },
    python = {
      hl = "Function",
      unique_words = { "def", "elif", "pass", "lambda", "self", "cls", "nonlocal", "yield", "__init__", "__str__", "__repr__", "enumerate" },
      words = { "if", "elif", "else", "for", "while", "break", "continue", "pass", "return", "def", "class", "lambda", "self", "cls", "import", "from", "as", "try", "except", "finally", "raise", "with", "and", "or", "not", "in", "is", "True", "False", "None", "global", "nonlocal", "async", "await", "del", "yield", "assert", "int", "float", "str", "bool", "list", "dict", "tuple", "set", "range", "len", "print", "input", "open", "file", "iter", "next", "enumerate", "zip", "map", "filter", "type", "isinstance", "issubclass", "property", "staticmethod", "classmethod", "__init__", "__str__", "__repr__" }
    },
    r = {
      hl = "Function",
      unique_words = { "sapply", "lapply", "vapply", "mapply", "ifelse" },
      words = { "function", "if", "else", "for", "while", "repeat", "break", "next", "return", "TRUE", "FALSE", "NULL", "NA", "NaN", "Inf", "library", "require", "print", "cat", "c", "list", "vector", "matrix", "apply", "sapply", "lapply", "vapply", "mapply", "environment", "assign", "ifelse" }
    },
    ruby = {
      hl = "Function",
      unique_words = { "elsif", "unless", "attr_accessor", "attr_reader", "retry", "redo" },
      words = { "def", "end", "class", "module", "if", "elsif", "else", "unless", "while", "until", "for", "in", "do", "begin", "rescue", "ensure", "raise", "retry", "redo", "case", "when", "then", "break", "next", "return", "self", "super", "yield", "require", "require_relative", "attr_accessor", "attr_reader", "attr_writer", "puts", "print", "p", "nil", "true", "false", "and", "or", "not", "lambda", "proc" }
    },
    rust = {
      hl = "Function",
      unique_words = { "fn", "mut", "impl", "trait", "match", "loop", "crate", "i8", "i16", "i32", "i64", "i128", "isize", "u8", "u16", "u32", "u64", "u128", "usize", "dyn", "unsafe" },
      words = { "i8", "i16", "i32", "i64", "i128", "isize", "u8", "u16", "u32", "u64", "u128", "usize", "f32", "f64", "bool", "char", "str", "type", "struct", "enum", "union", "trait", "impl", "if", "else", "match", "loop", "while", "for", "in", "return", "break", "continue", "fn", "mod", "pub", "use", "crate", "extern", "let", "mut", "const", "static", "ref", "move", "as", "async", "await", "unsafe", "dyn", "where", "Self", "self", "super", "true", "false", "None", "Some", "Ok", "Err", "Vec", "String", "Box", "Rc", "Arc", "Option", "Result", "Copy", "Clone", "Send", "Sync", "Drop" }
    },
    scala = {
      hl = "Function",
      unique_words = { "trait", "implicit", "object" },
      words = { "def", "val", "var", "class", "object", "trait", "extends", "with", "private", "protected", "override", "abstract", "final", "implicit", "lazy", "if", "else", "for", "while", "do", "match", "case", "return", "try", "catch", "finally", "throw", "this", "super", "new", "yield", "null", "true", "false", "import", "package" }
    },
    sql = {
      hl = "Statement",
      unique_words = { "SELECT", "INSERT", "DELETE", "JOIN", "HAVING" },
      words = { "SELECT", "FROM", "WHERE", "JOIN", "INNER", "LEFT", "RIGHT", "OUTER", "ON", "GROUP", "BY", "ORDER", "HAVING", "DISTINCT", "AS", "LIMIT", "OFFSET", "UNION", "INSERT", "INTO", "VALUES", "UPDATE", "SET", "DELETE", "CREATE", "TABLE", "ALTER", "DROP", "INDEX", "PRIMARY", "KEY", "FOREIGN", "REFERENCES", "UNIQUE", "DEFAULT", "AND", "OR", "NOT", "IN", "BETWEEN", "LIKE", "EXISTS", "NULL", "CASE", "WHEN", "THEN", "END" }
    },
    swift = {
      hl = "Function",
      unique_words = { "guard", "fileprivate", "unowned", "deinit" },
      words = { "func", "var", "let", "class", "struct", "enum", "protocol", "extension", "private", "public", "internal", "fileprivate", "open", "static", "lazy", "weak", "unowned", "if", "else", "guard", "for", "while", "repeat", "switch", "case", "default", "break", "continue", "return", "try", "catch", "throw", "throws", "do", "defer", "this", "self", "super", "init", "deinit", "override", "nil", "true", "false", "import" }
    },
    typescript = {
      hl = "Function",
      unique_words = { "interface", "namespace", "readonly", "typeof", "instanceof", "undefined", "debugger", "const", "let", "async", "await", "Promise" },
      words = { "number", "string", "boolean", "symbol", "bigint", "object", "any", "unknown", "never", "void", "type", "interface", "enum", "namespace", "readonly", "public", "private", "protected", "abstract", "static", "if", "else", "switch", "case", "default", "for", "while", "do", "break", "continue", "return", "try", "catch", "finally", "throw", "function", "class", "constructor", "extends", "implements", "super", "this", "new", "var", "let", "const", "async", "await", "Promise", "import", "export", "default", "from", "as", "require", "module", "typeof", "instanceof", "in", "of", "delete", "true", "false", "null", "undefined", "debugger", "with", "yield", "Array", "Map", "Set", "WeakMap", "WeakSet", "Date", "RegExp", "Error" }
    },
    vim = {
      hl = "Statement",
      unique_words = { "endif", "endfor", "endwhile", "endfunction", "endtry", "augroup", "doautocmd", "echom", "echoerr", "echohl", "nnoremap", "vnoremap", "inoremap", "xnoremap", "onoremap", "tnoremap", "cnoremap", "setlocal", "setglobal", "unlet", "delcommand", "luaeval", "feedkeys" },
      words = { "if", "else", "elseif", "endif", "for", "in", "endfor", "while", "endwhile", "do", "break", "continue", "return", "try", "catch", "finally", "endtry", "throw", "let", "const", "unlet", "set", "setlocal", "setglobal", "call", "execute", "eval", "echo", "echom", "echon", "echohl", "echoerr", "silent", "silentm", "unsilent", "normal", "normal!", "function", "endfunction", "abort", "closure", "command", "delcommand", "autocmd", "augroup", "doautocmd", "highlight", "syntax", "map", "noremap", "unmap", "nmap", "nnoremap", "nnoremenu", "vmap", "vnoremap", "xmap", "xnoremap", "imap", "inoremap", "omap", "onoremap", "tmap", "tnoremap", "cmap", "cnoremap", "source", "runtime", "finish", "sign", "wincmd", "tabdo", "bufdo", "argdo", "v:true", "v:false", "v:null", "v:none", "has", "exists", "expand", "fnamemodify", "resolve", "shellescape", "fnameescape", "system", "systemlist", "bufnr", "bufexists", "bufloaded", "buflisted", "winnr", "winbufnr", "win_getid", "win_gotoid", "tabpagenr", "tabpagebuflist", "line", "col", "virtcol", "indent", "getline", "setline", "append", "delete", "getpos", "setpos", "getcurpos", "cursor", "search", "searchpos", "match", "matchstr", "matchend", "substitute", "submatch", "split", "join", "trim", "tolower", "toupper", "strlen", "strchars", "strdisplaywidth", "strpart", "strcharpart", "printf", "string", "nr2char", "char2nr", "len", "empty", "type", "get", "has_key", "keys", "values", "items", "filter", "map", "sort", "reverse", "copy", "deepcopy", "extend", "remove", "insert", "index", "count", "abs", "ceil", "floor", "float2nr", "pow", "sqrt", "round", "max", "min", "range", "readfile", "writefile", "glob", "globpath", "isdirectory", "filereadable", "input", "inputlist", "confirm", "feedkeys", "getchar", "getcharstr", "mode", "visualmode", "reg_executing", "getreg", "setreg", "synID", "synIDattr", "synstack", "hlID", "sign_define", "sign_place", "sign_unplace", "luaeval", "json_encode", "json_decode" }
    },
    zig = {
      hl = "Function",
      unique_words = { "comptime", "errdefer", "orelse", "anytype", "anyerror", "anyframe", "noreturn", "unreachable", "linksection", "callconv", "allowzero", "nosuspend", "usize", "isize" },
      words = { "i8", "i16", "i32", "i64", "i128", "u8", "u16", "u32", "u64", "u128", "f16", "f32", "f64", "f80", "f128", "bool", "void", "noreturn", "type", "anyerror", "comptime_int", "comptime_float", "c_short", "c_ushort", "c_int", "c_uint", "c_long", "c_ulong", "c_longlong", "c_ulonglong", "c_longdouble", "isize", "usize", "struct", "enum", "union", "error", "opaque", "if", "else", "switch", "while", "for", "break", "continue", "return", "defer", "errdefer", "fn", "var", "const", "pub", "export", "extern", "align", "allowzero", "packed", "volatile", "linksection", "callconv", "noalias", "comptime", "inline", "noinline", "asm", "volatile", "test", "unreachable", "true", "false", "null", "undefined", "try", "catch", "orelse", "and", "or", "anytype", "anyframe", "suspend", "resume", "await", "async", "nosuspend", "threadlocal" }
    }
  },
  language_detection_threshold = 2,
  overrides = {},
  scheme = "default",
  treat_empty_fence_as_ascii = true,
  treesitter = {
    block_detection = true,
    enabled = true,
    syntax_highlight = true
  }
}


----------------------------

TSInstallInfot gibt es nicht, nur:

TSContext
TSInstall
TSInstallFromGrammar
TSLog
TSUninstall
TSUpdate

---------------------------------

C:\Windows\System32🔒 via C via 🦀 v1.95.0
❯ nvim --version
NVIM v0.12.2
Build type: Release
LuaJIT 2.1.1774638290
Run "nvim -V1 -v" for more info



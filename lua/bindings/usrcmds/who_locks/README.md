# bindings.usrcmds.who_locks

Diagnoses a Windows file lock (`EBUSY`/`EPERM`/`EACCES`) on any path.
Registers `:WhoLocks [path]` — run it right after a file operation fails
with "resource busy or locked"; it measures which process holds the file
rather than guessing.

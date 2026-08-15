# startup

Startup phase runner with built-in measurement. Replaces the previous
`vim.defer_fn(..., 10|50)` scheme — wall-clock timers were never a real
policy, since `defer_fn` can't run before the event loop goes idle, which on
this config happens ~2s after `VimEnter`.

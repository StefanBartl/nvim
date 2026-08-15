# config.lazy

lazy.nvim's own bootstrap options (`defaults.lazy = true`, etc.). Remote-managed
personal plugins need special handling here: dir-mode plugins are excluded
from `lazy-lock.json`, so nothing flags them drifting behind `origin/main`.

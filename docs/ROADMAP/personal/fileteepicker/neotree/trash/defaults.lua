---@module 'config.neotree.trash.defaults'

local TRASH_DEFAULTS = {
    debug = false,
    auto_close_buffers = true,
    create_backups = true,
    use_safety_system = true,
    confirm_dangerous = true,
    use_dry_run = false,
    quarantine_duration = 3000,
    pre_delete_wait = 200,
    post_delete_wait = 300,
}

return TRASH_DEFAULTS

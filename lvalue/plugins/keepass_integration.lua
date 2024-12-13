return {
    "custom/keepass-integration",
    lazy = false, -- Das Plugin wird direkt geladen
    config = function()
        -- Funktion zur Suche in der KeePass-Datenbank
        local function search_keepass()
            local entry = vim.fn.input("Enter search term: ")
            -- Aufruf von keepassxc-cli zum Abrufen von Ergebnissen (angepasster Pfad für WSL)
            local handle = io.popen(
            "keepassxc-cli ls '/mnt/c/Users/22bartls/OneDrive - Österreichischer Gewerkschaftsbund/Dokumente/lvalue.kdbx' --keyfile /mnt/c/Pfad/zur/keyfile.key | grep " ..
            entry)
            local result = handle:read("*a")
            handle:close()

            -- Zeige die Ergebnisse in Telescope an
            require('telescope.builtin').grep_string({ search = result })
        end

        -- NVChad spezifische Keymap
        local map = {
            n = {
                ["<leader>pw"] = {
                    function() search_keepass() end,
                    "Search KeePass entries",
                },
            },
        }

        -- Verwende die NVChad-Utility-Funktion, um die Mappings zu laden
        require("core.utils").load_mappings(map)
    end,
}

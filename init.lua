local vim = vim


function TelemuxStart()
    local M = {}
    local to_load = {
        'telemux.assets',
    }

    -- load all dependencies in `to_load` into the module
    for _, tbl in ipairs(to_load) do
        local t = require(tbl)
        for k, v in pairs(t) do
            M[k] = v
        end
    end

    -- set up keymappings
    require('telemux.keymap').setup(M)

    M.attach_to_pane()

    return M
end


vim.keymap.set('n', '<leader>ta', function() TelemuxStart() end)

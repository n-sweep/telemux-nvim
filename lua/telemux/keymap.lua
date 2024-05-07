local vim = vim
local M = {}

function M.setup(mod)
    vim.keymap.set('n', '<leader>tta', function() mod.attach_to_pane() end)
    vim.keymap.set('n', '<leader>ttp', function() mod.ipython() end)

    -- send keys
    -- ctrl + enter runs a cell
    vim.keymap.set({'n', 'v'}, '<F33>', function() mod.send_keys() end)

    -- shift + enter runs a cell and sends the cursor to the next cell
    vim.keymap.set({'n', 'v'}, '<F34>', function() mod.send_keys() mod.goto_next_cell() end)

    -- shift + tab
    vim.keymap.set('n', '<F31>', function() mod.goto_next_cell() end)

    -- alt + tab
    vim.keymap.set('n', '<F32>', function() mod.goto_prev_cell() end)

end

return M

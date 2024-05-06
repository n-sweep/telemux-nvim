local vim = vim
local M = {}

function M.setup(mod)
    vim.keymap.set('n', '<leader>tta', function() mod.attach_to_pane() end)
    vim.keymap.set('n', '<leader>ttp', function() mod.ipython() end)

    -- send keys
    -- ctrl + enter
    vim.keymap.set('n', '<F33>', function() mod.send_keys() end)
    vim.keymap.set('i', '<F33>', function() mod.send_keys() end)
    vim.keymap.set('v', '<F33>', function() mod.send_keys() end)

    -- shift + enter
    vim.keymap.set('n', '<F34>', function() mod.send_keys() mod.goto_next_cell() end)
    vim.keymap.set('i', '<F34>', function() mod.send_keys() mod.goto_next_cell() end)
    vim.keymap.set('v', '<F34>', function() mod.send_keys() mod.goto_next_cell() end)

end

return M

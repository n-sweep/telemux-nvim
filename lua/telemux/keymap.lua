local vim = vim
local M = {}

function M.setup(mod)
    vim.keymap.set('n', '<leader>tp', function() mod.ipython() end)

    -- send keys
    -- ctrl + enter
    vim.keymap.set('n', '<F33>', function() mod.send_keys(false) end)
    vim.keymap.set('v', '<F33>', function() mod.send_keys(true) end)

    -- shift + enter
    vim.keymap.set('n', '<F34>', function() mod.send_keys(false, true) end)
end

return M

local vim = vim
local M = {}
local filetypes = {
    python = {
        delimiter = '# %%',
        comment = '#',
    },
    markdown = {
        delimiter = '```',
        comment = '#',
    },
    quarto = {
        delimiter = '```',
        comment = '#', -- [TODO] is this right?
    }
}

PANE_ID = ''


local function tmux_list_panes()
    -- read the output of tmux list-panes
    local f = io.popen("tmux list-panes")
    if f then
        local panes = f:read("*a")

        -- we need to be able to map both directions
        -- gather table of pane numbers : pane ids
        --                      and ids : numbers
        local output = {}
        for line in panes:gmatch("[^\r\n]+") do
            output[line:match("^%d+")] = line:match("%%%d+")
            output[line:match("%%%d+")] = line:match("^%d+")
        end

        return output
    end
end


-- get pane ID by pane number
local function get_tmux_pane_id(num)
    return tmux_list_panes()[num]
end


-- get pane number by pane ID
local function get_tmux_pane_num(id)
    return tmux_list_panes()[id]
end


-- generate tmux send-keys command
local function generate_command(keys, flags)
    flags = flags or ''
    local pane = get_tmux_pane_num(PANE_ID)
    return 'silent !tmux send -' .. flags .. 't '.. pane .. ' ' .. keys
end


local function process_text(text)
    -- escape special characters before sending the command to vim
    -- gotta sub the escape char first \\
    for _, k in ipairs({ '\\', '%%', '"', '!', '#', '%$', '`' }) do
        text = text:gsub(k, '\\' .. k)
    end
    -- surround with quotes before sending the command to vim
    return '"' .. text .. '"'
end


local function process_lines(lines, filetype)
    local comment_char = filetypes[filetype]['comment']
    local output = {}

    for _, str in ipairs(lines) do

        -- flag to remove commented lines
         local comment = string.match(str, '^%s*' .. comment_char)

        -- flag to remove empty lines
         local empty = string.match(str, "^%s*$")

        if not comment and not empty then
            local processed = process_text(str)
            table.insert(output, processed)
        end

    end

    if filetype == 'python' and #output > 0 then
        if string.match(output[#output], "^\"[%s\t]+") ~= nil then
            -- adding two empty lines to close an indented block
            table.insert(output, "")
        end
    end

    return output
end


local function get_current_cell(div)
    -- find cell divider above cursor
    if vim.fn.getline("."):find(div) ~= nil then
        return vim.api.nvim_win_get_cursor(0)[1]
    else
        return vim.fn.search(div, 'nbW')
    end
end


local function get_next_cell(div)
    return vim.fn.search(div, 'nW')
end


local function goto_next_cell(div)
    vim.api.nvim_win_set_cursor(0, {get_next_cell(div), 0})
end


local function get_lines_within_cell(div)

    -- find cell divider above cursor
    local cstart = get_current_cell(div)

    -- find cell divider below cursor
    local cend = get_next_cell(div)

    -- if cend is zero (last cell), replace with the end of the buffer
    if cend < 1 then
        cend = vim.fn.line("$")
    end

    return vim.fn.getline(cstart + 1, cend - 1)
end


local function get_selected_lines()
    local vstart = vim.fn.getpos("v")
    local vend = vim.fn.getpos(".")

    -- if the selection was made backward, flip start and end
    if vstart[2] > vend[2] then
        vend = vim.fn.getpos("v")
        vstart = vim.fn.getpos(".")
    end

    return vim.fn.getline(vstart[2], vend[2])
end


local function get_lines(selection, delimiter)
    -- prioritize selection first
    if selection then
        return get_selected_lines()
    -- if in a supported file, return the whole cell
    elseif delimiter then
        return get_lines_within_cell(delimiter)
    -- otherwise, just return the one line
    else
        return {vim.fn.getline('.')}
    end
end


local function execute_lines(lines)
    for _, text in ipairs(lines) do
        -- convert text into a tmux send-keys command
        local command = generate_command(text, 'l')
        -- send command text
        vim.cmd(command)
        -- send carriage return
        vim.cmd(generate_command('Enter'))
    end
end


-- attach to pane by id
function M.attach_to_pane()
    local p = nil
    repeat
        vim.cmd('silent !tmux display-panes -Nbd 0')
        print('Attach to pane')
        local n = vim.fn.getchar()
        p = vim.fn.nr2char(n)
        PANE_ID = get_tmux_pane_id(p)
    until PANE_ID ~= nil
    vim.cmd('redraw')
    print('Attached to pane ' .. p .. ' (' .. PANE_ID .. ')')
end


function M.ipython()
    local tbl = {
        'ipython --no-autoindent',
        '%load_ext autoreload',
        '%autoreload 2',
        'clear'
    }

    execute_lines(process_lines(tbl, 'python'))
end


function M.send_keys(selection, cell_increment)
    local filetype = vim.bo.filetype
    local delimiter = filetypes[filetype]['delimiter']

    if PANE_ID == '' then
        M.attach_to_pane()
    end

    -- get lines to be sent to vim
    local lines = get_lines(selection, delimiter)
    local processed_lines = process_lines(lines, filetype)

    execute_lines(processed_lines)

    if selection then
        -- exit select mode
        vim.api.nvim_input('<Esc>')
    end

    if cell_increment then
        goto_next_cell(delimiter)
    end

end

return M

local u = require 'HexEditor.utils'

local namespace_id = vim.api.nvim_create_namespace('hex_highlight')
local augroup_hex_editor = vim.api.nvim_create_augroup('hex_editor', { clear = true })

-- For example:
-- 00000000: 34 00 00 00 00 00 00 00 E9 01 00 00 00 00 00 00  4...............
--           ^
-- Would return: 0, 60
local calculate_text_position = function(row, col)
    local text_row = row - 1
    -- NOTE: Only move after space
    local text_col = 60 + math.floor((col - 13) / 3)
    -- print(text_row, text_col)
    return text_row, text_col
end

local function highlight_corresponding_text()
    -- Clear the previous highlight
    vim.api.nvim_buf_clear_namespace(0, namespace_id, 0, -1)
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    -- Calculate the corresponding position in the text representation
    -- This will depend on how your hex editor is structured
    local text_row, text_col = calculate_text_position(row, col)
    -- Highlight the corresponding position in the text representation
    vim.api.nvim_buf_add_highlight(0, namespace_id, 'HexEditorHighlight', text_row, text_col, text_col + 1)
end

local function setup_highlight()
    -- print("Setting up highlighting for HexEditor...")
    vim.api.nvim_create_autocmd({ 'CursorMoved' },
        { group = augroup_hex_editor, callback = highlight_corresponding_text })

    vim.cmd('highlight HexEditorHighlight cterm=reverse gui=reverse')
end

local M = {}

local augroup_hex_editor = vim.api.nvim_create_augroup('hex_editor', { clear = true })

M.config = {
    dump_cmd = 'xxd -g 1 -u',
    assemble_cmd = 'xxd -r',
    is_file_binary_pre_read = function()
        local binary_ext = { 'out', 'bin', 'png', 'jpg', 'jpeg', 'exe', 'dll', 'pak', 'so', 'a' }
        -- only work on normal buffers
        if vim.bo.ft ~= "" then return false end
        -- check -b flag
        if vim.bo.bin then return true end
        -- check ext within binary_ext
        local filename = vim.fn.expand('%:t')
        local ext = vim.fn.expand('%:e')
        if vim.tbl_contains(binary_ext, ext) then return true end
        -- none of the above
        return false
    end,
    is_file_binary_post_read = function()
        local encoding = (vim.bo.fenc ~= '' and vim.bo.fenc) or vim.o.enc
        if encoding ~= 'utf-8' then return true end
        return false
    end,
}

M.dump = function()
    if not vim.b.hex then
        u.dump_to_hex(M.config.dump_cmd)
    else
        vim.notify('already dumped!', vim.log.levels.WARN)
    end
end

M.assemble = function()
    if vim.b.hex then
        u.assemble_from_hex(M.config.assemble_cmd)
    else
        vim.notify('already assembled!', vim.log.levels.WARN)
    end
end

M.toggle = function()
    if not vim.b.hex then
        M.dump()
    else
        M.assemble()
    end
end

local setup_auto_cmds = function()
    vim.api.nvim_create_autocmd({ 'BufReadPre' }, {
        group = augroup_hex_editor,
        callback = function()
            if M.config.is_file_binary_pre_read() then
                vim.b.hex = true
            end
        end
    })

    vim.api.nvim_create_autocmd({ 'BufReadPost' }, {
        group = augroup_hex_editor,
        callback = function()
            if vim.b.hex then
                u.dump_to_hex(M.config.dump_cmd)
            elseif M.config.is_file_binary_post_read() then
                vim.b.hex = true
                u.dump_to_hex(M.config.dump_cmd)
            end
        end
    })

    vim.api.nvim_create_autocmd({ 'BufWritePre' }, {
        group = augroup_hex_editor,
        callback = function()
            if vim.b.hex then
                u.begin_patch_from_hex(M.config.assemble_cmd)
            end
        end
    })

    vim.api.nvim_create_autocmd({ 'BufWritePost' }, {
        group = augroup_hex_editor,
        callback = function()
            if vim.b.hex then
                u.finish_patch_from_hex(M.config.dump_cmd)
            end
        end
    })
end

M.setup = function(options)
    -- print("Initializing HexEditor!")
    M.config = vim.tbl_deep_extend("force", M.config, options or {})

    local dump_program = vim.fn.split(M.config.dump_cmd)[1]
    local assemble_program = vim.fn.split(M.config.assemble_cmd)[1]

    if not u.is_program_executable(dump_program) then return end
    if not u.is_program_executable(assemble_program) then return end

    vim.api.nvim_create_user_command('HexDump', M.dump, {})
    vim.api.nvim_create_user_command('HexAssemble', M.assemble, {})
    vim.api.nvim_create_user_command('HexToggle', M.toggle, {})

    setup_auto_cmds()
    setup_highlight()
end

return M

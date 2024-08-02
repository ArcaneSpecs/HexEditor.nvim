local namespace_id = vim.api.nvim_create_namespace('hex_highlight')

local augroup_hex_editor = vim.api.nvim_create_augroup('hex_editor', { clear = true })

-- For example:
-- 00000000: 34 00 00 00 00 00 00 00 E9 01 00 00 00 00 00 00  4...............
--           ^
-- Would return 0, 60
local calculate_text_position = function(row, col)
    local text_row = row - 1
    -- Only move after space
    local text_col = 60 + math.floor((col - 13) / 3)
    print(text_row, text_col)
    return text_row, text_col
end

vim.cmd('highlight HexEditorHighlight cterm=reverse gui=reverse')

local function highlight_corresponding_text()
    -- Clear the previous highlight.
    vim.api.nvim_buf_clear_namespace(0, namespace_id, 0, -1)

    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    -- Calculate the corresponding position in the text representation.
    -- This will depend on how your hex editor is structured.
    local text_row, text_col = calculate_text_position(row, col)
    -- Highlight the corresponding position in the text representation.
    vim.api.nvim_buf_add_highlight(0, namespace_id, 'HexEditorHighlight', text_row, text_col, text_col + 1)
end

vim.api.nvim_create_autocmd({ 'CursorMoved' },
    { group = augroup_hex_editor, callback = highlight_corresponding_text })


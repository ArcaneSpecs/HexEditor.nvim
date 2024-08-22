-- Original Author: Raafat Turki
--  https://github.com/RaafatTurki/hex.nvim
-- MIT License
-- Copyright © 2023 Raafat Turki <raafat.turki@proton.me>
-- Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
-- The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
-- THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

local M = {}

function M.drop_undo_history()
    local undolevels = vim.o.undolevels
    vim.o.undolevels = -1
    vim.cmd [[exe "normal a \<BS>\<Esc>"]]
    vim.o.undolevels = undolevels
end

function M.dump_to_hex(hex_dump_cmd)
    vim.bo.bin = true
    vim.b['hex'] = true
    vim.cmd([[%! ]] .. hex_dump_cmd .. " \"" .. vim.fn.expand('%:p') .. "\"")
    vim.b.hex_ft = vim.bo.ft
    vim.bo.ft = 'xxd'
    M.drop_undo_history()
    M.dettach_all_lsp_clients_from_current_buf()
    vim.bo.mod = false
end

function M.assemble_from_hex(hex_assemble_cmd)
    vim.cmd([[%! ]] .. hex_assemble_cmd)
    vim.bo.ft = vim.b.hex_ft
    M.drop_undo_history()
    vim.bo.mod = false
    vim.b['hex'] = false
end

function M.begin_patch_from_hex(hex_assemble_cmd)
    vim.b.hex_cur_pos = vim.fn.getcurpos()
    vim.cmd([[%! ]] .. hex_assemble_cmd)
end

function M.finish_patch_from_hex(hex_dump_cmd)
    vim.cmd([[%! ]] .. hex_dump_cmd)
    vim.fn.setpos('.', vim.b.hex_cur_pos)
    vim.bo.mod = true
end

function M.is_program_executable(program)
    if vim.fn.executable(program) == 1 then
        return true
    else
        vim.notify(program .. " is not installed on this system, aborting!", vim.log.levels.WARN)
        return false
    end
end

function M.dettach_all_lsp_clients_from_current_buf()
    local attached_servers = vim.lsp.get_clients({ bufnr = vim.api.nvim_get_current_buf() })
    for _, attached_server in ipairs(attached_servers) do
        attached_server.stop()
    end
end

M.RELOAD = function(...)
    return require("plenary.reload").reload_module(...)
end

M.R = function(name)
    M.RELOAD(name)
    return require(name)
end

-- Reload functions
vim.api.nvim_create_user_command("ReloadHexEditor", function()
    M.RELOAD("HexEditor")
end, {})

return M

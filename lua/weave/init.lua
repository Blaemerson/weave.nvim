local M = {}

M._start = 0

function M.get_most_specific_group()
    local link = vim.inspect_pos()['treesitter'][1]['hl_group_link']
    return link
end


function M.dec_hex()
    local col = vim.fn.col "."
    local line = vim.api.nvim_get_current_line()
    local ch = string.sub(line, col, col)

    if ch == 'a' then
        ch = '9'
    elseif ch ~= '0' and ch ~= '#' then
        ch = string.char(string.byte(ch) - 1)
    end

    vim.api.nvim_set_current_line(line:sub(1, col - 1) .. ch .. line:sub(col + 1))

    -- because nvim_set_current_line doesn't throw this event apparently
    vim.cmd.doautocmd("TextChanged")
end


function M.inc_hex()
    local col = vim.fn.col "."
    local line = vim.api.nvim_get_current_line()
    local ch = string.sub(line, col, col)

    if ch == '9' then
        ch = 'a'
    elseif ch ~= 'f' and ch ~= '#' then
        ch = string.char(string.byte(ch) + 1)
    end

    vim.api.nvim_set_current_line(line:sub(1, col - 1) .. ch .. line:sub(col + 1))

    -- because nvim_set_current_line doesn't throw this event apparently
    vim.cmd.doautocmd("TextChanged")
end


local function convert_to_hex(hl_group, attr)
    local color_code = vim.api.nvim_get_hl(0, {name = hl_group})[attr]
    local hex = string.format("#%x", color_code)
    return hex
end


local function create_color_window(color, group)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, #color, false, { color })

    local win = vim.api.nvim_open_win(buf, false, {
        relative = 'cursor',
        style = 'minimal',
        border = 'rounded',
        row = -3,
        col = -4,
        width = #color,
        height = 1
    })


    vim.api.nvim_set_current_win(win)

    vim.api.nvim_buf_set_keymap(buf, 'n', 'k', "<CMD>lua require('weave').inc_hex()<CR>", {})
    vim.api.nvim_buf_set_keymap(buf, 'n', 'j', "<CMD>lua require('weave').dec_hex()<CR>", {})
    vim.api.nvim_buf_set_keymap(buf, 'n', 'q', "<CMD>close<CR>", { silent = true })
    vim.api.nvim_buf_set_keymap(buf, 'n', '<esc>', "<CMD>close<CR>", { silent = true })
    vim.api.nvim_buf_set_keymap(buf, 'n', '<cr>', "<CMD>close<CR>", { silent = true })

    vim.api.nvim_buf_set_option(buf, "modifiable", true)
    vim.api.nvim_win_set_option(win, "sidescrolloff", 0)

    local attr = vim.api.nvim_get_hl(0, {name = group})

    -- Update the color of the highlight on change
    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
        buffer = buf,
        callback = function()
            color = vim.api.nvim_get_current_line()
            attr['fg'] = color
            vim.api.nvim_set_hl(0, group, attr)
        end
    })

    -- Make sure the buffer is deleted when user exits the window
    vim.api.nvim_create_autocmd({ "BufLeave" }, {
        buffer = buf,
        callback = function()
            vim.api.nvim_win_close(win, true)
            vim.api.nvim_buf_delete(buf, { force = true })
        end
    })
end


function M.toggle_attr(attr)
    local group = M.get_most_specific_group()
    vim.print(group)
    local hl = vim.api.nvim_get_hl(0, {name = group, link = true})

    hl[attr] = not hl[attr]
    vim.api.nvim_set_hl(0, group, hl)
end


function M.set_color()
    local group = M.get_most_specific_group()
    vim.print(group)

    -- vim.pretty_print(hl_group)
    -- if hl_group == nil then
    --   hl_group = "normal"
    -- end

    local old_color = convert_to_hex(group, "fg")

    create_color_window(old_color, group)
end


local function setup_commands()
    vim.api.nvim_create_user_command("WeaveSetColor", "lua require('weave').set_color()", {})
    vim.api.nvim_create_user_command("WeaveToggleBold", "lua require('weave').toggle_attr('bold')", {})
    vim.api.nvim_create_user_command("WeaveToggleItalic", "lua require('weave').toggle_attr('italic')", {})
    vim.api.nvim_create_user_command("WeaveToggleUnderline", "lua require('weave').toggle_attr('underline')", {})
end


function M.setup()
    local start_time = vim.loop.hrtime()

    if vim.g.weave_did_setup then
        return vim.notify(
            "weave.nvim has already been set up",
            vim.log.levels.WARN,
            { title = "weave.nvim" }
        )
    end

    vim.g.weave_did_setup = true

    if vim.fn.has("nvim-0.8.0") ~= 1 then
        return vim.notify(
            "Neovim 0.8.0+ required",
            vim.log.levels.ERROR,
            { title = "weave.nvim" }
        )
    end

    setup_commands()

    print(vim.loop.hrtime() - start_time)
end

return M

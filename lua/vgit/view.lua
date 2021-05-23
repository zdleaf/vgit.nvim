local border = require('vgit.border')

local M = {}

local vim = vim

local function highlight_with_ts(buf, ft)
    local has_ts = false
    local ts_highlight = nil
    local ts_parsers = nil
    if not has_ts then
        has_ts, _ = pcall(require, 'nvim-treesitter')
        if has_ts then
            _, ts_highlight = pcall(require, 'nvim-treesitter.highlight')
            _, ts_parsers = pcall(require, 'nvim-treesitter.parsers')
        end
    end
    if has_ts and ft and ft ~= '' then
        local lang = ts_parsers.ft_to_lang(ft);
        if ts_parsers.has_parser(lang) then
            ts_highlight.attach(buf, lang)
            return true
        end
    end
    return false
end

M.create = function(options)
    local buf = vim.api.nvim_create_buf(false, true)
    if options.lines then
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, options.lines)
    end
    if options.filetype then
        highlight_with_ts(buf, options.filetype)
    end
    if options.buf_options then
        for key, value in pairs(options.buf_options) do
            vim.api.nvim_buf_set_option(buf, key, value)
        end
    end
    if not options.title then
        options.window_props.border = options.border
    end
    local win_id = vim.api.nvim_open_win(buf, true, options.window_props)
    if options.win_options then
        for key, value in pairs(options.win_options) do
            vim.api.nvim_win_set_option(win_id, key, value)
        end
    end
    options.buf = buf
    options.win_id = win_id
    if options.border and options.title then
        local created_border = border.create(options.title, buf, win_id, options.window_props, options.border)
        options.border_win_id = created_border.win_id
        options.border_buf = created_border.bufnr
    end
    return options
end

M.add_keymap = function(buf, key, action)
    vim.api.nvim_buf_set_keymap(buf, 'n', key, string.format(':lua require("vgit").%s<CR>', action), {
        silent = true,
        noremap = true
    })
end

M.add_autocmd = function(buf, cmd, action)
    vim.api.nvim_command(
        string.format(
            'autocmd %s <buffer=%s> lua require("vgit").%s',
            cmd,
            buf,
            action
        )
    )
end

M.set_lines = function(buf, lines)
    local modifiable = vim.api.nvim_buf_get_option(buf, 'modifiable')
    if not modifiable then
        vim.api.nvim_buf_set_option(buf, 'modifiable', true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        vim.api.nvim_buf_set_option(buf, 'modifiable', false)
    else
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    end
end

return M
local utils = require('vgit.utils')
local render_settings = require('vgit.render_settings')
local DiffPreview = require('vgit.previews.DiffPreview')
local GutterBlamePreview = require('vgit.previews.GutterBlamePreview')
local HistoryPreview = require('vgit.previews.HistoryPreview')
local HunkPreview = require('vgit.previews.HunkPreview')
local BlamePreview = require('vgit.previews.BlamePreview')
local ProjectDiffPreview = require('vgit.previews.ProjectDiffPreview')
local virtual_text = require('vgit.virtual_text')
local PreviewState = require('vgit.states.PreviewState')
local buffer = require('vgit.buffer')
local sign = require('vgit.sign')
local void = require('plenary.async.async').void
local scheduler = require('plenary.async.util').scheduler

local M = {}

local preview_state = PreviewState:new()

M.constants = utils.readonly({
    blame_ns_id = vim.api.nvim_create_namespace('tanvirtin/vgit.nvim/blame'),
    blame_line_id = 1,
})

M.is_popup_navigatable = function(popup)
    local allowed = {
        DiffPreview,
        ProjectDiffPreview,
        HistoryPreview,
        HunkPreview,
    }
    for i = 1, #allowed do
        local T = allowed[i]
        if popup:is(T) then
            return true
        end
    end
    return false
end

M.get_rendered_popup = function()
    return preview_state:get()
end

M.render_blame_line = function(buf, blame, lnum, git_config)
    if buffer.is_valid(buf) then
        local virt_text = render_settings.get('line_blame').format(blame, git_config)
        if type(virt_text) == 'string' then
            pcall(virtual_text.add, buf, M.constants.blame_ns_id, lnum - 1, 0, {
                id = M.constants.blame_line_id,
                virt_text = { { virt_text, render_settings.get('line_blame').hl } },
                virt_text_pos = 'eol',
                hl_mode = 'combine',
            })
        end
    end
end

M.render_hunk_signs = void(function(buf, hunks)
    scheduler()
    if buffer.is_valid(buf) then
        for i = 1, #hunks do
            local hunk = hunks[i]
            for j = hunk.start, hunk.finish do
                sign.place(
                    buf,
                    (hunk.type == 'remove' and j == 0) and 1 or j,
                    render_settings.get('sign').hls[hunk.type],
                    render_settings.get('sign').priority
                )
                scheduler()
            end
            scheduler()
        end
    end
end)

M.render_blame_preview = void(function(fetch)
    preview_state:clear()
    local blame_preview = BlamePreview:new()
    preview_state:set(blame_preview)
    blame_preview:mount()
    scheduler()
    local err, data = fetch()
    scheduler()
    blame_preview.err = err
    blame_preview.data = data
    blame_preview:render()
    scheduler()
end)

M.render_gutter_blame_preview = void(function(fetch, filetype)
    preview_state:clear()
    local gutter_blame_preview = GutterBlamePreview:new({ filetype = filetype })
    preview_state:set(gutter_blame_preview)
    gutter_blame_preview:mount()
    gutter_blame_preview:set_loading(true)
    scheduler()
    local err, data = fetch()
    scheduler()
    gutter_blame_preview:set_loading(false)
    scheduler()
    gutter_blame_preview.err = err
    gutter_blame_preview.data = data
    gutter_blame_preview:render()
    scheduler()
end)

M.render_hunk_preview = void(function(fetch, filetype)
    preview_state:clear()
    local current_lnum = vim.api.nvim_win_get_cursor(0)[1]
    local hunk_preview = HunkPreview:new({ filetype = filetype })
    preview_state:set(hunk_preview)
    hunk_preview:mount()
    hunk_preview:set_loading(true)
    scheduler()
    local err, data = fetch()
    scheduler()
    hunk_preview:set_loading(false)
    scheduler()
    hunk_preview.err = err
    hunk_preview.data = data
    hunk_preview.selected = current_lnum
    hunk_preview:render()
    scheduler()
end)

M.render_diff_preview = void(function(fetch, filetype, layout_type)
    preview_state:clear()
    local current_lnum = vim.api.nvim_win_get_cursor(0)[1]
    local diff_preview = DiffPreview:new({
        filetype = filetype,
        layout_type = layout_type,
    })
    preview_state:set(diff_preview)
    diff_preview:mount()
    diff_preview:set_loading(true)
    scheduler()
    local err, data = fetch()
    scheduler()
    diff_preview:set_loading(false)
    scheduler()
    diff_preview.err = err
    diff_preview.data = data
    diff_preview.selected = current_lnum
    diff_preview:render()
    scheduler()
end)

M.render_history_preview = void(function(fetch, filetype, layout_type)
    preview_state:clear()
    local history_preview = HistoryPreview:new({
        filetype = filetype,
        layout_type = layout_type,
        selected = 1,
    })
    preview_state:set(history_preview)
    history_preview:mount()
    history_preview:set_loading(true)
    scheduler()
    local err, data = fetch()
    scheduler()
    history_preview:set_loading(false)
    scheduler()
    history_preview.err = err
    history_preview.data = data
    history_preview:render()
    scheduler()
end)

M.rerender_history_preview = void(function(fetch, selected)
    local history_preview = preview_state:get()
    scheduler()
    if history_preview.selected == selected then
        return
    end
    history_preview:set_loading(true)
    scheduler()
    local err, data = fetch()
    scheduler()
    history_preview:set_loading(false)
    scheduler()
    history_preview.err = err
    history_preview.data = data
    history_preview.selected = selected
    history_preview:render()
    scheduler()
end)

M.render_project_diff_preview = void(function(fetch, layout_type)
    preview_state:clear()
    local project_diff_preview = ProjectDiffPreview:new({
        layout_type = layout_type,
        selected = 1,
    })
    preview_state:set(project_diff_preview)
    project_diff_preview:mount()
    project_diff_preview:set_loading(true)
    scheduler()
    local err, data = fetch()
    scheduler()
    project_diff_preview:set_loading(false)
    scheduler()
    project_diff_preview.err = err
    project_diff_preview.data = data
    project_diff_preview:render()
    scheduler()
end)

M.rerender_project_diff_preview = void(function(fetch, selected)
    local project_diff_preview = preview_state:get()
    scheduler()
    if project_diff_preview.selected == selected then
        local data = project_diff_preview.data
        if not data then
            return
        end
        local changed_files = data.changed_files
        if not changed_files then
            return
        end
        local changed_file = changed_files[selected]
        if not changed_file then
            return
        end
        local invalid_status = {
            ['AD'] = true,
            [' D'] = true,
        }
        if invalid_status[changed_file.status] then
            return
        end
        M.hide_preview()
        vim.cmd(string.format('e %s', changed_file.filename))
        return
    end
    project_diff_preview:set_loading(true)
    scheduler()
    local err, data = fetch()
    scheduler()
    project_diff_preview:set_loading(false)
    scheduler()
    project_diff_preview.err = err
    project_diff_preview.data = data
    project_diff_preview.selected = selected
    project_diff_preview:render()
    scheduler()
end)

M.hide_blame_line = function(buf)
    if buffer.is_valid(buf) then
        pcall(virtual_text.delete, buf, M.constants.blame_ns_id, M.constants.blame_line_id)
    end
end

M.hide_hunk_signs = void(function(buf)
    scheduler()
    if buffer.is_valid(buf) then
        sign.unplace(buf)
        scheduler()
    end
end)

M.hide_preview = function()
    local preview = preview_state:get()
    if not vim.tbl_isempty(preview) then
        preview:unmount()
        preview_state:set({})
    end
end

M.hide_windows = function(wins)
    local preview = preview_state:get()
    if not vim.tbl_isempty(preview) then
        preview_state:clear()
    end
    local existing_wins = vim.api.nvim_list_wins()
    for i = 1, #wins do
        local win = wins[i]
        if vim.api.nvim_win_is_valid(win) and vim.tbl_contains(existing_wins, win) then
            pcall(vim.api.nvim_win_close, win, true)
        end
    end
end

return M
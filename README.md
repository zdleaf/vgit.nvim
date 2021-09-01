# VGit :zap:
<table>
    <tr>
        <td>
            <strong>Visual Git Plugin for Neovim to enhance your git experience.</strong>
        </tr>
    </td>
</table>

<br />

<a href="https://github.com/tanvirtin/vgit.nvim/actions?query=workflow%3ACI">
    <img src="https://github.com/tanvirtin/vgit.nvim/workflows/CI/badge.svg?branch=main" alt="CI" />
</a>
<a href="https://opensource.org/licenses/MIT">
    <img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License" />
</a>

<br />
<br />
<img src="https://user-images.githubusercontent.com/25164326/132134589-9b676b82-ddca-400c-975c-d1c3de11a30c.gif" alt="overview" />

## Supported Neovim versions:
- Neovim **>=** 0.5

## Supported Opperating System:
- linux-gnu*
- Darwin

## Prerequisites
- [Git](https://git-scm.com/)
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)

## Recommended Settings
- `vim.o.updatetime = 100` (see :help updatetime).
- `vim.wo.signcolumn = 'yes'` (see :help signcolumn)

## Installation
```lua
use {
  'tanvirtin/vgit.nvim',
  requires = {
    'nvim-lua/plenary.nvim'
  }
}
```

## Setup
You must instantiate the plugin in order for the features to work.
```lua
require('vgit').setup()
```

To embed the above code snippet in a .vim file wrap it in lua << EOF code-snippet EOF:
```lua
lua << EOF
require('vgit').setup()
EOF
```

## Advanced Setup
```lua
local vgit = require('vgit')

vgit.setup({
    hunks_enabled = true,
    blames_enabled = true,
    diff_strategy = 'index',
    diff_preference = 'vertical',
    predict_hunk_signs = true,
    predict_hunk_throttle_ms = 300,
    predict_hunk_max_lines = 50000,
    blame_line_throttle_ms = 150,
    show_untracked_file_signs = true,
    action_delay_ms = 300,
    hls = vgit.themes.tokyonight -- You can also pass in your own custom object,
    render_settings = {
        preview = {
            border = { '╭', '─', '╮', '│', '╯', '─', '╰', '│' },
            border_hl = 'VGitBorder',
            border_focus_hl = 'VGitBorderFocus',
            indicator_hl = 'VGitIndicator',
            virtual_line_nr_width = 6,
            sign = {
                priority = 10,
                hls = {
                    add = 'VGitViewSignAdd',
                    remove = 'VGitViewSignRemove',
                },
            },
        },
        sign = {
            priority = 10,
            hls = {
                add = 'VGitSignAdd',
                remove = 'VGitSignRemove',
                change = 'VGitSignChange',
            },
        },
        line_blame = {
            hl = 'VGitLineBlame',
            format = function(blame, git_config)
                local config_author = git_config['user.name']
                local author = blame.author
                if config_author == author then
                    author = 'You'
                end
                local time = os.difftime(os.time(), blame.author_time) / (24 * 60 * 60)
                local time_format = string.format('%s days ago', utils.round(time))
                local time_divisions = { { 24, 'hours' }, { 60, 'minutes' }, { 60, 'seconds' } }
                local division_counter = 1
                while time < 1 and division_counter ~= #time_divisions do
                    local division = time_divisions[division_counter]
                    time = time * division[1]
                    time_format = string.format('%s %s ago', utils.round(time), division[2])
                    division_counter = division_counter + 1
                end
                local commit_message = blame.commit_message
                if not blame.committed then
                    author = 'You'
                    commit_message = 'Uncommitted changes'
                    local info = string.format('%s • %s', author, commit_message)
                    return string.format(' %s', info)
                end
                local max_commit_message_length = 255
                if #commit_message > max_commit_message_length then
                    commit_message = commit_message:sub(1, max_commit_message_length) .. '...'
                end
                local info = string.format('%s, %s • %s', author, time_format, commit_message)
                return string.format(' %s', info)
            end,
        },
    }
})
```

## Themes
Predefined supported themes:
- [tokyonight](https://github.com/folke/tokyonight.nvim)
- [monokai](https://github.com/tanvirtin/monokai.nvim)

Colorscheme definitions can be found in `lua/vgit/themes/`, feel free to open a pull request with your own colorscheme!

## API
| Function Name | Description |
|---------------|-------------|
| setup | Sets up the plugin for success |
| toggle_buffer_hunks | Shows hunk signs on buffers/Hides hunk signs on buffers |
| toggle_buffer_blames | Enables blames feature on buffers/Disables blames feature on buffers |
| toggle_diff_preference | Switches between "horizontal" and "vertical" layout for previews |
| buffer_stage | Stages a buffer you are currently on |
| buffer_unstage | Unstages a buffer you are currently on |
| buffer_diff_preview | Opens a diff preview of the changes in the current buffer |
| buffer_staged_diff_preview | Shows staged changes in a preview window |
| buffer_hunk_preview | Gives you a view through which you can navigate and see the current hunk or other hunks |
| buffer_history_preview | Opens a buffer preview along with a table of logs, enabling users to see different iterations of the buffer in the git history |
| buffer_blame_preview | Opens a preview detailing the blame of the line that the user is currently on |
| buffer_gutter_blame_preview | Opens a preview which shows the blames related to all the lines of a buffer |
| buffer_reset | Resets the current buffer to HEAD |
| buffer_hunk_stage | Stages a hunk, if cursor is over it |
| buffer_hunk_reset | Removes the hunk from the buffer, if cursor is over it |
| project_hunks_qf | Opens a populated quickfix window with all the hunks of the project |
| project_diff_view | Opens a preview listing all the files that have been changed |
| hunk_down | Navigate downward through a hunk, this works on any view with diff highlights |
| hunk_up | Navigate upwards through a hunk, this works on any view with diff highlights |
| get_diff_base | Returns the current diff base that all diff and hunks are being compared for all buffers |
| get_diff_preference | Returns the current diff preference of the diff, the value will either be "horizontal" or "vertical" |
| get_diff_strategy | Returns the current diff strategy used to compute hunk signs and buffer preview, the value will either be "remote" or "index" |
| set_diff_base | Sets the current diff base to a different commit, going forward all future hunks and diffs for a given buffer will be against this commit |
| set_diff_preference | Sets the diff preference to your given output, the value can only be "horizontal" or "vertical" |
| set_diff_strategy | Sets the diff strategy that will be used to show hunk signs and buffer preview, the value can only be "remote" or "index" |
| show_debug_logs | Shows all errors that has occured during program execution |

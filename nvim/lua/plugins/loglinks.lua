return {
    {
        "loglinks.nvim",
        virtual = true,
        config = function()
            local config = {
                qrc_root = "C:/Users/ljuek/Work_Code/VideoEnhance/videoenhanceai/mainapp",
                filetypes = { "", "log", "txt" },
                hl_group = "Underlined",
            }

            local patterns = {
                { pattern = "([A-Za-z]:\\[^%s:]+):(%d+)", type = "windows" },
                { pattern = "(qrc:/[^%s:]+):(%d+)", type = "qrc" },
                { pattern = "(/[^%s:]+):(%d+)", type = "unix" },
            }

            local function resolve_path(path, path_type)
                if path_type == "qrc" then
                    local relative = path:gsub("^qrc:/", "")
                    return config.qrc_root .. "/" .. relative
                elseif path_type == "windows" then
                    return path:gsub("\\", "/")
                else
                    return path
                end
            end

            local function find_file_ref_at_cursor()
                local line = vim.api.nvim_get_current_line()
                local col = vim.api.nvim_win_get_cursor(0)[2] + 1

                for _, pat in ipairs(patterns) do
                    local search_start = 1
                    while true do
                        local match_start, match_end, filepath, linenum = line:find(pat.pattern, search_start)
                        if not match_start then break end

                        if col >= match_start and col <= match_end then
                            local resolved = resolve_path(filepath, pat.type)
                            return resolved, tonumber(linenum)
                        end

                        search_start = match_end + 1
                    end
                end

                return nil, nil
            end

            -- can modify this if u need, i do this because i always spawn my logs into a dedicated buffer
            -- so i want it to open in any other buffer
            local function find_target_window()
                local current_win = vim.api.nvim_get_current_win()
                local windows = vim.api.nvim_list_wins()

                for _, win in ipairs(windows) do
                    if win ~= current_win then
                        local buf = vim.api.nvim_win_get_buf(win)
                        local buftype = vim.bo[buf].buftype
                        if buftype == "" then
                            return win
                        end
                    end
                end

                for _, win in ipairs(windows) do
                    if win ~= current_win then
                        return win
                    end
                end

                return nil
            end

            local function goto_file_ref()
                local filepath, linenum = find_file_ref_at_cursor()
                if filepath and linenum then
                    if vim.fn.filereadable(filepath) == 1 then
                        local target_win = find_target_window()

                        if target_win then
                            vim.api.nvim_set_current_win(target_win)
                        else
                            vim.cmd("above split")
                        end

                        vim.cmd("edit " .. vim.fn.fnameescape(filepath))
                        vim.api.nvim_win_set_cursor(0, { linenum, 0 })
                        vim.cmd("normal! zz")
                    else
                        vim.notify("File not found: " .. filepath, vim.log.levels.WARN)
                    end
                else
                    vim.notify("No file reference under cursor", vim.log.levels.INFO)
                end
            end

            local ns_id = vim.api.nvim_create_namespace("loglinks")

            local function highlight_buffer(bufnr)
                bufnr = bufnr or vim.api.nvim_get_current_buf()
                vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

                local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
                for lnum, line in ipairs(lines) do
                    for _, pat in ipairs(patterns) do
                        local search_start = 1
                        while true do
                            local match_start, match_end = line:find(pat.pattern, search_start)
                            if not match_start then break end

                            vim.api.nvim_buf_add_highlight(
                                bufnr,
                                ns_id,
                                config.hl_group,
                                lnum - 1,
                                match_start - 1,
                                match_end
                            )

                            search_start = match_end + 1
                        end
                    end
                end
            end

            local function setup_buffer_keymaps(bufnr)
                vim.keymap.set("n", "<leader>gd", goto_file_ref, {
                    buffer = bufnr,
                    desc = "Go to file:line reference",
                })
                vim.keymap.set("n", "<CR>", goto_file_ref, {
                    buffer = bufnr,
                    desc = "Go to file:line reference",
                })
            end

            vim.api.nvim_create_user_command("LogLinksGoto", goto_file_ref, {
                desc = "Jump to file:line reference under cursor"
            })

            vim.api.nvim_create_user_command("LogLinksHighlight", function()
                highlight_buffer()
            end, { desc = "Highlight file references in current buffer" })

            vim.api.nvim_create_user_command("LogLinksSetQrcRoot", function(args)
                config.qrc_root = args.args
                vim.notify("QRC root set to: " .. config.qrc_root)
            end, { nargs = 1, complete = "dir", desc = "Set QRC root path" })

            local group = vim.api.nvim_create_augroup("LogLinks", { clear = true })

            vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
                group = group,
                callback = function(args)
                    local ft = vim.bo[args.buf].filetype
                    for _, allowed_ft in ipairs(config.filetypes) do
                        if ft == allowed_ft then
                            setup_buffer_keymaps(args.buf)
                            vim.defer_fn(function()
                                if vim.api.nvim_buf_is_valid(args.buf) then
                                    highlight_buffer(args.buf)
                                end
                            end, 100)
                            break
                        end
                    end
                end,
            })

            vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
                group = group,
                callback = function(args)
                    local ft = vim.bo[args.buf].filetype
                    for _, allowed_ft in ipairs(config.filetypes) do
                        if ft == allowed_ft then
                            highlight_buffer(args.buf)
                            break
                        end
                    end
                end,
            })

            print("LogLinks loaded - <leader>gd or <CR> to jump to file:line")
        end,
    },
}

return {
    {
        "logfilter.nvim",
        virtual = true,
        config = function()
            local config = {
                poll_interval = 300,
                input_height = 1,
                input_width = 50,
                filetypes = { "", "log", "txt" },
                close_on_leave = true,
            }

            local state = {}
            local timers = {}

            local function update_cache(bufnr)
                if not vim.api.nvim_buf_is_valid(bufnr) then return false end

                local ok, lines = pcall(vim.api.nvim_buf_get_lines, bufnr, 0, -1, false)
                if not ok then return false end

                state[bufnr] = state[bufnr] or { lines = {}, line_count = 0 }
                local s = state[bufnr]

                local changed = #lines ~= s.line_count or (lines[#lines] ~= s.lines[#s.lines])
                if changed then
                    s.lines = lines
                    s.line_count = #lines
                end

                return changed
            end

            local function filter_lines(bufnr, pattern)
                local s = state[bufnr]
                if not s or not s.lines then return {}, {} end

                if not pattern or pattern == "" then
                    local line_nums = {}
                    for i = 1, #s.lines do
                        line_nums[i] = i
                    end
                    return s.lines, line_nums
                end

                local result = {}
                local line_nums = {}
                local pat = pattern:lower()

                for i, line in ipairs(s.lines) do
                    if line:lower():find(pat, 1, true) then
                        table.insert(result, line)
                        table.insert(line_nums, i)
                    end
                end

                return result, line_nums
            end

            local function start_cache_timer(bufnr)
                local old_timer = timers[bufnr]
                if old_timer then
                    timers[bufnr] = nil
                    pcall(function()
                        old_timer:stop()
                        old_timer:close()
                    end)
                end

                update_cache(bufnr)

                local timer = vim.uv.new_timer()
                timers[bufnr] = timer

                timer:start(config.poll_interval, config.poll_interval, vim.schedule_wrap(function()
                    if timers[bufnr] ~= timer then return end

                    if not vim.api.nvim_buf_is_valid(bufnr) then
                        timers[bufnr] = nil
                        pcall(function()
                            timer:stop()
                            timer:close()
                        end)
                        return
                    end

                    local changed = update_cache(bufnr)

                    local s = state[bufnr]
                    if s and s.filter_active and s.view_buf and changed then
                        local pattern = s.current_pattern or ""
                        local filtered, line_nums = filter_lines(bufnr, pattern)
                        s.line_map = line_nums

                        if vim.api.nvim_buf_is_valid(s.view_buf) then
                            vim.api.nvim_buf_set_option(s.view_buf, "modifiable", true)
                            vim.api.nvim_buf_set_lines(s.view_buf, 0, -1, false, filtered)
                            vim.api.nvim_buf_set_option(s.view_buf, "modifiable", false)
                        end
                    end
                end))
            end

            local function stop_cache_timer(bufnr)
                local timer = timers[bufnr]
                if timer then
                    timers[bufnr] = nil
                    pcall(function()
                        timer:stop()
                        timer:close()
                    end)
                end
            end

            local function open_filter(source_bufnr)
                local s = state[source_bufnr]
                if not s then
                    update_cache(source_bufnr)
                    s = state[source_bufnr]
                end
                if not s then
                    vim.notify("No log content to filter", vim.log.levels.WARN)
                    return
                end

                s.filter_active = true
                s.original_buf = source_bufnr
                s.original_win = vim.api.nvim_get_current_win()
                s.current_pattern = ""

                s.view_buf = vim.api.nvim_create_buf(false, true)
                vim.api.nvim_buf_set_option(s.view_buf, "buftype", "nofile")
                vim.api.nvim_buf_set_option(s.view_buf, "bufhidden", "wipe")
                vim.api.nvim_buf_set_option(s.view_buf, "swapfile", false)
                vim.api.nvim_buf_set_name(s.view_buf, "[Log Filter]")

                local all_lines, line_nums = filter_lines(source_bufnr, "")
                s.line_map = line_nums
                vim.api.nvim_buf_set_lines(s.view_buf, 0, -1, false, all_lines)
                vim.api.nvim_buf_set_option(s.view_buf, "modifiable", false)

                vim.api.nvim_win_set_buf(s.original_win, s.view_buf)

                local win_width = vim.api.nvim_win_get_width(s.original_win)
                local input_width = math.min(config.input_width, win_width - 4)

                s.input_buf = vim.api.nvim_create_buf(false, true)
                vim.api.nvim_buf_set_option(s.input_buf, "buftype", "nofile")
                vim.api.nvim_buf_set_option(s.input_buf, "bufhidden", "wipe")

                local win_config = {
                    relative = "win",
                    win = s.original_win,
                    width = input_width,
                    height = config.input_height,
                    row = -3,
                    col = math.floor((win_width - input_width) / 2),
                    style = "minimal",
                    border = "rounded",
                    title = " Filter (Esc to close) ",
                    title_pos = "center",
                }

                s.input_win = vim.api.nvim_open_win(s.input_buf, true, win_config)
                vim.api.nvim_win_set_option(s.input_win, "winhl", "Normal:Normal,FloatBorder:FloatBorder")

                vim.cmd("startinsert")

                local function update_filter()
                    if not vim.api.nvim_buf_is_valid(s.input_buf) then return end
                    if not vim.api.nvim_buf_is_valid(s.view_buf) then return end

                    local lines = vim.api.nvim_buf_get_lines(s.input_buf, 0, 1, false)
                    local pattern = lines[1] or ""
                    s.current_pattern = pattern

                    local filtered, line_nums = filter_lines(source_bufnr, pattern)
                    s.line_map = line_nums

                    vim.api.nvim_buf_set_option(s.view_buf, "modifiable", true)
                    vim.api.nvim_buf_set_lines(s.view_buf, 0, -1, false, filtered)
                    vim.api.nvim_buf_set_option(s.view_buf, "modifiable", false)

                    local total = s.lines and #s.lines or 0
                    local title = string.format(" Filter: %d/%d (Esc to close) ", #filtered, total)
                    vim.api.nvim_win_set_config(s.input_win, { title = title, title_pos = "center" })
                end

                local function close_filter()
                    s.filter_active = false

                    if s.leave_group then
                        pcall(vim.api.nvim_del_augroup_by_id, s.leave_group)
                        s.leave_group = nil
                    end

                    if s.input_win and vim.api.nvim_win_is_valid(s.input_win) then
                        vim.api.nvim_win_close(s.input_win, true)
                    end

                    if s.original_win and vim.api.nvim_win_is_valid(s.original_win) then
                        vim.api.nvim_win_set_buf(s.original_win, source_bufnr)
                    end

                    s.input_win = nil
                    s.input_buf = nil
                    s.view_buf = nil
                    s.line_map = nil
                end

                local function goto_original_line()
                    if not s.line_map then return end

                    local cursor = vim.api.nvim_win_get_cursor(s.original_win)
                    local filtered_line = cursor[1]
                    local original_line = s.line_map[filtered_line]

                    if original_line then
                        close_filter()
                        vim.api.nvim_win_set_cursor(s.original_win, { original_line, 0 })
                        vim.cmd("normal! zz")
                    end
                end

                vim.keymap.set({ "i", "n" }, "<Esc>", close_filter, { buffer = s.input_buf })
                vim.keymap.set({ "i", "n" }, "<C-c>", close_filter, { buffer = s.input_buf })
                vim.keymap.set("n", "q", close_filter, { buffer = s.input_buf })

                vim.keymap.set({ "i", "n" }, "<CR>", function()
                    vim.cmd("stopinsert")
                    vim.api.nvim_set_current_win(s.original_win)
                end, { buffer = s.input_buf })

                vim.keymap.set("n", "<Esc>", close_filter, { buffer = s.view_buf })
                vim.keymap.set("n", "q", close_filter, { buffer = s.view_buf })
                vim.keymap.set("n", "i", function()
                    vim.api.nvim_set_current_win(s.input_win)
                    vim.cmd("startinsert")
                end, { buffer = s.view_buf })

                vim.keymap.set("n", "<CR>", goto_original_line, { buffer = s.view_buf })
                vim.keymap.set("n", "gf", goto_original_line, { buffer = s.view_buf })

                vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
                    buffer = s.input_buf,
                    callback = update_filter,
                })

                vim.api.nvim_create_autocmd("BufWipeout", {
                    buffer = s.input_buf,
                    once = true,
                    callback = function()
                        if s.filter_active then
                            close_filter()
                        end
                    end,
                })

                if config.close_on_leave then
                    local leave_group = vim.api.nvim_create_augroup("LogFilterLeave" .. source_bufnr, { clear = true })
                    s.leave_group = leave_group

                    vim.api.nvim_create_autocmd("WinLeave", {
                        group = leave_group,
                        callback = function()
                            if not s.filter_active then return end
                            vim.defer_fn(function()
                                if not s.filter_active then return end
                                local cur_buf = vim.api.nvim_get_current_buf()
                                if cur_buf ~= s.input_buf and cur_buf ~= s.view_buf then
                                    close_filter()
                                end
                            end, 10)
                        end,
                    })
                end
            end

            local function is_log_buffer(bufnr)
                local ft = vim.bo[bufnr].filetype
                local buftype = vim.bo[bufnr].buftype
                if buftype == "terminal" then return true end
                for _, allowed_ft in ipairs(config.filetypes) do
                    if ft == allowed_ft then return true end
                end
                return false
            end

            vim.api.nvim_create_user_command("LogFilter", function()
                local bufnr = vim.api.nvim_get_current_buf()
                if is_log_buffer(bufnr) then
                    open_filter(bufnr)
                else
                    vim.notify("Not a log buffer", vim.log.levels.WARN)
                end
            end, { desc = "Open log filter" })

            vim.keymap.set("n", "<leader>fi", function()
                local bufnr = vim.api.nvim_get_current_buf()
                if is_log_buffer(bufnr) then
                    open_filter(bufnr)
                else
                    vim.notify("Not a log buffer", vim.log.levels.WARN)
                end
            end, { desc = "Filter log buffer" })

            local group = vim.api.nvim_create_augroup("LogFilter", { clear = true })

            vim.api.nvim_create_autocmd("TermOpen", {
                group = group,
                callback = function(args)
                    start_cache_timer(args.buf)
                end,
            })

            vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
                group = group,
                callback = function(args)
                    if is_log_buffer(args.buf) and vim.bo[args.buf].buftype == "terminal" then
                        if not timers[args.buf] then
                            start_cache_timer(args.buf)
                        end
                    end
                end,
            })

            vim.api.nvim_create_autocmd("BufDelete", {
                group = group,
                callback = function(args)
                    stop_cache_timer(args.buf)
                    state[args.buf] = nil
                end,
            })

            print("LogFilter loaded - <leader>fi to filter logs")
        end,
    },
}
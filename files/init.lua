-- Editor settings

vim.opt.nu = true
vim.opt.relativenumber = true

vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.tabstop = 4
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.cindent = true
vim.opt.cinoptions = ':0l1'
vim.opt.backup = false
vim.opt.swapfile = false
vim.opt.undofile = true

vim.opt.textwidth = 100
vim.opt.formatoptions:remove('t')
vim.opt.formatoptions:remove('c')
vim.opt.colorcolumn = '101'
vim.opt.cursorline = true
vim.opt.incsearch = true
vim.opt.scrolloff = 4
vim.opt.signcolumn = 'yes'
vim.opt.termguicolors = true
vim.opt.updatetime = 50
vim.opt.wrap = false

vim.opt.autowrite = true
vim.opt.makeprg = 'jk_build'
vim.cmd([[set errorformat+=%\\s%#modified:%\\s%#%f,]])

vim.cmd('colorscheme jkellickonedark')

-- Enable autoread and set up checking triggers

vim.o.autoread = true
vim.api.nvim_create_autocmd({'FocusGained', 'BufEnter' }, {
  command = "if mode() != 'c' | checktime | endif",
  pattern = "*",
})

-- Keymaps

vim.g.mapleader = ' '

vim.keymap.set('n', '<leader>pv', vim.cmd.Ex)
vim.keymap.set('n', '<leader>,', vim.cmd.nohlsearch)

vim.keymap.set('n', '<C-y>', '6<C-y>')
vim.keymap.set('n', '<C-e>', '6<C-e>')
vim.keymap.set('n', 'n', 'nzz')
vim.keymap.set('n', 'N', 'Nzz')

vim.keymap.set({'n', 'v'}, '<leader>y', '"+y')
vim.keymap.set('n', '<leader>Y', '"+Y')

vim.keymap.set('n', '<leader>x', '<cmd>!chmod +x %<CR>', {silent = true})

vim.keymap.set('n', '<leader>u', vim.cmd.UndotreeToggle)
vim.keymap.set('n', '<leader>i', vim.cmd.cclose)

vim.keymap.set('n', '<leader>o', 'o<Esc>')
vim.keymap.set('n', '<leader>O', 'O<Esc>')

local fzf_lua = require('fzf-lua')
vim.keymap.set('n', '<leader>pf', fzf_lua.files, {})
vim.keymap.set('n', '<C-p>', fzf_lua.git_files, {})
vim.keymap.set('n', '<leader>ps', fzf_lua.live_grep, {})

vim.keymap.set('n', '<leader>gs', vim.cmd.Git)

require('gitsigns').setup()

vim.keymap.set('i', '<C-BS>', '<C-w>')
vim.keymap.set('i', '<C-h>', '<C-w>')
vim.keymap.set('i', '<C-o>', '<Esc>O')

-- curly brace shortcut
vim.keymap.set('i', '<C-u>', function ()
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2]
    if col > 0 and line:sub(col, col) == ';' then
        vim.cmd('normal! h')
    end
    vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes('{<CR>}<Esc>O', true, false, true), 'n', false)
end)

local function scroll_and_center(scroll_key)
    return function()
        vim.cmd('normal! ' .. scroll_key)
        -- Only recenter if there's enough buffer on both sides of the cursor to actually do it
        local half = math.ceil(vim.api.nvim_win_get_height(0) / 2)
        local cur = vim.fn.line('.')
        local last = vim.fn.line('$')
        if cur > half and cur <= last - half then
            vim.cmd('normal! M')
        end
    end
end
vim.keymap.set('n', '<C-u>', scroll_and_center('\21'))
vim.keymap.set('n', '<C-d>', scroll_and_center('\4'))

local ls = require('luasnip')
vim.keymap.set({"i"}, "<C-l>", function() ls.expand() end, {silent = true})
vim.keymap.set({"i", "s"}, "<C-j>", function() ls.jump(1) end, {silent = true})
vim.keymap.set({"i", "s"}, "<C-k>", function() ls.jump(-1) end, {silent = true})

vim.keymap.set('x', 'J', ":m '>+1<CR>gv=gv")
vim.keymap.set('x', 'K', ":m '<-2<CR>gv=gv")
vim.keymap.set('x', '<leader>p', '"_dP')

function make(args)
    vim.cmd('silent make! ' .. args .. ' ' .. vim.fn.shellescape(vim.fn.expand('%')))
    vim.cmd('copen')
    vim.cmd('wincmd p')
end

vim.keymap.set('n', '<leader>d', function() make('--mode=debug_slow') end)
vim.keymap.set('n', '<leader>r', function() make('--mode=debug_fast') end)

function reflow_in_tag()
    local saved_view = vim.fn.winsaveview()

    vim.cmd.normal('vit')

    local start_pos = vim.fn.getpos('v')
    local end_pos = vim.fn.getpos('.')

    if start_pos[2] < end_pos[2] then
        local start_content = vim.fn.getline(start_pos[2])
        if start_content:sub(start_pos[3], #start_content):match('^%s*$') then
            start_pos[2] = start_pos[2] + 1
            start_pos[3] = 1
        end

        local end_content = vim.fn.getline(end_pos[2])
        if end_content:sub(0, end_pos[3]):match('^%s*$') then
            end_pos[2] = end_pos[2] - 1
            end_pos[3] = math.max(1, #vim.fn.getline(end_pos[2]))
        end

        vim.cmd.normal('v')
        vim.api.nvim_win_set_cursor(0, {start_pos[2], start_pos[3] - 1})
        vim.cmd.normal('v')
        vim.api.nvim_win_set_cursor(0, {end_pos[2], end_pos[3] - 1})
    end

    vim.cmd.normal('gq')

    vim.fn.winrestview(saved_view)
end

vim.keymap.set('n', '<leader>t', reflow_in_tag);

local function rg_qflist(args)
    local cmd = {'rg', '--vimgrep'}
    vim.list_extend(cmd, args)
    local result = vim.system(cmd, {text = true}):wait()
    local lines = vim.split(result.stdout or '', '\n', {trimempty = true})
    vim.fn.setqflist({}, 'r', {lines = lines})
    vim.cmd('copen')
    vim.cmd('wincmd p')
end

vim.api.nvim_create_user_command(
    "G",
    function(opts)
        rg_qflist(opts.fargs)
    end,
    {nargs = '+'}
)

vim.api.nvim_create_user_command(
    "Gf",
    function(opts)
        local args = {'--line-regexp', '--max-count=1', '.*' .. opts.fargs[1] .. '.*'}
        vim.list_extend(args, vim.list_slice(opts.fargs, 2))
        rg_qflist(args)
    end,
    {nargs = '+'}
)

vim.keymap.set('n', '<leader>g', function()
  vim.fn.setreg('+', vim.fn.expand('%') .. ':' .. vim.fn.line('.'))
end)

-- Treesitter

vim.api.nvim_create_autocmd('FileType', {
    pattern = {'c', 'cpp', 'lua', 'objc', 'query', 'vim', 'vimdoc'},
    callback = function() vim.treesitter.start() end,
})

require('nvim-treesitter-textobjects').setup({
    select = { lookahead = true },
})

local treesitter_select = require('nvim-treesitter-textobjects.select')
vim.keymap.set({'x', 'o'}, 'ia', function()
    treesitter_select.select_textobject('@parameter.inner', 'textobjects')
end)
vim.keymap.set({'x', 'o'}, 'aa', function()
    treesitter_select.select_textobject('@parameter.outer', 'textobjects')
end)

function _G.SpecIndent()
    local lnum = vim.v.lnum
    local prev = vim.fn.prevnonblank(lnum - 1)
    if prev == 0 then return 0 end

    local sw = vim.fn.shiftwidth()
    local indent = vim.fn.indent(prev)

    -- previous line opens a block -> indent one deeper
    if vim.fn.getline(prev):match("[%{%[%(]%s*$") then
        indent = indent + sw
    end
    -- current line closes a block -> dedent one
    if vim.fn.getline(lnum):match("^%s*[%}%]%)]") then
        indent = indent - sw
    end

    return math.max(indent, 0)
end

vim.filetype.add({ extension = { spec = "myspec" } })

vim.api.nvim_create_autocmd("FileType", {
    pattern = "myspec",
    callback = function()
        vim.opt_local.cindent = false
        vim.opt_local.indentexpr = "v:lua.SpecIndent()"
        vim.opt_local.indentkeys:remove(":")
    end
})

-- LSP

vim.lsp.config('*', {
    capabilities = require('blink.cmp').get_lsp_capabilities(),
})

vim.lsp.enable({'clangd'})

-- Operator: <leader>f{motion} formats the resulting range, e.g. <leader>fi{,
-- <leader>fap, <leader>f}. Referenced via v:lua since operatorfunc needs a
-- global name, not a closure.
_G.FormatRangeOperator = function(motion_type)
    local start_pos = vim.api.nvim_buf_get_mark(0, '[')
    local end_pos = vim.api.nvim_buf_get_mark(0, ']')
    local start_line, start_col = start_pos[1] - 1, start_pos[2]
    local end_line, end_col = end_pos[1] - 1, end_pos[2]

    if motion_type == 'line' then
        start_col = 0
        end_col = #vim.fn.getline(end_pos[1])
    else
        end_col = end_col + 1
    end

    vim.lsp.buf.format({
        range = {
            start = { start_line, start_col },
            ['end'] = { end_line, end_col },
        },
    })
end

vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(args)
        local opts = {buffer = args.buf}
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
        vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
        vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
        vim.keymap.set('n', 'go', vim.lsp.buf.type_definition, opts)
        vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
        vim.keymap.set('n', 'gs', vim.lsp.buf.signature_help, opts)
        vim.keymap.set('n', '<F2>', vim.lsp.buf.rename, opts)
        vim.keymap.set('n', '<F3>', function() vim.lsp.buf.format({async = true}) end, opts)
        local function format_range_and_exit()
            vim.lsp.buf.format({async = true})
            vim.cmd('normal! \27')
        end
        vim.keymap.set('v', '<F3>', format_range_and_exit, opts)
        vim.keymap.set('v', '<leader>f', format_range_and_exit, opts)
        vim.keymap.set('n', 'f', function()
            vim.o.operatorfunc = 'v:lua.FormatRangeOperator'
            return 'g@'
        end, vim.tbl_extend('force', opts, {expr = true}))
        vim.keymap.set('n', 'ff', function()
            vim.o.operatorfunc = 'v:lua.FormatRangeOperator'
            return 'g@_'
        end, vim.tbl_extend('force', opts, {expr = true}))
        vim.keymap.set({'n', 'x'}, '<F4>', vim.lsp.buf.code_action, opts)
    end,
})

vim.keymap.set('n', ']d', function()
    vim.diagnostic.jump({count = 1, float = true})
end)

vim.keymap.set('n', '[d', function()
    vim.diagnostic.jump({count = -1, float = true})
end)

-- Autocomplete

require('blink.cmp').setup({
    keymap = { preset = 'default' },
    sources = {
        default = {'lsp', 'path', 'snippets', 'buffer'},
    },
    snippets = { preset = 'luasnip' },
    completion = { documentation = { auto_show = false } },
})

-- Snippets

function typedef_snippet(keyword)
    return ls.snippet({trig = keyword .. '%.(%w+)', regTrig = true}, {
        ls.function_node(function(_, snip)
            return {'typedef ' .. keyword .. ' ' .. snip.captures[1] .. ' {', '\t'}
        end, {}),
        ls.insert_node(0),
        ls.function_node(function(_, snip)
            return {'', '} ' .. snip.captures[1] .. ';'}
        end, {}),
    })
end

ls.add_snippets('all', {
    ls.snippet({trig = 'case (%w+):', regTrig = true}, {
        ls.function_node(function(_, snip)
            return {'case ' .. snip.captures[1] .. ': {', '\t'}
        end, {}),
        ls.insert_node(0),
        ls.text_node({'', '} break;'}),
    }),
    typedef_snippet('struct'),
    typedef_snippet('union'),
    typedef_snippet('enum'),
})

-- Undotree settings

vim.g.undotree_RelativeTimestamp = 0

-- Plugins

vim.cmd [[packadd packer.nvim]]

require('packer').startup(function(use)
    use('christoomey/vim-tmux-navigator')
    use('jeremiahkellick/jkellick-one-dark-vim')
    use('mbbill/undotree')
    use({
        'nvim-telescope/telescope.nvim',
        requires = {{'nvim-lua/plenary.nvim'}, {'BurntSushi/ripgrep'}}
    })
    use('nvim-treesitter/nvim-treesitter', {run = ':TSUpdate'})
    use({
        'nvim-treesitter/nvim-treesitter-textobjects',
        after = 'nvim-treesitter',
        requires = 'nvim-treesitter/nvim-treesitter',
    })
    use('saadparwaiz1/cmp_luasnip')
    use('tpope/vim-fugitive')
    use('tpope/vim-repeat')
    use('tpope/vim-sleuth')
    use('tpope/vim-surround')
    use('tpope/vim-unimpaired')
    use ({
        'VonHeikemen/lsp-zero.nvim',
        branch = 'v3.x',
        requires = {
            {'williamboman/mason.nvim'},
            {'williamboman/mason-lspconfig.nvim'},
            {'neovim/nvim-lspconfig'},
            {'hrsh7th/nvim-cmp'},
            {'hrsh7th/cmp-nvim-lsp'},
            {'L3MON4D3/LuaSnip'},
        }
    })
    use('wbthomason/packer.nvim')
end)

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
vim.opt.scrolloff = 8
-- vim.opt.signcolumn = 'yes'
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

vim.keymap.set('n', '<C-d>', '<C-d>zz')
vim.keymap.set('n', '<C-u>', '<C-u>zz')
vim.keymap.set('n', 'n', 'nzzzv')
vim.keymap.set('n', 'N', 'Nzzzb')

vim.keymap.set({'n', 'v'}, '<leader>y', '"+y')
vim.keymap.set('n', '<leader>Y', '"+Y')

vim.keymap.set('n', '<leader>x', '<cmd>!chmod +x %<CR>', {silent = true})

vim.keymap.set('n', '<leader>u', vim.cmd.UndotreeToggle)
vim.keymap.set('n', '<leader>i', vim.cmd.cclose)

vim.keymap.set('n', '<leader>o', 'o<Esc>')
vim.keymap.set('n', '<leader>O', 'O<Esc>')

local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>pf', builtin.find_files, {})
vim.keymap.set('n', '<C-p>', builtin.git_files, {})
vim.keymap.set('n', '<leader>ps', builtin.live_grep, {})

vim.keymap.set('n', '<leader>gs', vim.cmd.Git)

vim.keymap.set('i', '<C-BS>', '<C-w>')
vim.keymap.set('i', '<C-h>', '<C-w>')
vim.keymap.set('i', '<C-o>', '<Esc>O')
vim.keymap.set('i', '<C-u>', '{<CR>}<Esc>O')

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

vim.keymap.set('n', '<leader>s', function() make('--mode=debug_slow') end)
vim.keymap.set('n', '<leader>f', function() make('--mode=debug_fast') end)

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
  vim.fn.setreg('+', vim.fn.expand('%'))
end)

-- Treesitter
require('nvim-treesitter.config').setup({
    ensure_installed = {'c', 'cpp', 'lua', 'objc', 'query', 'vim', 'vimdoc'},
    sync_install = false,
    auto_install = true,

    highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
    },

    textobjects = {
        select = {
            enable = true,
            lookahead = true,
            keymaps = {
                ['ia'] = '@parameter.inner',
                ['aa'] = '@parameter.outer',
            }
        }
    },
})

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

local lsp_zero = require('lsp-zero')

lsp_zero.on_attach(function(client, bufnr)
    lsp_zero.default_keymaps({buffer = bufnr})
end)

require('mason').setup({})
require('mason-lspconfig').setup({
    ensure_installed = {'clangd'},
})

vim.keymap.set('n', ']d', function()
    vim.diagnostic.jump({count = 1, float = true})
end)

vim.keymap.set('n', '[d', function()
    vim.diagnostic.jump({count = -1, float = true})
end)

-- Autocomplete

local cmp = require('cmp')

cmp.setup({
    sources = {
        {name = 'nvim_lsp'},
    },
    mapping = {
        ['<C-y>'] = cmp.mapping.confirm({select = true}),
        ['<C-e>'] = cmp.mapping.abort(),
        ['<Up>'] = cmp.mapping.select_prev_item({behavior = 'select'}),
        ['<Down>'] = cmp.mapping.select_next_item({behavior = 'select'}),
        ['<C-p>'] = cmp.mapping(function()
            if cmp.visible() then
                cmp.select_prev_item({behavior = 'insert'})
            else
                cmp.complete()
            end
        end),
        ['<C-n>'] = cmp.mapping(function()
            if cmp.visible() then
                cmp.select_next_item({behavior = 'insert'})
            else
                cmp.complete()
            end
        end),
    },
    snippet = {
        expand = function(args)
            ls.lsp_expand(args.body)
        end,
    },
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

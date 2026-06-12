#!/usr/bin/env bash

setup_neovim() {
    draw_section "NEOVIM SETUP"

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Would configure Neovim"
        return 0
    fi

    if ! command -v nvim &>/dev/null; then
        log_info "Installing Neovim..."
        pkg_install neovim
    fi

    if ! command -v nvim &>/dev/null; then
        log_error "Neovim installation failed"
        return 1
    fi

    log_success "Neovim $(nvim --version 2>/dev/null | head -1) ready"

    local nvim_config="${HOME}/.config/nvim"
    mkdir -p "$nvim_config"

    if [[ ! -f "${nvim_config}/init.lua" ]] && [[ ! -f "${nvim_config}/init.vim" ]]; then
        log_info "Setting up basic Neovim configuration..."

        cat > "${nvim_config}/init.lua" << 'EOF'
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.termguicolors = true
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.incsearch = true

vim.opt.updatetime = 50
vim.opt.signcolumn = "yes"

vim.api.nvim_create_autocmd("TextYankPost", {
    callback = function()
        vim.highlight.on_yank({ higroup = "IncSearch", timeout = 150 })
    end,
})

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    { "catppuccin/nvim", name = "catppuccin", priority = 1000 },
    { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
    { "nvim-lualine/lualine.nvim", dependencies = { "nvim-tree/nvim-web-devicons" } },
    { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
    { "nvim-tree/nvim-tree.lua", dependencies = { "nvim-tree/nvim-web-devicons" } },
    { "williamboman/mason.nvim", build = ":Mason" },
    { "williamboman/mason-lspconfig.nvim" },
    { "neovim/nvim-lspconfig" },
    { "hrsh7th/nvim-cmp", dependencies = { "hrsh7th/cmp-nvim-lsp", "L3MON4D3/LuaSnip" } },
    { "windwp/nvim-autopairs" },
    { "numToStr/Comment.nvim" },
    { "folke/which-key.nvim" },
    { "akinsho/toggleterm.nvim" },
})

vim.cmd.colorscheme("catppuccin-mocha")
EOF
        log_success "Neovim configuration created with Lazy plugin manager"
    else
        log_info "Neovim config already exists"
    fi

    log_success "Neovim setup complete"
}

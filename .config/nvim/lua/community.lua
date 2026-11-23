-- AstroCommunity: import any community modules here
-- We import this file in `lazy_setup.lua` before the `plugins/` folder.
-- This guarantees that the specs are processed before any user plugins.

---@type LazySpec
return {
  "AstroNvim/astrocommunity",

  -- Python: treesitter, debugpy, venv-selector, neotest-python + basedpyright (LSP)
  -- + ruff (lint, fix, sort imports, format)
  { import = "astrocommunity.pack.python.base" },
  { import = "astrocommunity.pack.python.basedpyright" },
  { import = "astrocommunity.pack.python.ruff" },

  -- Rust: rustaceanvim (rust-analyzer from rustup, clippy), crates.nvim, TOML, codelldb
  { import = "astrocommunity.pack.rust" },

  -- Bash/sh/zsh: bashls, shellcheck, shfmt, bash-debug-adapter
  { import = "astrocommunity.pack.bash" },

  -- C/C++: clangd (+ clang-format), clangd_extensions, cmake-tools, codelldb
  { import = "astrocommunity.pack.cpp" },

  -- JS/TS + web: vtsls, HTML/CSS/Emmet + JSON LSPs, ESLint (only in ESLint projects),
  -- Prettier (prettierd) as the formatter for JS/TS/JSON/CSS/HTML/YAML/Markdown
  { import = "astrocommunity.pack.typescript" },
  { import = "astrocommunity.pack.html-css" },
  { import = "astrocommunity.pack.eslint" },
  { import = "astrocommunity.pack.prettier" },

  -- Runs the formatters the packs above configure (format on save, <Leader>lf)
  { import = "astrocommunity.editing-support.conform-nvim" },

  -- Surround: ys{motion}{char}, ds{char}, cs{old}{new}
  { import = "astrocommunity.motion.nvim-surround" },
}

-- Personal key mappings.
-- This file is part of *your* config (`~/.config/nvim`), not AstroNvim itself,
-- so updating AstroNvim (`:Lazy update`) will never overwrite it.
-- Lazy merges these opts into the ones AstroNvim ships, it doesn't replace them.

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    mappings = {
      -- insert mode
      i = {
        -- Ctrl+Backspace -> delete the whole word before the cursor.
        -- Terminals disagree on what Ctrl+Backspace actually sends, so map both:
        --   <C-BS> : terminals speaking the kitty keyboard protocol (kitty, wezterm,
        --            foot, ghostty, alacritty >= 0.14, ...) which Neovim 0.10+ enables
        --   <C-H>  : the legacy 0x08 byte sent by everything else (xterm, gnome-terminal,
        --            tmux without passthrough, ssh into an older host, ...)
        -- AstroNvim only maps <C-H> in normal/terminal mode, so this doesn't clash.
        ["<C-BS>"] = { "<C-w>", desc = "Delete previous word" },
        ["<C-H>"] = { "<C-w>", desc = "Delete previous word" },
      },
    },
  },
}

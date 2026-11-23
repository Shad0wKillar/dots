-- Personal vim options.
-- Lives in *your* config (`~/.config/nvim`), so `:Lazy update` on AstroNvim
-- will never overwrite it. These are merged over AstroNvim's own defaults.

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    options = {
      opt = {
        -- AstroNvim defaults this to false; wrap long lines instead of
        -- letting them run off the right edge of the terminal.
        -- AstroNvim already sets `linebreak` (break at word boundaries, not
        -- mid-word) and `breakindent` (wrapped lines keep the line's indent),
        -- so those don't need repeating here.
        wrap = true,
      },
    },
  },
}

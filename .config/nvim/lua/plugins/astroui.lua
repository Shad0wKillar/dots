-- AstroUI provides the basis for configuring the AstroNvim User Interface
-- Configuration documentation can be found with `:h astroui`

---@type LazySpec
return {
  "AstroNvim/astroui",
  ---@type AstroUIOpts
  opts = {
    -- change colorscheme
    colorscheme = "astrodark",

    -- This is the new section you will add
    highlights = {
      init = { -- this table overrides highlights in all themes

        -- Set the main editor background to transparent
        Normal = { bg = "NONE" },
        -- Set inactive window backgrounds to transparent
        NormalNC = { bg = "NONE" },
        -- Set floating window backgrounds to transparent
        NormalFloat = { bg = "NONE" },
        -- Set floating window borders to transparent
        FloatBorder = { bg = "NONE" },
        -- Set window separator lines to transparent
        WinSeparator = { bg = "NONE" },
        -- Set the tab line background to transparent
        TabLineFill = { bg = "NONE" },
        -- Set the file tree background to transparent
        NeoTreeNormal = { bg = "NONE" },
        -- Set the comments to have a light red color for better visibility
        Comment = { fg = "#61AFEF", italic = true },
        -- Set the color for the numbers that represent the line
        LineNr = { fg = "#E06C75" },
        CursorLineNr = { fg = "#A5D6A7", bold = true },
      },
    },
  },
}

-- I configured git signs and colors.
th.git = th.git or {}
th.git.unknown_sign = " "
th.git.modified_sign = "M"
th.git.deleted_sign = "D"
th.git.clean_sign = "✔"

th.git.modified = ui.Style():fg("blue")
th.git.deleted = ui.Style():fg("red"):bold()

require("git"):setup({
  order = 1500,
})

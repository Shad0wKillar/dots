return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = function(_, opts)
    opts.event_handlers = opts.event_handlers or {}
    table.insert(opts.event_handlers, {
      event = "neo_tree_buffer_enter",
      handler = function()
        -- I forced relative line numbers upon entering the buffer
        vim.opt_local.number = true
        vim.opt_local.relativenumber = true
      end,
    })
  end,
}

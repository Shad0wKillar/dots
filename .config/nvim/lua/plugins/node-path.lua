-- Node.js is managed by nvm, and ~/.zshrc_custom only loads nvm lazily (`node`/`npm` are
-- shell functions), so nvim and everything it spawns (Mason npm installs, vtsls, eslint,
-- html/css/json/bash language servers, prettierd) can't find `node`.
-- Put nvm's default Node on PATH for this nvim session. This runs when lazy.nvim reads
-- the plugin specs, i.e. before any plugin, LSP or Mason install starts.
if vim.fn.executable "node" == 0 then
  local nvm_dir = vim.env.NVM_DIR or vim.fn.expand "~/.nvm"
  local alias_file = nvm_dir .. "/alias/default"
  local alias = vim.fn.filereadable(alias_file) == 1 and vim.fn.readfile(alias_file)[1] or ""
  local wanted = alias:match "^v?(%d[%d.]*)$" -- "24" / "v24.20.0"; nil for "lts/*", "node" => newest
  local range = wanted and vim.version.range(wanted)
  local best_dir, best_ver
  for _, dir in ipairs(vim.fn.glob(nvm_dir .. "/versions/node/v*", false, true)) do
    local ver = vim.version.parse(vim.fs.basename(dir))
    if ver and (not range or range:has(ver)) and (not best_ver or vim.version.gt(ver, best_ver)) then
      best_dir, best_ver = dir, ver
    end
  end
  if best_dir then vim.env.PATH = best_dir .. "/bin:" .. vim.env.PATH end
end

---@type LazySpec
return {}

-- This will run last in the setup process.
-- This is just pure lua so anything that doesn't
-- fit in the normal config locations above can go here

-- Auto-activate the nearest .venv
-- --------------------------------
-- When a Python buffer is opened or entered, walk up from the file's own folder to `/` and
-- activate the first `.venv` found in one of those folders (the nearest one wins).
-- Folders that aren't on that path (siblings, sub-folders) are never looked at.
--   * No .venv above the file -> back to system Python.
--   * A venv picked by hand with <Leader>lv (venv-selector remembers it per project), or a
--     buffer deactivated by hand, always wins over this rule.
--   * A `.venv` without an executable bin/python is skipped with a warning.
-- Activation goes through venv-selector, so PATH, $VIRTUAL_ENV, the debugger, terminals and
-- the Python language servers all switch together. The statusline shows the venv's folder
-- name (e.g. `AI` for AI/.venv); `:VenvInfo` or <Leader>lV shows where it was loaded from.
-- `:VenvAuto` forgets a hand pick for the current project and goes back to this rule.

local auto_venv = { warned = {}, active = nil }
local notify_opts = { title = "auto-venv" }

---@return string? file absolute path if `buf` is a normal, on-disk Python buffer
local function python_file(buf)
  if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= "" or vim.bo[buf].filetype ~= "python" then
    return
  end
  local name = vim.api.nvim_buf_get_name(buf)
  if name ~= "" and not name:find "://" then return vim.fs.normalize(name) end
end

---Walk up from `file`. Returns the nearest usable .venv and every folder checked on the way.
local function find_venv(file)
  local walk = {}
  for dir in vim.fs.parents(file) do
    local venv = vim.fs.joinpath(dir, ".venv")
    if not vim.uv.fs_stat(venv) then
      table.insert(walk, { dir = dir, state = "none" })
    else
      local python = vim.fs.joinpath(venv, "bin", "python")
      if vim.fn.executable(python) == 1 then
        table.insert(walk, { dir = dir, state = "found" })
        return { dir = venv, python = python }, walk
      end
      table.insert(walk, { dir = dir, state = "broken" })
      if not auto_venv.warned[venv] then
        auto_venv.warned[venv] = true
        vim.notify(("Skipping %s: no executable bin/python"):format(venv), vim.log.levels.WARN, notify_opts)
      end
    end
  end
  return nil, walk
end

---A choice made by hand that beats the auto rule: `{ disabled = true }` if this buffer was
---deactivated by hand, or the venv picked with <Leader>lv for the file's project. venv-selector
---remembers picks per project root (LSP root, else the file's folder), so a pick covers files
---in that folder and below; the deepest matching pick wins.
local function manual_choice(buf, file)
  if vim.b[buf].venv_selector_disabled and not vim.b[buf].auto_venv_disabled then return { disabled = true } end
  local cache_file = vim.tbl_get(require("venv-selector.config"), "user_settings", "cache", "file")
  if not cache_file or not require("venv-selector.cached_venv").cache_auto_enabled() then return end
  cache_file = vim.fn.expand(cache_file)
  if vim.fn.filereadable(cache_file) == 0 then return end
  local ok, cache = pcall(vim.json.decode, table.concat(vim.fn.readfile(cache_file), "\n"))
  if not ok or type(cache) ~= "table" then return end
  local best
  for root, entry in pairs(cache) do
    if
      type(entry) == "table"
      and type(entry.value) == "string"
      and vim.fs.relpath(root, file)
      and vim.fn.filereadable(entry.value) == 1
      and (not best or #root > #best.root)
    then
      best = { root = root, python = entry.value, type = entry.type or "venv" }
    end
  end
  return best
end

---venv-selector skips re-adding a bin/ it thinks is already on PATH, so make sure it leads PATH.
local function ensure_on_path(python)
  local bin = vim.fs.dirname(python)
  if not vim.startswith(vim.env.PATH or "", bin .. ":") then vim.env.PATH = bin .. ":" .. (vim.env.PATH or "") end
end

local function deactivate(buf)
  local vs = require "venv-selector"
  local bin = vim.fs.dirname(vs.python())
  vs.deactivate() -- also marks this buffer so venv-selector won't restore a venv into it
  -- venv-selector forgets the active venv before cleaning PATH, so its bin/ would stay behind
  require("venv-selector.path").remove(bin)
  vim.b[buf].auto_venv_disabled = true
end

---Point the buffer's basedpyright/pyright clients at the active interpreter. One client can serve
---files from different venvs (folders without pyproject.toml/.git share one), so re-check on
---every switch; the server re-reads its settings and re-analyses with the new interpreter.
local function sync_lsp(buf)
  local ok, vs = pcall(require, "venv-selector")
  local python = ok and vs.python() or vim.fn.exepath "python"
  for _, client in ipairs(vim.lsp.get_clients { bufnr = buf }) do
    if client.name == "basedpyright" or client.name == "pyright" then
      client.settings = client.settings or {}
      local settings = client.settings
      if vim.tbl_get(settings, "python", "pythonPath") ~= python then
        settings.python = settings.python or {}
        settings.python.pythonPath = python
        client:notify("workspace/didChangeConfiguration", { settings = settings })
      end
    end
  end
end

---Also re-sync PATH and the LSP after activations venv-selector does by itself (<Leader>lv
---picker, cache restore). Keeps any on_venv_activate_callback that was already configured.
local function hook_venv_selector()
  if auto_venv.hooked then return end
  auto_venv.hooked = true
  local opts = require("venv-selector.config").user_settings.options
  local previous_callback = opts.on_venv_activate_callback
  opts.on_venv_activate_callback = function(...)
    local buf = vim.api.nvim_get_current_buf()
    local python = require("venv-selector").python()
    if python then ensure_on_path(python) end
    if python_file(buf) then sync_lsp(buf) end
    if previous_callback then return previous_callback(...) end
  end
end

local function apply(buf)
  local file = python_file(buf)
  if not file then return end
  local ok, vs = pcall(require, "venv-selector")
  if not ok then
    if not auto_venv.warned.venv_selector then
      auto_venv.warned.venv_selector = true
      vim.notify("venv-selector isn't available (it needs `fd`), so .venv auto-activation is off", vim.log.levels.WARN, notify_opts)
    end
    return
  end
  hook_venv_selector()

  local manual = manual_choice(buf, file)
  if manual then
    if manual.python then
      if vs.python() ~= manual.python then
        require("venv-selector.venv").activate_for_buffer(manual.python, manual.type, buf, { save_cache = false })
        local msg = "Activated %s (picked by hand for %s)"
        vim.notify(msg:format(vim.fn.fnamemodify(manual.python, ":h:h:~"), vim.fn.fnamemodify(manual.root, ":~")), vim.log.levels.INFO, notify_opts)
      end
      ensure_on_path(manual.python)
    end
  else
    local venv = find_venv(file)
    if venv then
      -- undo our own "no venv here" mark if a .venv has appeared since
      if vim.b[buf].auto_venv_disabled then
        vim.b[buf].venv_selector_disabled, vim.b[buf].auto_venv_disabled = nil, nil
      end
      if vs.python() ~= venv.python then
        if require("venv-selector.venv").activate_for_buffer(venv.python, "venv", buf, { save_cache = false }) then
          auto_venv.active = { python = venv.python, venv = venv.dir, file = file }
          vim.notify("Activated " .. vim.fn.fnamemodify(venv.dir, ":~"), vim.log.levels.INFO, notify_opts)
        end
      end
      ensure_on_path(venv.python)
    elseif vs.python() then
      local previous = vim.fn.fnamemodify(vs.python(), ":h:h:~")
      deactivate(buf)
      auto_venv.active = nil
      vim.notify(("No .venv above this file, back to system Python (was %s)"):format(previous), vim.log.levels.INFO, notify_opts)
    end
  end
  sync_lsp(buf)
end

local augroup = vim.api.nvim_create_augroup("auto_venv", { clear = true })
vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
  group = augroup,
  desc = "Activate the nearest .venv above the current Python file",
  callback = function(args)
    -- only act on the buffer being shown; hidden/preview buffers are handled when entered
    if args.buf == vim.api.nvim_get_current_buf() then apply(args.buf) end
  end,
})
vim.api.nvim_create_autocmd("LspAttach", {
  group = augroup,
  desc = "Point a (possibly shared) Python LSP client at the active venv",
  callback = function(args)
    if args.buf == vim.api.nvim_get_current_buf() and python_file(args.buf) then sync_lsp(args.buf) end
  end,
})

local function venv_info()
  local buf = vim.api.nvim_get_current_buf()
  local lines = {}
  local function add(line) table.insert(lines, line) end
  local ok, vs = pcall(require, "venv-selector")
  local active = ok and vs.python() or nil

  if active then
    add(("Active: %s (%s)"):format(vim.fn.fnamemodify(active, ":h:h:~"), vim.trim(vim.fn.system { active, "--version" })))
    add("Python: " .. active)
    if auto_venv.active and auto_venv.active.python == active then
      add("Source: auto .venv rule, loaded for " .. vim.fn.fnamemodify(auto_venv.active.file, ":~"))
    else
      add "Source: venv-selector (picked by hand or restored from its cache)"
    end
  else
    add("Active: none, system Python (" .. vim.fn.exepath "python" .. ")")
  end

  local file = python_file(buf)
  if file then
    local manual = ok and manual_choice(buf, file)
    if manual then
      add(manual.disabled and "Auto rule skipped: this buffer was deactivated by hand"
        or ("Auto rule skipped: picked by hand for %s"):format(vim.fn.fnamemodify(manual.root, ":~")))
    end
    local _, walk = find_venv(file)
    add("Walk from " .. vim.fn.fnamemodify(file, ":~") .. ":")
    local marks = { none = "·", broken = "✗", found = "✓" }
    for _, step in ipairs(walk) do
      local venv = vim.fn.fnamemodify(vim.fs.joinpath(step.dir, ".venv"), ":~")
      add(("  %s %s%s"):format(marks[step.state], venv, step.state == "broken" and "  (no bin/python, skipped)" or ""))
    end
    if not walk[#walk] or walk[#walk].state ~= "found" then add "  (no usable .venv up to /)" end
  else
    add "Current buffer isn't a Python file."
  end

  for _, client in ipairs(vim.lsp.get_clients { bufnr = buf }) do
    local py = vim.tbl_get(client.config, "settings", "python", "pythonPath")
    if py then add(("LSP %s uses: %s"):format(client.name, py)) end
  end
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "auto-venv: VenvInfo", timeout = 15000 })
end

vim.api.nvim_create_user_command("VenvInfo", venv_info, { desc = "Show the active Python venv and where it came from" })
vim.keymap.set("n", "<Leader>lV", venv_info, { desc = "Venv info (where it was loaded from)" })

-- Undo a hand pick (or a hand deactivation) for this file's project and go back to the .venv rule.
vim.api.nvim_create_user_command("VenvAuto", function()
  local buf = vim.api.nvim_get_current_buf()
  local file = python_file(buf)
  if not file or not pcall(require, "venv-selector") then
    return vim.notify("Open a Python file first", vim.log.levels.WARN, notify_opts)
  end
  local manual = manual_choice(buf, file)
  if manual and manual.root then
    local cache_file = vim.fn.expand(require("venv-selector.config").user_settings.cache.file)
    local cache = vim.json.decode(table.concat(vim.fn.readfile(cache_file), "\n"))
    cache[manual.root] = nil
    vim.fn.writefile({ vim.json.encode(next(cache) and cache or vim.empty_dict()) }, cache_file)
    vim.notify("Forgot the hand-picked venv for " .. vim.fn.fnamemodify(manual.root, ":~"), vim.log.levels.INFO, notify_opts)
  end
  vim.b[buf].venv_selector_disabled, vim.b[buf].auto_venv_disabled = nil, nil
  apply(buf)
end, { desc = "Forget a hand-picked venv for this project and use the nearest .venv again" })

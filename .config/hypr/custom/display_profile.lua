-- Only the connection watcher runs on the laptop alone. The normal ML4W
-- monitor configuration then supplies its preferred mode and 1.2 scaling.
local lcdDescription = "Dell Inc. DELL P2419H 4PQC6X2"

-- Waybar normally reserves five buttons per monitor. While docked, reserve
-- none: Hyprland supplies occupied workspaces and each display's current one.
local function updateWorkspaceBar(docked)
    local path = os.getenv("HOME") .. "/.config/waybar/workspace-profile.json"
    local content = '{\n  "hyprland/workspaces": {\n    "persistent-workspaces": { "*": '
        .. (docked and "0" or "5") .. ' }\n  }\n}\n'
    local previous = io.open(path, "r")
    if previous then
        local unchanged = previous:read("*a") == content
        previous:close()
        if unchanged then return end
    end

    -- Replace atomically so a simultaneous Waybar launch sees a complete file.
    local file = assert(io.open(path .. ".tmp", "w"))
    assert(file:write(content))
    assert(file:close())
    assert(os.rename(path .. ".tmp", path))
    hl.exec_cmd("pkill -USR2 -x waybar")
end

local function findLCD()
    for _, monitor in ipairs(hl.get_monitors()) do
        if monitor.description == lcdDescription then
            return monitor.name
        end
    end
end

-- Capture the normal options after input.lua has loaded. Keep them when docked.
local normalKeyboardOptions = hl.get_config("input.kb_options")
local dockedKeyboardOptions = normalKeyboardOptions == "" and "ctrl:swap_ralt_rctl"
    or normalKeyboardOptions .. ",ctrl:swap_ralt_rctl"

local function updateKeyboard(docked)
    local options = docked and dockedKeyboardOptions or normalKeyboardOptions
    if hl.get_config("input.kb_options") ~= options then
        hl.config({ input = { kb_options = options } })
    end
end

local function loadDualProfile(output, moveExistingWorkspaces)
    require("custom.dual_monitors")(output)
    require("custom.workspaces")(output, moveExistingWorkspaces)
    updateKeyboard(true)
end

-- Applying a config reload must preserve workspaces the user has manually
-- moved. Restore workspace homes only when the LCD is newly connected.
local appliedOutput = findLCD()
updateWorkspaceBar(appliedOutput ~= nil)
if appliedOutput then
    loadDualProfile(appliedOutput, false)
end

local pendingCheck
local reloadRequested = false

local function checkConnection()
    pendingCheck = nil
    if reloadRequested then return end

    local output = findLCD()
    -- Reconcile after startup/reload even if the same LCD is still connected.
    -- An unchanged connection does not guarantee the keyboard option survived.
    updateKeyboard(output ~= nil)
    if output == appliedOutput then return end

    if appliedOutput then
        -- A fresh config restores normal keyboard options and clears the old
        -- monitor rules, workspace assignments, bindings and subscriptions.
        -- If the LCD is gone, neither dual
        -- module is loaded again; Hyprland keeps the windows on the laptop.
        reloadRequested = true
        hl.exec_cmd("hyprctl reload")
    elseif output then
        -- Set this before applying rules: layout changes can emit more events.
        appliedOutput = output
        loadDualProfile(output, true)
        updateWorkspaceBar(true)
    end
end

local function scheduleCheck()
    if reloadRequested then return end
    if pendingCheck then
        pendingCheck:set_timeout(300)
    else
        -- Monitor events can fire before the output list finishes changing.
        pendingCheck = hl.timer(checkConnection, { timeout = 300, type = "oneshot" })
    end
end

hl.on("hyprland.start", scheduleCheck)
hl.on("config.reloaded", scheduleCheck)
hl.on("monitor.added", scheduleCheck)
hl.on("monitor.removed", scheduleCheck)

-- Also check after this module finishes loading. At login the output list can
-- still be empty; this must run after the compositor has initialized it.
scheduleCheck()

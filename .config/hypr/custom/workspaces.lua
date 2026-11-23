return function(lcdOutput, moveExistingWorkspaces)
    local mainMod = "SUPER"

    -- Workspace homes: 1-5 on the LCD, 6-10 on the laptop.
    -- Workspaces 1 and 6 are the default workspace for their respective displays.
    for i = 1, 10 do
        hl.workspace_rule({
            workspace = tostring(i),
            monitor = i <= 5 and lcdOutput or "eDP-1",
            default = i == 1 or i == 6,
        })
    end

    -- Bring any workspace onto the focused display, regardless of its home.
    -- Move and focus it; leave this display's previous workspace here, hidden.
    -- Hyprland chooses a replacement workspace for the source display.
    -- Super + number still follows a workspace; Super + Shift + number moves a window.
    local function bringWorkspaceHere(workspaceId)
        local destination = hl.get_active_monitor()
        if not destination then return end
        local destinationName = destination.name

        -- Materialize unused workspaces before moving them. Capture the destination
        -- first, since the initial focus may follow the workspace's home monitor.
        if not hl.get_workspace(workspaceId) then
            hl.dispatch(hl.dsp.focus({ workspace = workspaceId }))
        end

        local workspace = hl.get_workspace(workspaceId)
        if workspace and workspace.monitor and workspace.monitor.name ~= destinationName then
            hl.dispatch(hl.dsp.workspace.move({ workspace = workspaceId, monitor = destinationName }))
        end
        hl.dispatch(hl.dsp.focus({ workspace = workspaceId }))
    end

    for i = 1, 10 do
        hl.bind(mainMod .. " + CTRL + " .. (i % 10),
            function() bringWorkspaceHere(i) end,
            { description = "Bring workspace " .. i .. " to current monitor" })
    end

    -- On docking, place existing numbered workspaces on their default displays.
    -- Skip this on ordinary reloads so manually moved workspaces stay put.
    if moveExistingWorkspaces then
        for _, workspace in ipairs(hl.get_workspaces()) do
            if workspace.id >= 1 and workspace.id <= 10 then
                local home = workspace.id <= 5 and lcdOutput or "eDP-1"
                if hl.get_monitor(home) and workspace.monitor and workspace.monitor.name ~= home then
                    hl.dispatch(hl.dsp.workspace.move({ workspace = workspace.id, monitor = home }))
                end
            end
        end
    end
end

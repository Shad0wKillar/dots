return function(lcdOutput)
    -- Dual displays: Dell P2419H LCD on the left, laptop on the right.
    -- LCD at 100%, laptop at 120%; the LCD's desktop width is 1920 pixels.
    hl.monitor({
        output = lcdOutput,
        mode = "1920x1080@60",
        position = "0x0",
        scale = 1.0,
        disabled = false,
    })

    hl.monitor({
        output = "eDP-1",
        mode = "1920x1080@60",
        position = "1920x0",
        scale = 1.2,
        disabled = false,
    })
end

-- ui/navigation.lua
-- Navigation and system buttons

Saellskapsresan = Saellskapsresan or {}
local SSR = Saellskapsresan

-- Navigation Buttons
SSR.NavButtons = {}

-- Show a specific frame and highlight the correct button
function SSR.ShowFrame(frame)
    -- Find and highlight the correct button based on frame name
    local frameName = frame:GetName()
    for k, v in pairs(SSR.NavButtons) do
        if k == frameName then
            SSR.SetButtonState(v, true)
        else
            SSR.SetButtonState(v, false)
        end
    end

    -- Hide all frames
    SSR.frames.StartFrame:Hide()
    SSR.frames.DeathLogFrame:Hide()
    SSR.frames.StatsFrame:Hide()
    SSR.frames.ProfessionsFrame:Hide()
    
    -- Show the requested frame
    frame:Show()
end

-- Set button appearance (pressed or normal)
function SSR.SetButtonState(button, isPressed)
    if isPressed then
        -- Pressed appearance for GameMenuButtonTemplate
        button:LockHighlight()
    else
        -- Normal appearance
        button:UnlockHighlight()
    end
end

-- Create a navigation button
function SSR.CreateNavButton(name, text, xOffset, onClick)
    local btn = CreateFrame("Button", nil, SSR.frames.MainFrame, "GameMenuButtonTemplate")
    btn:SetWidth(120)
    btn:SetHeight(30)
    btn:SetPoint("TOPLEFT", SSR.frames.MainFrame, "TOPLEFT", xOffset, -60)
    btn:SetText(text)
    btn:SetScript("OnClick", onClick)
    return btn
end

-- Create all navigation buttons
function SSR.CreateNavigationButtons()
    -- Create navigation buttons
    local startBtn = SSR.CreateNavButton("StartBtn", "Start", 20, function() SSR.ShowFrame(SSR.frames.StartFrame) end)
    local logBtn = SSR.CreateNavButton("LogBtn", "Dödslogg", 150, function() SSR.ShowFrame(SSR.frames.DeathLogFrame) end)
    local statsBtn = SSR.CreateNavButton("StatsBtn", "Statistik", 280, function() SSR.ShowFrame(SSR.frames.StatsFrame) end)
    local professionsBtn = SSR.CreateNavButton("ProfessionsBtn", "Yrken", 410, function() SSR.ShowFrame(SSR.frames.ProfessionsFrame) end)

    -- Fill the table after buttons are created
    SSR.NavButtons["StartFrame"] = startBtn
    SSR.NavButtons["DeathLogFrame"] = logBtn
    SSR.NavButtons["StatsFrame"] = statsBtn
    SSR.NavButtons["ProfessionsFrame"] = professionsBtn

    -- Initialize with Start button pressed
    SSR.SetButtonState(startBtn, true)
    SSR.ShowFrame(SSR.frames.StartFrame)
end

-- Create system buttons (close, reload, debug)
function SSR.CreateSystemButtons()
    -- Close Button
    local close = CreateFrame("Button", nil, SSR.frames.MainFrame, "GameMenuButtonTemplate")
    close:SetPoint("BOTTOMRIGHT", SSR.frames.MainFrame, "BOTTOMRIGHT", -20, 20)
    close:SetWidth(90)
    close:SetHeight(25)
    close:SetText("Stäng")
    close:SetScript("OnClick", function() SSR.CloseUI() end)

    -- Reset Button
    local refresh = CreateFrame("Button", nil, SSR.frames.MainFrame, "GameMenuButtonTemplate")
    refresh:SetPoint("BOTTOMRIGHT", SSR.frames.MainFrame, "BOTTOMRIGHT", -120, 20)
    refresh:SetWidth(90)
    refresh:SetHeight(25)
    refresh:SetText("Ladda Om")
    refresh:SetScript("OnClick", ReloadUI)

    -- Debug Button
    local debugTest = CreateFrame("Button", nil, SSR.frames.MainFrame, "GameMenuButtonTemplate")
    debugTest:SetPoint("BOTTOMRIGHT", SSR.frames.MainFrame, "BOTTOMRIGHT", -220, 20)
    debugTest:SetWidth(90)
    debugTest:SetHeight(25)
    debugTest:SetText("Debug")
    debugTest:SetScript("OnClick", function()
        SSR.ProfessionsScrollUpdate()
    end)
end
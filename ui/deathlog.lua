-- ui/deathlog.lua
-- Death log UI

Saellskapsresan = Saellskapsresan or {}
local SSR = Saellskapsresan

-- Create the death log layout
function SSR.CreateDeathLoggerLayout()
    -- Deathlog Frame
    local DeathLogFrame = CreateFrame("Frame", "DeathLogFrame", SSR.frames.MainFrame)
    DeathLogFrame:SetAllPoints(SSR.frames.MainFrame)
    
    local deathlogFrameBg = DeathLogFrame:CreateTexture(nil, "BACKGROUND")
    deathlogFrameBg:SetAllPoints(DeathLogFrame)
    deathlogFrameBg:SetTexture(SSR.UI.navWindowColor.r, SSR.UI.navWindowColor.g, SSR.UI.navWindowColor.b, SSR.UI.navWindowColor.a)

    DeathLogFrame:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })

    DeathLogFrame:SetPoint("TOPLEFT", SSR.frames.MainFrame, "TOPLEFT", 15, -75)
    DeathLogFrame:SetPoint("BOTTOMRIGHT", SSR.frames.MainFrame, "BOTTOMRIGHT", -15, 50)
    DeathLogFrame:Hide()

    -- Create a FauxScrollFrame
    local deathlogScrollFrame = CreateFrame("Frame", "ProfessionsFauxScrollFrame", DeathLogFrame)
    deathlogScrollFrame:SetPoint("TOPLEFT", DeathLogFrame, "TOPLEFT", 20, -20)
    deathlogScrollFrame:SetPoint("BOTTOMRIGHT", DeathLogFrame, "BOTTOMRIGHT", -35, 20)
    deathlogScrollFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })

    -- Create the actual scroll frame
    local deathlogFauxScroll = CreateFrame("ScrollFrame", "deathlogScrollFrame", deathlogScrollFrame, "FauxScrollFrameTemplate")
    deathlogFauxScroll:SetPoint("TOPLEFT", deathlogScrollFrame, "TOPLEFT", 0, 0)
    deathlogFauxScroll:SetPoint("BOTTOMRIGHT", deathlogScrollFrame, "BOTTOMRIGHT", -16, 0)

    -- Create content frame directly inside the scrollFrame (no SetScrollChild needed)
    local deathlogContentFrame = CreateFrame("Frame", "deathlogContentFrame", deathlogScrollFrame)
    deathlogContentFrame:SetPoint("TOPLEFT", deathlogScrollFrame, "TOPLEFT", 0, 0)
    deathlogContentFrame:SetWidth(deathlogScrollFrame:GetWidth() - 16)  -- Adjust for scroll bar
    deathlogContentFrame:SetHeight(500)  -- Will be adjusted based on content

    -- Add visible background to content frame
    deathlogContentFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = nil,
        tile = true, tileSize = 16, edgeSize = 0,
        insets = { left = 4, right = 4, top = 4, bottom = 4, }
    })
    deathlogContentFrame:SetBackdropColor(0.5, 0, 0, 1)

    -- Move existing logList content into LogFrame
    local logList = CreateFrame("Frame", nil, UIParent)
    logList:SetParent(DeathLogFrame)
    logList:ClearAllPoints()
    logList:SetPoint("TOPLEFT", deathlogContentFrame, "TOPLEFT", 20, -20)
    logList:SetWidth(550)
    logList:SetHeight(340)

    -- Store frame references
    SSR.frames.DeathLogFrame = DeathLogFrame
    SSR.frames.deathlogScrollFrame = deathlogScrollFrame
    SSR.frames.deathlogFauxScroll = deathlogFauxScroll
    SSR.frames.deathlogContentFrame = deathlogContentFrame
    SSR.frames.logList = logList
    
    -- Populate death logs
    SSR.PopulateDeathLogs()
end
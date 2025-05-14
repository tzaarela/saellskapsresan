-- ui/stats.lua
-- Stats UI

Saellskapsresan = Saellskapsresan or {}
local SSR = Saellskapsresan

-- Create the stats layout
function SSR.CreateStatsLayout()
    -- Stats Frame
    local StatsFrame = CreateFrame("Frame", "StatsFrame", SSR.frames.MainFrame)
    StatsFrame:SetAllPoints(SSR.frames.MainFrame)
    
    local statsFrameBg = StatsFrame:CreateTexture(nil, "BACKGROUND")
    statsFrameBg:SetAllPoints(StatsFrame)
    statsFrameBg:SetTexture(SSR.UI.navWindowColor.r, SSR.UI.navWindowColor.g, SSR.UI.navWindowColor.b, SSR.UI.navWindowColor.a)

    StatsFrame:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })

    StatsFrame:SetPoint("TOPLEFT", SSR.frames.MainFrame, "TOPLEFT", 15, -75)
    StatsFrame:SetPoint("BOTTOMRIGHT", SSR.frames.MainFrame, "BOTTOMRIGHT", -15, 50)
    StatsFrame:Hide()

    local statsText = StatsFrame:CreateFontString(nil, "OVERLAY")
    statsText:SetFont(SSR.UI.StandardTextFont.font, SSR.UI.StandardTextFont.size, SSR.UI.StandardTextFont.flags)
    statsText:SetPoint("TOPLEFT", 20, -20)
    statsText:SetText("Under konstruktion, återkom senare.")
    
    -- Store frame reference
    SSR.frames.StatsFrame = StatsFrame
end
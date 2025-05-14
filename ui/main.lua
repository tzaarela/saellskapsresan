-- ui/main.lua
-- Main UI frame

Saellskapsresan = Saellskapsresan or {}
local SSR = Saellskapsresan

-- Create the main window layout
function SSR.CreateMainLayout()
    if SSR.frames.MainFrame and SSR.frames.MainFrame:IsShown() then
        return
    end

    -- Main Frame
    local MainFrame = CreateFrame("Frame", "SallskaModMainFrame", UIParent)
    MainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    MainFrame:SetWidth(SSR.UI.mainWindowWidth)
    MainFrame:SetHeight(SSR.UI.mainWindowHeight)
    MainFrame:SetFrameStrata("DIALOG")

    local mainBg = MainFrame:CreateTexture(nil, "BACKGROUND")
    mainBg:SetAllPoints(MainFrame)
    mainBg:SetTexture(SSR.UI.mainWindowColor.r, SSR.UI.mainWindowColor.g, SSR.UI.mainWindowColor.b, SSR.UI.mainWindowColor.a) 

    MainFrame:SetBackdrop({
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })

    MainFrame:EnableMouse(true)
    MainFrame:SetMovable(true)
    MainFrame:SetUserPlaced(true)
    MainFrame:RegisterForDrag("LeftButton")
    MainFrame:SetScript("OnDragStart", function() MainFrame:StartMoving() end)
    MainFrame:SetScript("OnDragStop", function() MainFrame:StopMovingOrSizing() end)

    -- Title
    local title = MainFrame:CreateFontString(nil, "OVERLAY")
    title:SetFont(SSR.UI.Header1Font.font, SSR.UI.Header1Font.size, SSR.UI.Header1Font.flags)
    title:SetText("Sällskapsresan Mod v" .. SSR.addonVersion)
    title:SetPoint("TOP", 0, -24)
    
    -- Store the frame reference
    SSR.frames.MainFrame = MainFrame
end
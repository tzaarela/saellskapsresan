-- ui/start.lua
-- Start screen UI

Saellskapsresan = Saellskapsresan or {}
local SSR = Saellskapsresan

-- Create the start screen layout
function SSR.CreateStartLayout()
    -- START Frame
    local StartFrame = CreateFrame("Frame", "StartFrame", SSR.frames.MainFrame)
    StartFrame:SetAllPoints(SSR.frames.MainFrame)

    local startFrameBg = StartFrame:CreateTexture(nil, "BACKGROUND")
    startFrameBg:SetAllPoints(StartFrame)
    startFrameBg:SetTexture(SSR.UI.navWindowColor.r, SSR.UI.navWindowColor.g, SSR.UI.navWindowColor.b, SSR.UI.navWindowColor.a)

    StartFrame:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })

    StartFrame:SetPoint("TOPLEFT", SSR.frames.MainFrame, "TOPLEFT", 15, -75)
    StartFrame:SetPoint("BOTTOMRIGHT", SSR.frames.MainFrame, "BOTTOMRIGHT", -15, 50)
    
    local infoText = StartFrame:CreateFontString(nil, "OVERLAY")
    infoText:SetFont(SSR.UI.StandardTextFont.font, SSR.UI.StandardTextFont.size, SSR.UI.StandardTextFont.flags)
    infoText:SetPoint("TOPLEFT", 20, -20)
    infoText:SetText("Välkommen till Sällskapsresan!\n\n Detta är ett addon under konstruktion så förvänta er att det kan strula. \n \n Guildregler:\n\n -Addonet måste alltid vara aktivt när man är online  \n -Dör man får man inte ta samma namn igen \n")
    infoText:SetJustifyH("LEFT")
    
    local logo = StartFrame:CreateTexture(nil, "OVERLAY")
    logo:SetPoint("BOTTOMLEFT", StartFrame, "BOTTOMLEFT", 20, 20)  -- adjust offsets as needed
    logo:SetTexture("Interface\\AddOns\\SaellskapsresanMod\\Art\\hardcore.blp")
    logo:SetWidth(128)
    logo:SetHeight(128) -- adjust size as needed
    
    -- Store the frame reference
    SSR.frames.StartFrame = StartFrame
end
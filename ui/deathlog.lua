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

    -- Set the OnShow script handler
    DeathLogFrame:SetScript("OnShow", function(self)
        SSR.DeathLogScrollUpdate()
    end)

    -- Create a simple container frame)
    local deathLogContainer = CreateFrame("Frame", "deathLogContainer", DeathLogFrame)
    deathLogContainer:SetPoint("TOPLEFT", DeathLogFrame, "TOPLEFT", 20, -20)
    deathLogContainer:SetPoint("BOTTOMRIGHT", DeathLogFrame, "BOTTOMRIGHT", -35, 20)
    deathLogContainer:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })

    -- Create header text
    local headerText = deathLogContainer:CreateFontString(nil, "OVERLAY")
    headerText:SetFont(SSR.UI.Header3Font.font, SSR.UI.Header3Font.size, SSR.UI.Header3Font.flags)
    headerText:SetPoint("TOPLEFT", deathLogContainer, "TOPLEFT", 10, -10)
    headerText:SetText("Rip †")

    -- Move existing logList content into LogFrame
    SSR.CreateScrollFrameRows(deathLogContainer, "DeathLogRow", false)
    
    -- Create the scroll frame LAST, after all content is created
    local scrollFrame = CreateFrame("ScrollFrame", "deathLogScrollFrame", deathLogContainer, "FauxScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", deathLogContainer, "TOPLEFT", 5, -35)
    scrollFrame:SetPoint("BOTTOMRIGHT", deathLogContainer, "BOTTOMRIGHT", -30, 10)
    
    -- Set the OnVerticalScroll handler
    scrollFrame:SetScript("OnVerticalScroll", function()
        -- The simplest possible implementation for Vanilla WoW
        FauxScrollFrame_OnVerticalScroll(SSR.ProfessionSettings.rowHeight, SSR.DeathLogScrollUpdate) 
    end)

    -- Store frame references
    SSR.frames.DeathLogFrame = DeathLogFrame
    SSR.frames.deathLogScrollFrame = scrollFrame
    SSR.frames.deathLogContainer = deathLogContainer
end

-- Populate death logs in the UI
function SSR.DeathLogScrollUpdate()
    -- Collect data
    local dataTable = {}
    if DeathLoggerDB then
         for i, entry in ipairs(DeathLoggerDB or {}) do
            if entry ~= nil then
                table.insert(dataTable, {
                    key = i,
                    entry = entry
                })
            end
        end
    end

    local totalEntries = table.getn(dataTable) 

    SSR.UpdateScrollFrameRows(SSR.frames.deathLogScrollFrame, dataTable, "DeathLogRow", totalEntries)
end
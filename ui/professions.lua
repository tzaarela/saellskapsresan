-- ui/professions.lua
-- Professions UI

Saellskapsresan = Saellskapsresan or {}
local SSR = Saellskapsresan

-- Create the character professions layout
function SSR.CreateCharacterProfessionsLayout()
    -- Create profession frame
    local ProfessionsFrame = CreateFrame("Frame", "ProfessionsFrame", SSR.frames.MainFrame)
    ProfessionsFrame:SetAllPoints(SSR.frames.MainFrame)
    
    local proffFrameBg = ProfessionsFrame:CreateTexture(nil, "BACKGROUND")
    proffFrameBg:SetAllPoints(ProfessionsFrame)
    proffFrameBg:SetTexture(SSR.UI.navWindowColor.r, SSR.UI.navWindowColor.g, SSR.UI.navWindowColor.b, SSR.UI.navWindowColor.a)
    
    ProfessionsFrame:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    
    ProfessionsFrame:SetPoint("TOPLEFT", SSR.frames.MainFrame, "TOPLEFT", 15, -75)
    ProfessionsFrame:SetPoint("BOTTOMRIGHT", SSR.frames.MainFrame, "BOTTOMRIGHT", -15, 50)
    ProfessionsFrame:Hide()
    
    -- Set the OnShow script handler
    ProfessionsFrame:SetScript("OnShow", function(self)
        SSR.ProfessionsScrollUpdate()
    end)

    -- Create a simple container frame
    local professionContainer = CreateFrame("Frame", "professionsContainer", ProfessionsFrame)
    professionContainer:SetPoint("TOPLEFT", ProfessionsFrame, "TOPLEFT", 20, -20)
    professionContainer:SetPoint("BOTTOMRIGHT", ProfessionsFrame, "BOTTOMRIGHT", -35, 20)
    professionContainer:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    
    -- Create header text
    local headerText = professionContainer:CreateFontString(nil, "OVERLAY")
    headerText:SetFont(SSR.UI.Header3Font.font, SSR.UI.Header3Font.size, SSR.UI.Header3Font.flags)
    headerText:SetPoint("TOPLEFT", professionContainer, "TOPLEFT", 10, -10)
    headerText:SetText("Character")
    
    local headerText2 = professionContainer:CreateFontString(nil, "OVERLAY")
    headerText2:SetFont(SSR.UI.Header3Font.font, SSR.UI.Header3Font.size, SSR.UI.Header3Font.flags)
    headerText2:SetPoint("TOPLEFT", professionContainer, "TOPLEFT", 130, -10)
    headerText2:SetText("Professions")
    
    SSR.CreateScrollFrameRows(professionContainer, "ProfessionRow", true)
    
    -- Create the scroll frame LAST, after all content is created
    local scrollFrame = CreateFrame("ScrollFrame", "ProfessionsScrollFrame", professionContainer, "FauxScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", professionContainer, "TOPLEFT", 5, -35)
    scrollFrame:SetPoint("BOTTOMRIGHT", professionContainer, "BOTTOMRIGHT", -30, 10)
    
    -- Set the OnVerticalScroll handler
    scrollFrame:SetScript("OnVerticalScroll", function()
        -- The simplest possible implementation for Vanilla WoW
        FauxScrollFrame_OnVerticalScroll(SSR.ProfessionSettings.rowHeight, SSR.ProfessionsScrollUpdate) 
    end)
    
    -- Store references for later use
    SSR.frames.ProfessionsFrame = ProfessionsFrame
    SSR.frames.professionContainer = professionContainer
    SSR.frames.professionsScrollFrame = scrollFrame
end

-- Update function for profession scroll
function SSR.ProfessionsScrollUpdate()
    -- Collect data
    local dataTable = {}
    if CharacterProfessionsDB then
        for character, profData in pairs(CharacterProfessionsDB) do
            if profData ~= nil then
                table.insert(dataTable, {
                    key = character,
                    entry = profData
                })
            end
        end
    end
    
    local totalEntries = table.getn(dataTable) 

    -- Sort Data By EntryName A-Z
    for i = 1, totalEntries do
        for j = 1, totalEntries - i do
            if dataTable[j].key > dataTable[j + 1].key then
                dataTable[j], dataTable[j + 1] = dataTable[j + 1], dataTable[j]
            end
        end
    end
    
    SSR.UpdateScrollFrameRows(SSR.frames.professionsScrollFrame, dataTable, "ProfessionRow", totalEntries)
end
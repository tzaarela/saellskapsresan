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
    local professionContainer = CreateFrame("Frame", "ProfessionsContainer", ProfessionsFrame)
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
    
    for i = 1, SSR.ProfessionSettings.maxDisplayed do
        local row = CreateFrame("Frame", "ProfRow"..i, professionContainer)
        row:SetHeight(SSR.ProfessionSettings.rowHeight)
        row:SetWidth(professionContainer:GetWidth() - 30) -- Leave room for scrollbar
        row:SetPoint("TOPLEFT", professionContainer, "TOPLEFT", 10, -35 - ((i-1) * SSR.ProfessionSettings.rowHeight))
        
        -- Make rows visible for debugging
        row:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            tile = true
        })
        
        -- Alternate row colors
        if math.mod(i, 2) == 0 then
            row:SetBackdropColor(0.1, 0.1, 0.1, 0.3)
        else
            row:SetBackdropColor(0.2, 0.2, 0.2, 0.2)
        end
        
        -- Character name text
        row.nameText = row:CreateFontString(nil, "OVERLAY")
        row.nameText:SetFont(SSR.UI.StandardTextFont.font, SSR.UI.StandardTextFont.size, SSR.UI.StandardTextFont.flags)
        row.nameText:SetPoint("LEFT", row, "LEFT", 5, 0)
        row.nameText:SetText("") -- Will be set in update function
        
        -- Profession text
        row.profText = row:CreateFontString(nil, "OVERLAY")
        row.profText:SetFont(SSR.UI.StandardTextFont.font, SSR.UI.StandardTextFont.size, SSR.UI.StandardTextFont.flags)
        row.profText:SetPoint("LEFT", row, "LEFT", 120, 0)
        row.profText:SetText("") -- Will be set in update function
        
        row:Hide() -- Initially hidden
    end
    
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
                    name = character,
                    profData = profData
                })
            end
        end
    end
    
    -- Sort data (simple bubble sort for Lua 5.0 compatibility)
    local totalEntries = table.getn(dataTable)
    for i = 1, totalEntries do
        for j = 1, totalEntries - i do
            if dataTable[j].name > dataTable[j + 1].name then
                dataTable[j], dataTable[j + 1] = dataTable[j + 1], dataTable[j]
            end
        end
    end
    
    -- Constants
    local maxDisplayed = SSR.ProfessionSettings.maxDisplayed
    local rowHeight = SSR.ProfessionSettings.rowHeight
    
    -- Update the scroll frame
    FauxScrollFrame_Update(SSR.frames.professionsScrollFrame, totalEntries, maxDisplayed, rowHeight)
    
    -- Get current offset
    local offset = FauxScrollFrame_GetOffset(SSR.frames.professionsScrollFrame)
    -- print("Current offset: " .. offset .. " Total entries: " .. totalEntries .. " maxDisplayed: " .. maxDisplayed .. " rowHeight: " .. rowHeight)
    
    -- Update row visibility and content
    for i = 1, maxDisplayed do
        local row = getglobal("ProfRow" .. i)
        local dataIndex = i + offset
        
        if dataIndex <= totalEntries then
            local entry = dataTable[dataIndex]
            
            -- Set text
            row.nameText:SetText(entry.name)

            local profText = "No data"
            if type(entry.profData) == "table" and entry.profData.professionString then
                profText = entry.profData.professionString
            elseif type(entry.profData) == "string" then
                profText = entry.profData
            end
            row.profText:SetText(profText)
            -- Show the row
            row:Show()
            -- print("Showing row " .. i .. " with data index " .. dataIndex)
            -- print("Name: " .. entry.name)
            -- print("professions: " .. profText)

        else
            -- Hide rows without data
            -- print("Hiding row " .. i .. " with data index " .. dataIndex)

            row:Hide()
        end
    end
end
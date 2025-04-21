--Sällskapsresan Mod v0.2 - Made by Tzaa 
local addonVersion = "0.2";

-- Register frames
local systemFrame = CreateFrame("Frame", "SaellskapsresanSystemFrame")

--Register Events
systemFrame:RegisterEvent("ADDON_LOADED")
systemFrame:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH")
systemFrame:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS")
systemFrame:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_SELF_SPELL_DAMAGE")
systemFrame:RegisterEvent("PLAYER_DEAD")
systemFrame:RegisterEvent("PLAYER_LOGOUT")
systemFrame:RegisterEvent("PLAYER_LOGIN")
systemFrame:RegisterEvent("SKILL_LINES_CHANGED")

--Libs
local LDB = LibStub("LibDataBroker-1.1")
local icon = LibStub("LibDBIcon-1.0")

-- Initialize UI function (called in ADDON_LOADED)
InitializeSystem = function()
    CurrentCharacter = CurrentCharacter or ""
    DeathLoggerDB = DeathLoggerDB or {}
    LastLogonDB = LastLogonDB or {}
    SyncLoaded = SyncLoaded or false
    CharacterProfessionsDB = CharacterProfessionsDB or {}
    LocalCurrentCharacter = LocalCurrentCharacter or ""
    LocalDeathLoggerDB = LocalDeathLoggerDB or {}
    LocalLastLogonDB = LocalLastLogonDB or {}
    LocalSyncLoaded = LocalSyncLoaded or false
    LocalCharacterProfessionsDB = LocalCharacterProfessionsDB or {}
    print("[Sällskapsresan] v" .. addonVersion .." har initierats!")
end

-- local variables
local LastKiller = "Främmande varelse"

-- local ui-variables
local MainFrame, StartFrame, DeathLogFrame, StatsFrame, ProfessionsFrame, proffContentFrame, proffFauxScroll, proffScrollFrame, logList
local deathlogScrollFrame, deathlogContentFrame, deathlogFauxScroll

-- UI Style
local mainWindowWidth = 700
local mainWindowHeight = 500

local mainWindowColor = {r = 0, g = 0, b = 0, a = 0.9} -- Black with little transparency
local navWindowColor = {r = 0.1, g = 0.1, b = 0.1, a = 1} -- Dark gray with no transparency

local Header1Font = { layer = "OVERLAY", font = "Interface\\AddOns\\SaellskapsresanMod\\fonts\\Myriad-Pro.ttf", size = 24, flags = "OUTLINE" }
local Header2Font = { layer = "OVERLAY", font = "Interface\\AddOns\\SaellskapsresanMod\\fonts\\Myriad-Pro.ttf", size = 20, flags = "OUTLINE" }
local Header3Font = { layer = "OVERLAY", font = "Interface\\AddOns\\SaellskapsresanMod\\fonts\\Myriad-Pro.ttf", size = 18, flags = "OUTLINE" }
local StandardTextFont = { layer = "OVERLAY", font = "Interface\\AddOns\\SaellskapsresanMod\\fonts\\Myriad-Pro.ttf", size = 14, flags = "OUTLINE" }


local CreateMainLayout = function()
    if MainFrame and MainFrame:IsShown() then
        return
    end

    -- Main Frame
    MainFrame = CreateFrame("Frame", "SallskaModMainFrame", UIParent)
    MainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    MainFrame:SetWidth(mainWindowWidth)
    MainFrame:SetHeight(mainWindowHeight)
    MainFrame:SetFrameStrata("DIALOG")

    local mainBg = MainFrame:CreateTexture(nil, "BACKGROUND")
    mainBg:SetAllPoints(MainFrame)
    mainBg:SetTexture(mainWindowColor.r, mainWindowColor.g, mainWindowColor.b, mainWindowColor.a) 

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
    title:SetFont(Header1Font.font, Header1Font.size, Header1Font.flags)
    title:SetText("Sällskapsresan Mod v" .. addonVersion)
    title:SetPoint("TOP", 0, -24)
end

local CreateStartLayout = function ()

    -- START Frame
    StartFrame = CreateFrame("Frame", "StartFrame", MainFrame)
    StartFrame:SetAllPoints(MainFrame)

    local startFrameBg = StartFrame:CreateTexture(nil, "BACKGROUND")
    startFrameBg:SetAllPoints(StartFrame)
    startFrameBg:SetTexture(navWindowColor.r, navWindowColor.g, navWindowColor.b, navWindowColor.a)

    StartFrame:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })

    StartFrame:SetPoint("TOPLEFT", MainFrame, "TOPLEFT", 15, -75)
    StartFrame:SetPoint("BOTTOMRIGHT", MainFrame, "BOTTOMRIGHT", -15, 50)
    
    local infoText = StartFrame:CreateFontString(nil, "OVERLAY")
    infoText:SetFont(StandardTextFont.font, StandardTextFont.size, StandardTextFont.flags)
    infoText:SetPoint("TOPLEFT", 20, -20)
    infoText:SetText("Välkommen till Sällskapsresan!\n\n Detta är ett addon under konstruktion så förvänta er att det kan strula. \n \n Guildregler:\n\n -Addonet måste alltid vara aktivt när man är online  \n -Dör man får man inte ta samma namn igen \n")
    infoText:SetJustifyH("LEFT")
    
    local logo = StartFrame:CreateTexture(nil, "OVERLAY")
    logo:SetPoint("BOTTOMLEFT", StartFrame, "BOTTOMLEFT", 20, 20)  -- adjust offsets as needed
    logo:SetTexture("Interface\\AddOns\\SaellskapsresanMod\\UI\\hardcore.blp")
    logo:SetWidth(128)
    logo:SetHeight(128) -- adjust size as needed
end

local CreateDeathLoggerLayout = function ()
     
    -- Deathlog Frame
    DeathLogFrame = CreateFrame("Frame", "DeathLogFrame", MainFrame)
    DeathLogFrame:SetAllPoints(MainFrame)
    
    local deathlogFrameBg = DeathLogFrame:CreateTexture(nil, "BACKGROUND")
    deathlogFrameBg:SetAllPoints(DeathLogFrame)
    deathlogFrameBg:SetTexture(navWindowColor.r, navWindowColor.g, navWindowColor.b, navWindowColor.a)

    DeathLogFrame:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })

    DeathLogFrame:SetPoint("TOPLEFT", MainFrame, "TOPLEFT", 15, -75)
    DeathLogFrame:SetPoint("BOTTOMRIGHT", MainFrame, "BOTTOMRIGHT", -15, 50)
    DeathLogFrame:Hide()


    -- Create a FauxScrollFrame
    deathlogScrollFrame = CreateFrame("Frame", "ProfessionsFauxScrollFrame", DeathLogFrame)
    deathlogScrollFrame:SetPoint("TOPLEFT", DeathLogFrame, "TOPLEFT", 20, -20)
    deathlogScrollFrame:SetPoint("BOTTOMRIGHT", DeathLogFrame, "BOTTOMRIGHT", -35, 20)
    deathlogScrollFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })

    -- Create the actual scroll frame
    deathlogFauxScroll = CreateFrame("ScrollFrame", "deathlogScrollFrame", deathlogScrollFrame, "FauxScrollFrameTemplate")
    deathlogFauxScroll:SetPoint("TOPLEFT", deathlogScrollFrame, "TOPLEFT", 0, 0)
    deathlogFauxScroll:SetPoint("BOTTOMRIGHT", deathlogScrollFrame, "BOTTOMRIGHT", -16, 0)

    -- Create content frame directly inside the scrollFrame (no SetScrollChild needed)
    deathlogContentFrame = CreateFrame("Frame", "deathlogContentFrame", deathlogScrollFrame)
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
    logList = CreateFrame("Frame", nil, UIParent)
    logList:SetParent(DeathLogFrame)
    logList:ClearAllPoints()
    logList:SetPoint("TOPLEFT", deathlogContentFrame, "TOPLEFT", 20, -20)
    logList:SetWidth(550)
    logList:SetHeight(340)

    PopulateDeathLogs()
end

local CreateStatsLayout = function()
    -- Stats Frame
    StatsFrame = CreateFrame("Frame", "StatsFrame", MainFrame)
    StatsFrame:SetAllPoints(MainFrame)
    
    local statsFrameBg = StatsFrame:CreateTexture(nil, "BACKGROUND")
    statsFrameBg:SetAllPoints(StatsFrame)
    statsFrameBg:SetTexture(navWindowColor.r, navWindowColor.g, navWindowColor.b, navWindowColor.a)

    StatsFrame:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })

    StatsFrame:SetPoint("TOPLEFT", MainFrame, "TOPLEFT", 15, -75)
    StatsFrame:SetPoint("BOTTOMRIGHT", MainFrame, "BOTTOMRIGHT", -15, 50)
    StatsFrame:Hide()

    local statsText = StatsFrame:CreateFontString(nil, "OVERLAY")
    statsText:SetFont(StandardTextFont.font, StandardTextFont.size, StandardTextFont.flags)
    statsText:SetPoint("TOPLEFT", 20, -20)
    statsText:SetText("Under konstruktion, återkom senare.")
end

local CreateCharacterProfessionsLayout = function ()
    -- Professions Frame
    ProfessionsFrame = CreateFrame("Frame", "ProfessionsFrame", MainFrame)
    ProfessionsFrame:SetAllPoints(MainFrame)
    
    local proffFrameBg = ProfessionsFrame:CreateTexture(nil, "BACKGROUND")
    proffFrameBg:SetAllPoints(ProfessionsFrame)
    proffFrameBg:SetTexture(navWindowColor.r, navWindowColor.g, navWindowColor.b, navWindowColor.a)
    
    ProfessionsFrame:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })

    ProfessionsFrame:SetPoint("TOPLEFT", MainFrame, "TOPLEFT", 15, -75)
    ProfessionsFrame:SetPoint("BOTTOMRIGHT", MainFrame, "BOTTOMRIGHT", -15, 50)
    ProfessionsFrame:Hide()

    -- Create a FauxScrollFrame
    proffScrollFrame = CreateFrame("Frame", "ProfessionsFauxScrollFrame", ProfessionsFrame)
    proffScrollFrame:SetPoint("TOPLEFT", ProfessionsFrame, "TOPLEFT", 20, -20)
    proffScrollFrame:SetPoint("BOTTOMRIGHT", ProfessionsFrame, "BOTTOMRIGHT", -35, 20)
    proffScrollFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })

    -- Create the actual scroll frame
    proffFauxScroll = CreateFrame("ScrollFrame", "ProfessionsFauxScroll", proffScrollFrame, "FauxScrollFrameTemplate")
    proffFauxScroll:SetPoint("TOPLEFT", proffScrollFrame, "TOPLEFT", 0, 0)
    proffFauxScroll:SetPoint("BOTTOMRIGHT", proffScrollFrame, "BOTTOMRIGHT", -16, 0)

    -- Create content frame directly inside the scrollFrame (no SetScrollChild needed)
    proffContentFrame = CreateFrame("Frame", "ProfessionsContentFrame", proffScrollFrame)
    proffContentFrame:SetPoint("TOPLEFT", proffScrollFrame, "TOPLEFT", 0, 0)
    proffContentFrame:SetWidth(proffScrollFrame:GetWidth() - 16)  -- Adjust for scroll bar
    proffContentFrame:SetHeight(500)  -- Will be adjusted based on content

    -- Add visible background to content frame
    proffContentFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = nil,
        tile = true, tileSize = 16, edgeSize = 0,
        insets = { left = 4, right = 4, top = 4, bottom = 4, }
    })
    proffContentFrame:SetBackdropColor(0.5, 0, 0, 1)

    PopulateProfessionsTable()
end

local CreateNavigationButtons = function ()
    
    -- Navigation Buttons
    local function CreateNavButton(name, text, xOffset, onClick)
        local btn = CreateFrame("Button", nil, MainFrame, "GameMenuButtonTemplate")
        btn:SetWidth(120)
        btn:SetHeight(30)
        btn:SetPoint("TOPLEFT", MainFrame, "TOPLEFT", xOffset, -60)
        btn:SetText(text)
        btn:SetScript("OnClick", onClick)
        return btn
    end

    -- Function to set button appearance (pressed or normal)
    local function SetButtonState(button, isPressed)
        if isPressed then
            -- Pressed appearance for GameMenuButtonTemplate
            button:LockHighlight()
        else
            -- Normal appearance
            button:UnlockHighlight()
        end
    end
    
    -- Navigation Buttons --
    NavButtons = { }
    
    local function ShowFrame(frame)
        
        -- Find and highlight the correct button based on frame name
        local frameName = frame:GetName()
        for k, v in pairs(NavButtons) do
            if k == frameName then
                SetButtonState(v, true)
            else
                SetButtonState(v, false)
            end
        end

        -- Hide all frames
        StartFrame:Hide()
        DeathLogFrame:Hide()
        StatsFrame:Hide()
        ProfessionsFrame:Hide()
        
        -- Show the requested frame
        frame:Show()
        
    end
    
    -- Create navigation buttons
    local startBtn = CreateNavButton("StartBtn", "Start", 20, function() ShowFrame(StartFrame) end)
    local logBtn = CreateNavButton("LogBtn", "Dödslogg", 150, function() ShowFrame(DeathLogFrame) end)
    local statsBtn = CreateNavButton("StatsBtn", "Statistik", 280, function() ShowFrame(StatsFrame) end)
    local professionsBtn = CreateNavButton("ProfessionsBtn", "Yrken", 410, function() ShowFrame(ProfessionsFrame) end)

    -- Fill the table after buttons are created
    NavButtons["StartFrame"] = startBtn
    NavButtons["DeathLogFrame"] = logBtn
    NavButtons["StatsFrame"] = statsBtn
    NavButtons["ProfessionsFrame"] = professionsBtn

    -- Initialize with Start button pressed
    SetButtonState(startBtn, true)
    ShowFrame(StartFrame)
end

local CreateSystemButtons = function ()

     -- Close Button
     local close = CreateFrame("Button", nil, MainFrame, "GameMenuButtonTemplate")
     close:SetPoint("BOTTOMRIGHT", MainFrame, "BOTTOMRIGHT", -20, 20)
     close:SetWidth(90)
     close:SetHeight(25)
     close:SetText("Stäng")
     close:SetScript("OnClick", function() MainFrame:Hide() end)
 
     -- Reset Button
     local refresh = CreateFrame("Button", nil, MainFrame, "GameMenuButtonTemplate")
     refresh:SetPoint("BOTTOMRIGHT", MainFrame, "BOTTOMRIGHT", -120, 20)
     refresh:SetWidth(90)
     refresh:SetHeight(25)
     refresh:SetText("Ladda Om")
     refresh:SetScript("OnClick", ReloadUI)

     -- Reset Button
     local debugTest = CreateFrame("Button", nil, MainFrame, "GameMenuButtonTemplate")
     debugTest:SetPoint("BOTTOMRIGHT", MainFrame, "BOTTOMRIGHT", -220, 20)
     debugTest:SetWidth(90)
     debugTest:SetHeight(25)
     debugTest:SetText("Debug")
     debugTest:SetScript("OnClick", PopulateProfessionsTable)
 
end

-- Open the UI
OpenUI = function()
    CreateMainLayout();
    CreateStartLayout()
    CreateDeathLoggerLayout()
    CreateStatsLayout()
    CreateCharacterProfessionsLayout()
    CreateNavigationButtons()
    CreateSystemButtons()
end

-- Close the UI
CloseUI = function()
    if MainFrame then
        MainFrame:Hide()
    end
end

-- Event Handler
local deathReportSent = false
local isGameValid = false

systemFrame:SetScript("OnEvent", function()

    -- Uncomment to test all events
    -- DEFAULT_CHAT_FRAME:AddMessage("DebugEvent: " .. event, 1, 0.5, 0)
    -- DEFAULT_CHAT_FRAME:AddMessage("DebugArg1: " .. arg1, 1, 0.5, 0)
    -- DEFAULT_CHAT_FRAME:AddMessage("DebugArg2: " .. arg2, 1, 0.5, 0)

    -- Handle all initialization inside addon loaded
    if event == "ADDON_LOADED" and arg1 == "SaellskapsresanMod" and not this.loaded then

        if not SyncLoaded then
            ShowErrorPopup("Du startade inte spelet med Saellskapsresan.bat! Synkningen kommer inte fungera!");
        end

        SSR_CONFIG = SSR_CONFIG or { 
            minimap = { 
                hide = false,
                minimapPos = 225 
            } 
        }
        -- Register minimap button
        icon:Register("Saellskapsresan", Saellskaspresan.dataObject, SSR_CONFIG.minimap)

        deathReportSent = false;
        this.loaded = true
        InitializeSystem();
        
        isGameValid = ValidatePlayerLogin()
        print ("[Sällskapsresan] Allt är okej!") 
    elseif not isGameValid then
        print("[Sällskapsresan] VIKTIGT! Antingen är det första gången du loggar in, eller så har du bytt karaktär. Tryck LADDA OM i addonet eller skriv /reload")
        return
   
    elseif event == "SKILL_LINES_CHANGED" then
        -- Update when skills change
        SetCharacterProfessions()
        
        -- Update table if frame is visiblesccd
        if ProfessionsFrame and ProfessionsFrame:IsVisible() then
            PopulateProfessionsTable()
        end

    -- If we get hit by creature melee/spell hits. I use this for testing somethings.
    elseif event == "CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS" or event == "CHAT_MSG_COMBAT_CREATURE_VS_SELF_SPELL_DAMAGE" then

        local text = arg1
        local lowerText = string.lower(text)
        
        -- Match "hits" in lowercase and grab the number after
        local damage = GetFirstNumberInString(lowerText);

        local currentHealth = UnitHealth("player")

        -- DEFAULT_CHAT_FRAME:AddMessage("damage: " .. damage .. " previousHealth: " .. currentHealth .. "new health: " .. currentHealth - damage, 1, 0.5, 0)
        
        if (currentHealth < 91 and not deathReportSent) then
            print("[Sällskapsresan] Jag är ledsen, men du dog! Du kommer bli ihågkommen! Bara att resa sig upp och gå igen!")
            ReportDeath()
            deathReportSent = true
        end

        ParseKiller(arg1)
    end

        -- If player dies
    if event == "PLAYER_DEAD" and not deathReportSent then
        print("[Sällskapsresan] Jag är ledsen, men du dog! Du kommer bli ihågkommen! Bara att resa sig upp och gå igen!")
        ReportDeath()
        deathReportSent = true

        -- This does not seem to trigger. But ALT-F4 seems to save to SavedVariables either way. So maybe not neccesary.
        ReloadUI()
    end

    -- if event == "PLAYER_LOGOUT" or "PLAYER_LEAVING_WORLD" then
    --     SyncLoaded = false;
    -- end
    
end)

-- Function to record player login
ValidatePlayerLogin = function()
    
    -- Update current characters timestamp
    LocalLastLogonDB = {}
    local playerName = UnitName("player")
    local dateTime = date("%y-%m-%d %H:%M:%S")

    if playerName == tostring(CurrentCharacter) then
        LocalLastLogonDB[playerName] = dateTime
        return true
    else
        LocalCurrentCharacter = playerName
        CurrentCharacter = playerName
        ShowErrorPopup("Viktigt! Du har bytt karaktär sen du spelade sist, du måste skriva /reload eller trycka 'Ladda om' i Saellskapsresan Addonet.", "Ladda Om", ReloadUI);
        return false
    end 
end

function PopulateProfessionsTable()

    -- Clear previous entries but NOT the header
    local children = { proffContentFrame:GetChildren() }
    for _, child in ipairs(children) do
        if child:GetName() ~= "ProfessionsHeader" then
            child:Hide()
        end
    end
    
    -- Create header if it doesn't exist
    local headerRow = getglobal("ProfessionsHeader") or CreateFrame("Frame", "ProfessionsHeader", proffContentFrame)
    if headerRow:GetParent() ~= proffContentFrame then
        headerRow:SetParent(proffContentFrame)
    end
    
    headerRow:SetHeight(25)
    headerRow:SetWidth(proffContentFrame:GetWidth())
    headerRow:SetPoint("TOPLEFT", proffContentFrame, "TOPLEFT", 10, -10)
    
    -- IMPORTANT: Explicitly show the header
    headerRow:Show()
    
    -- Create header text
    if not headerRow.characterTitle then
        headerRow.characterTitle = headerRow:CreateFontString(nil, "OVERLAY")
        headerRow.characterTitle:SetFont(Header3Font.font, Header3Font.size, Header3Font.flags)
        headerRow.characterTitle:SetPoint("TOPLEFT", headerRow, "TOPLEFT", 5, -5)
        headerRow.characterTitle:SetText("Character")
        
        headerRow.professionsTitle = headerRow:CreateFontString(nil, "OVERLAY")
        headerRow.professionsTitle:SetFont(Header3Font.font, Header3Font.size, Header3Font.flags)
        headerRow.professionsTitle:SetPoint("TOPLEFT", headerRow, "TOPLEFT", 120, -5)
        headerRow.professionsTitle:SetText("Professions")
    end
    
    -- IMPORTANT: Explicitly show the text elements
    headerRow.characterTitle:Show()
    headerRow.professionsTitle:Show()
    
    -- Table rows
    local yOffset = -30
    local rowHeight = 20
    local numRows = 0
    
    -- FauxScrollFrame setup
    local maxDisplayedRows = math.floor((proffContentFrame:GetHeight() - 30) / (rowHeight + 2))
    local totalRows = 0
    
    -- Count total entries
    if CharacterProfessionsDB then
        for _ in pairs(CharacterProfessionsDB) do
            totalRows = totalRows + 1
        end
    end
    
    -- Update FauxScrollFrame
    FauxScrollFrame_Update(proffFauxScroll, totalRows, maxDisplayedRows, rowHeight)
    local offset = FauxScrollFrame_GetOffset(proffFauxScroll)
    
    -- print("Total rows: " .. totalRows)
    -- print("Max displayed rows: " .. maxDisplayedRows)
    -- print("Scroll offset: " .. offset)


    -- Get data from saved variables
    if CharacterProfessionsDB then
        local index = 0
        for character, profData in pairs(CharacterProfessionsDB) do

            if (profData ~= nil) then
                
                index = index + 1
                
                -- Only show rows that are in view based on scroll position
                if index > offset and numRows < maxDisplayedRows then
                    numRows = numRows + 1
                    
                    -- Create or reuse a row
                    local rowName = "ProfRow"..numRows
                    local row = getglobal(rowName)
                    if not row then
                        -- print("Creating new row: " .. rowName)
                        row = CreateFrame("Frame", rowName, proffContentFrame)
                    else
                        -- print("Reusing existing row: " .. rowName)
                        -- Make sure it's properly parented
                        if row:GetParent() ~= proffContentFrame then
                            row:SetParent(proffContentFrame)
                        end
                    end
                    
                    -- IMPORTANT: Explicitly show the row
                    row:Show()
                    
                    -- Update row position
                    row:SetHeight(rowHeight)
                    row:SetWidth(proffContentFrame:GetWidth())
                    row:SetPoint("TOPLEFT", proffContentFrame, "TOPLEFT", 10, yOffset - 10)
                    
                    -- Background for alternate rows
                    if math.mod(numRows, 2) == 0 then
                        row:SetBackdrop({
                            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
                            tile = true
                        })
                        row:SetBackdropColor(0.1, 0.1, 0.1, 0.2)
                    else
                        row:SetBackdrop(nil)
                    end
                    
                    -- Character name
                    if not row.nameText then
                        row.nameText = row:CreateFontString(nil, "OVERLAY")
                        row.nameText:SetFont(StandardTextFont.font, StandardTextFont.size, StandardTextFont.flags)
                        row.nameText:SetPoint("TOPLEFT", row, "TOPLEFT", 5, 0)
                    end
                    row.nameText:SetText(character)
                    
                    -- Make sure nameText is shown
                    row.nameText:Show()
                    
                    -- Profession data
                    if not row.profText then
                        row.profText = row:CreateFontString(nil, "OVERLAY")
                        row.profText:SetFont(StandardTextFont.font, StandardTextFont.size, StandardTextFont.flags)
                        row.profText:SetPoint("TOPLEFT", row, "TOPLEFT", 120, 0)
                    end
                    
                    local profText = "No data"
                    if type(profData) == "table" and profData.professionString then
                        profText = profData.professionString
                    elseif type(profData) == "string" then
                        profText = profData
                    end
                    row.profText:SetText(profText)
                    
                    -- Make sure profText is shown
                    row.profText:Show()
                    
                    yOffset = yOffset - (rowHeight + 2)
                end
            end
        end
    else
        -- Add a "no data" row
        local noDataText = proffContentFrame:CreateFontString(nil, "OVERLAY")
        noDataText:SetFont(StandardTextFont.font, StandardTextFont.size, StandardTextFont.flags)
        noDataText:SetPoint("TOP", proffContentFrame, "TOP", 0, -50)
        noDataText:SetText("No profession data available")
    end
end

-- Helper function to check if a profession is primary
local function IsProfession(skillName)
    local primaryProfessions = {
        "Alchemy", "Blacksmithing", "Enchanting", "Engineering",
        "Herbalism", "Leatherworking", "Mining", "Skinning",
        "Tailoring", "Jewelcrafting", "Cooking", "First Aid"
    }
    
    for _, profession in ipairs(primaryProfessions) do
        if skillName == profession then
            return true
        end
    end
    
    return false
end

function SetCharacterProfessions()
    local playerName = UnitName("player")
    local primaryProfessions = {}
    local outputString = ""
    
    -- Loop through all skills
    for i = 1, GetNumSkillLines() do
        local skillName, isHeader, _, skillRank, _, _, maxRank = GetSkillLineInfo(i)
        
        -- If not a header and is a primary profession
        if not isHeader and IsProfession(skillName) then
            local profData = skillName .. ": " .. skillRank .. "/" .. maxRank
            table.insert(primaryProfessions, profData)
        end
    end
    
    if next(primaryProfessions) == nil then
        return
    end

    -- Add primary professions to the output string
    for _, profData in ipairs(primaryProfessions) do
        outputString = outputString .. profData .. " | "
    end

    -- Get current timestamp
    local lastModified = date("%Y-%m-%d %H:%M:%S")
    
    -- Create data table with outputString and lastModified
    local characterData = {
        professionString = outputString,
        lastModified = lastModified
    }
    
    -- Save to stored variables
    if LocalCharacterProfessionsDB == nil then
        LocalCharacterProfessionsDB = {}
    end
    
    LocalCharacterProfessionsDB[playerName] = characterData
    CharacterProfessionsDB[playerName] = characterData
end


function SendRandomDeathMessage(level, killer)
    local messages = {
        -- Heroic
        function()
            return string.format(
                "Jag föll vid level [%d], men mitt mod var större än %s:s styrka. Mitt namn ska minnas – och min återkomst frukta!",
                level, killer
            )
        end,
        -- Salty
        function()
            return string.format(
                "Jaha, där dog jag... Level [%d], rippad av förbannade %s. Jag skyller på lagg. Vi ses i nästa liv – kanske.",
                level, killer
            )
        end,
        -- Heroic with fantasy touch
        function()
            return string.format(
                "Vid level [%d] har min själ funnit vägen till Valhalla, nedslagen av %s. Men mina förfäders andar för mig tillbaka, starkare än någonsin!",
                level, killer
            )
        end,
        -- Salty with fantasy touch
        function()
            return string.format(
                "Level [%d] och jag blir dödad av en %s?! Vilken skam! Nästa gång ska jag kasta en förbannelse över dig som får dina vapen att rosta och din rustning att krympa!",
                level, killer
            )
        end,
        -- Heroic
        function()
            return string.format(
                "Mitt öde skrevs vid level [%d], där %s besegrade min kropp men aldrig min ande. Jag återvänder som en storm över slagfältet!",
                level, killer
            )
        end,
        -- Heroic with fantasy touch
        function()
            return string.format(
                "Vid level [%d] föll jag inför %s, men de gamla profetiorna talar om min återkomst. De säger att askan från de fallna kommer bli till en phoenix!",
                level, killer
            )
        end,
        -- Salty with fantasy touch
        function()
            return string.format(
                "Level [%d] och nedslagen av %s... Jag svär vid alla skogsalver att min klan kommer hämnas detta! Förvänta dig en armé av odöda vid din port innan gryningen!",
                level, killer
            )
        end,
        -- Heroic
        function()
            return string.format(
                "Vid level [%d] föll jag med ära, medan %s stod segrande. Men legenderna säger att hjältar aldrig dör, de vilar bara en stund!",
                level, killer
            )
        end,
        -- Salty
        function()
            return string.format(
                "Seriöst? Döda mig på level [%d], %s? Jag hade inte ens mina bästa skills aktiva! Nästa gång ska jag visa dig vad en riktig krigare kan göra!",
                level, killer
            )
        end,
        -- Heroic with fantasy touch
        function()
            return string.format(
                "Vid level [%d] blev jag besegrad av %s, men min själ är bunden till den eviga flamman. Jag återvänder med kraften från de uråldriga drakarna!",
                level, killer
            )
        end,
        -- Salty with fantasy touch
        function()
            return string.format(
                "Level [%d]... Dödad av %s... Mina förfäder skrattar åt mig från andevärlden just nu. Nästa gång tar jag med mig min förtrollade yxa istället för detta patetiska träsvärd!",
                level, killer
            )
        end
    }
    -- Lua 5.0 doesn't have math.randomseed(os.time()) by default on some versions, but it's safe to call
    math.randomseed(GetTime() * 1000)  -- Use WoW API GetTime() for a seed
    local pick = math.random(1, messages)
    local msg = messages[pick]()
    SendChatMessage(msg, "GUILD")
end

-- Utility function to check if a table contains a value
local function TableContains(t, value)
    for _, v in ipairs(t) do
        if v == value then
            return true
        end
    end
    return false
end
    
local classColors = {
    ["WARRIOR"] = "C79C6E",
    ["PALADIN"] = "F48CBA",
    ["HUNTER"]  = "AAD372",
    ["ROGUE"]   = "FFF468",
    ["PRIEST"]  = "FFFFFF",
    ["SHAMAN"]  = "0070DD",
    ["MAGE"]    = "3FC7EB",
    ["WARLOCK"] = "8788EE",
    ["DRUID"]   = "FF7C0A",
}

function GetColorFromClassName(class)
    class = string.upper(class) 
    local hex = classColors[class]
    if hex then
        return "|cFF" .. hex
    else
        return class
    end
end

-- Send message and report when dead
ReportDeath = function()
    local timestamp = date("%y-%m-%d %H:%M:%S")
    local level = UnitLevel("player") or "??"
    local playerName = UnitName("player")
    local zone = GetZoneText()
    local killer = LastKiller or "en främmande varelse"
    local playerClass = UnitClass("player")
    -- local classColor = GetColorFromClassName(playerClass)
    
    local deathMessageTable = {
        zone = zone,
        killer = killer,
        level = level,
        playerClass = playerClass,
        playerName = playerName,
        timestamp = timestamp
    }

    if not TableContains(LocalDeathLoggerDB, deathMessageTable) then
        table.insert(LocalDeathLoggerDB, deathMessageTable)
    end
    
    -- TODO - Finish print guild message or some kind of dramatic announcment that guild member died 
    -- SendChatMessage(CreateRandomGuildDeathMessage(level, killer))
    -- DEFAULT_CHAT_FRAME:AddMessage(deathMessage, 1, 0.5, 0)
end

function PopulateDeathLogs()
    local deathFontStrings = {}
    -- Ensure the deathFontStrings table exists
    if not deathFontStrings then
        deathFontStrings = {}  -- Initialize the table if it doesn't exist
    end

    -- Clear existing font strings from the UI
    for _, fontString in ipairs(deathFontStrings) do
        fontString:SetText("")       -- Clear the text
        fontString:Hide()            -- Optionally hide it
        fontString:SetParent(nil)    -- Remove from frame hierarchy
    end

    -- Clear the tracking table
    for k in pairs(deathFontStrings) do
        deathFontStrings[k] = nil  -- Clear each key-value pair
    end

    local yOffset = -20
    local spacing = 20
    
    -- Rebuild the UI from current DB with new structure
    -- print("[Sällskapsresan] Uppdaterar " .. tostring(GetTableLength(DeathLoggerDB)) .. "st dödsfall i dödslistan" );
    
    for i, entry in ipairs(DeathLoggerDB or {}) do
        local fontString = logList:CreateFontString("deathEntry"..i, "OVERLAY")
        fontString:SetFont(StandardTextFont.font, StandardTextFont.size, StandardTextFont.flags)
        fontString:SetPoint("TOPLEFT", 0, yOffset - ((i - 1) * spacing) + 20)
        
        -- Format the death entry text with the new structure
        local formattedText = entry.timestamp .. " - " .. "(" .. "|cFFFFFF00" .. entry.accountName .. "|r) - " ..  
                              GetColorFromClassName(entry.playerClass) .. entry.playerName .. "|r".. " (" .. "Level " .. 
                              entry.level .. ") blev dräpt av " .. 
                              "|cFFFF0000" .. entry.killer .. "|r" .. " i " .. 
                              entry.zone
        
        fontString:SetText(formattedText)
        fontString:Show()
        table.insert(deathFontStrings, fontString) -- Track it
    end
end

function GetTableLength(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

function ParseKillerName(msg)
    local name

    -- Match "Young Wolf hits you for 237."
    local start, finish = string.find(msg, "^([%w%s%-]+) hits you")
    if start then
        name = string.sub(msg, 1, finish - string.len(" hits you"))  -- Remove ' hits you'
        return name
    end

    -- Match "Young Wolf crits you for 812."
    start, finish = string.find(msg, "^([%w%s%-]+) crits you")
    if start then
        name = string.sub(msg, 1, finish - string.len(" crits you"))  -- Remove ' crits you'
        return name
    end

    -- Match "Skeleton Mage's Frostbolt hits you for 157."
    start, finish = string.find(msg, "^([%w%s%-]+)'s")
    if start then
        name = string.sub(msg, 1, finish - string.len("'s"))  -- Remove "'s"
        return name
    end

    return "Unknown"
end

--- Simple pattern parser for kills
function ParseKiller(hitMessage)
    if hitMessage then
        LastKiller = ParseKillerName(hitMessage)
    end
end

function GetFirstNumberInString(text)
    for i = 1, string.len(text) do
        local c = string.sub(text, i, i)
        local byte = string.byte(c)
        -- Print each character and its ASCII code
        -- (Uncomment the line below for debugging in WoW chat)
        -- DEFAULT_CHAT_FRAME:AddMessage("Char: " .. c .. " (" .. byte .. ")")

        if byte >= 48 and byte <= 57 then  -- ASCII '0' to '9'
            local numberStr = c
            local j = i + 1
            while j <= string.len(text) do
                local nextChar = string.sub(text, j, j)
                local nextByte = string.byte(nextChar)
                if nextByte >= 48 and nextByte <= 57 then
                    numberStr = numberStr .. nextChar
                    j = j + 1
                else
                    break
                end
            end

            -- DEFAULT_CHAT_FRAME:AddMessage("Converted to DamageNumber: " .. numberStr)
            return tonumber(numberStr)
        end
    end

    -- DEBUG: Show that nothing was found
    -- DEFAULT_CHAT_FRAME:AddMessage("No DamageNumber found in: " .. text)
    return nil
end

function ShowErrorPopup(message, customButtonText, customFunction)
    StaticPopupDialogs["SALLSKAPSRESAN_ERROR"] = {
        text = message,
        button1 = "Ok",
        button2 = customButtonText or "Avbryt",
        timeout = 0,
        whileDead = 1,
        hideOnEscape = 1,
        preferredIndex = 3,
        OnAccept = function()
            -- This function will run when button1 ("OK") is clicked
            -- You can leave this empty or add functionality if needed
        end,
        OnCancel = function()
            -- This function will run when button2 is clicked
            if customFunction and type(customFunction) == "function" then
                customFunction()
            end
        end,
    }
    StaticPopup_Show("SALLSKAPSRESAN_ERROR")
end
-- slash Commands
SLASH_SSR1 = "/sr"
SLASH_SSR2 = "/ssr"
SLASH_SSR3 = "/sällskapsresan"
SLASH_SSR4 = "/saellskapsresan"
SlashCmdList["SSR"] = OpenUI

Saellskaspresan = {}
Saellskaspresan.dataObject = LDB:NewDataObject("Saellskapsresan", {
    type = "data source",
    text = "Saellskapsresan",
    icon = "Interface\\AddOns\\SaellskapsresanMod\\UI\\addonlogo.tga",
    OnClick = function(self, button)
        OpenUI();
    end,
    OnTooltipShow = function(tooltip)
        tooltip:AddLine("Sällskapsresan")
        tooltip:AddLine("Öppna!")
    end,
})





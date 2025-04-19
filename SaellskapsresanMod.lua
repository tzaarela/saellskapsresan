--Sällskapsresan Mod v0.1 - Made by Tzaa 
local addonVersion = "0.1";

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

-- Initialize UI function (called in ADDON_LOADED)
InitializeSystem = function()
    DeathLoggerDB = DeathLoggerDB or {}
    LastLogonDB = LastLogonDB or {}
    SyncLoaded = SyncLoaded or false
    CharacterProfessionsDB = CharacterProfessionsDB or {}
    DEFAULT_CHAT_FRAME:AddMessage("Sällskapsresan-Mod v0.1 har initierats!", 1, 0.5, 0)
end

-- UI Creation 
local MainFrame, StartFrame, DeathLogFrame, StatsFrame, ProfessionsFrame, contentFrame, fauxScroll, scrollFrame, logList

OpenUI = function()
    if MainFrame and MainFrame:IsShown() then
        return
    end

    -- === Main Frame ===
    MainFrame = CreateFrame("Frame", "SallskaModMainFrame", UIParent)
    MainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    MainFrame:SetWidth(600)
    MainFrame:SetHeight(450)
    MainFrame:SetFrameStrata("DIALOG")
    MainFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    MainFrame:SetAlpha(1)
    MainFrame:EnableMouse(true)
    MainFrame:SetMovable(true)
    MainFrame:SetUserPlaced(true)
    MainFrame:RegisterForDrag("LeftButton")
    MainFrame:SetScript("OnDragStart", function() MainFrame:StartMoving() end)
    MainFrame:SetScript("OnDragStop", function() MainFrame:StopMovingOrSizing() end)

    -- === Title ===
    local title = MainFrame:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 22, "THICKOUTLINE")
    title:SetText("Sällskapsresan Mod v" .. addonVersion)
    title:SetPoint("TOP", 0, -24)

    -- === Navigation Buttons ===
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

    -- START Frame
    StartFrame = CreateFrame("Frame", "StartFrame", MainFrame)
    StartFrame:SetAllPoints(MainFrame)
    StartFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    StartFrame:SetPoint("TOPLEFT", MainFrame, "TOPLEFT", 15, -75)
    StartFrame:SetPoint("BOTTOMRIGHT", MainFrame, "BOTTOMRIGHT", -15, 50)


    local infoText = StartFrame:CreateFontString(nil, "OVERLAY")
    infoText:SetFont("Fonts\\FRIZQT__.TTF", 14)
    infoText:SetPoint("TOPLEFT", 20, -20)
    infoText:SetText("Välkommen till Sällskapsresan!\n\n Detta är ett addon under konstruktion så förvänta er att det kan strula. \n \n Guildregler:\n\n -Addonet måste alltid vara aktivt när man är online  \n -Dör man får man inte ta samma namn igen \n")
    infoText:SetJustifyH("LEFT")
    
    local logo = StartFrame:CreateTexture(nil, "OVERLAY")
    logo:SetPoint("BOTTOMLEFT", StartFrame, "BOTTOMLEFT", 20, 20)  -- adjust offsets as needed
    logo:SetTexture("Interface\\AddOns\\SaellskapsresanMod\\UI\\hardcore.blp")
    logo:SetWidth(128)
    logo:SetHeight(128) -- adjust size as needed

    -- Deathlog Frame (your original UI reused)
    DeathLogFrame = CreateFrame("Frame", "DeathLogFrame", MainFrame)
    DeathLogFrame:SetAllPoints(MainFrame)
    DeathLogFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    DeathLogFrame:SetPoint("TOPLEFT", MainFrame, "TOPLEFT", 15, -75)
    DeathLogFrame:SetPoint("BOTTOMRIGHT", MainFrame, "BOTTOMRIGHT", -15, 50)
    DeathLogFrame:Hide()

    -- Move existing logList content into LogFrame
    logList = CreateFrame("Frame", nil, UIParent)
    logList:SetParent(DeathLogFrame)
    logList:ClearAllPoints()
    logList:SetPoint("TOPLEFT", DeathLogFrame, "TOPLEFT", 20, -20)
    logList:SetWidth(550)
    logList:SetHeight(340)

    -- Stats Frame
    StatsFrame = CreateFrame("Frame", "StatsFrame", MainFrame)
    StatsFrame:SetAllPoints(MainFrame)
    StatsFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    StatsFrame:SetPoint("TOPLEFT", MainFrame, "TOPLEFT", 15, -75)
    StatsFrame:SetPoint("BOTTOMRIGHT", MainFrame, "BOTTOMRIGHT", -15, 50)
    StatsFrame:Hide()

    local statsText = StatsFrame:CreateFontString(nil, "OVERLAY")
    statsText:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    statsText:SetPoint("TOPLEFT", 20, -20)
    statsText:SetText("Under konstruktion, återkom senare.")

    -- Professions Frame
    ProfessionsFrame = CreateFrame("Frame", "ProfessionsFrame", MainFrame)
    ProfessionsFrame:SetAllPoints(MainFrame)
    ProfessionsFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    ProfessionsFrame:SetPoint("TOPLEFT", MainFrame, "TOPLEFT", 15, -75)
    ProfessionsFrame:SetPoint("BOTTOMRIGHT", MainFrame, "BOTTOMRIGHT", -15, 50)
    ProfessionsFrame:Hide()

    -- Create a FauxScrollFrame
    scrollFrame = CreateFrame("Frame", "ProfessionsFauxScrollFrame", ProfessionsFrame)
    scrollFrame:SetPoint("TOPLEFT", ProfessionsFrame, "TOPLEFT", 20, -40)
    scrollFrame:SetPoint("BOTTOMRIGHT", ProfessionsFrame, "BOTTOMRIGHT", -35, 20)
    scrollFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    scrollFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.8)

    -- Create the actual scroll frame
    fauxScroll = CreateFrame("ScrollFrame", "ProfessionsFauxScroll", scrollFrame, "FauxScrollFrameTemplate")
    fauxScroll:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, 0)
    fauxScroll:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", -16, 0)

    -- Create content frame directly inside the scrollFrame (no SetScrollChild needed)
    contentFrame = CreateFrame("Frame", "ProfessionsContentFrame", scrollFrame)
    contentFrame:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, 0)
    contentFrame:SetWidth(scrollFrame:GetWidth() - 16)  -- Adjust for scroll bar
    contentFrame:SetHeight(500)  -- Will be adjusted based on content

    -- Add visible background to content frame
    contentFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = nil,
        tile = true, tileSize = 16, edgeSize = 0,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    contentFrame:SetBackdropColor(0.5, 0, 0, 0.3)  -- Red tint

    PopulateProfessionsTable()


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


    -- === Close Button ===
    local close = CreateFrame("Button", nil, MainFrame, "GameMenuButtonTemplate")
    close:SetPoint("BOTTOMRIGHT", MainFrame, "BOTTOMRIGHT", -20, 20)
    close:SetWidth(90)
    close:SetHeight(25)
    close:SetText("Stäng")
    close:SetScript("OnClick", function() MainFrame:Hide() end)

    -- === Reset Button ===
    local refresh = CreateFrame("Button", nil, MainFrame, "GameMenuButtonTemplate")
    refresh:SetPoint("BOTTOMRIGHT", MainFrame, "BOTTOMRIGHT", -120, 20)
    refresh:SetWidth(90)
    refresh:SetHeight(25)
    refresh:SetText("Ladda Om")
    refresh:SetScript("OnClick", RefreshDeathLog)

    -- === Reset Button ===
    local debugTest = CreateFrame("Button", nil, MainFrame, "GameMenuButtonTemplate")
    debugTest:SetPoint("BOTTOMRIGHT", MainFrame, "BOTTOMRIGHT", -220, 20)
    debugTest:SetWidth(90)
    debugTest:SetHeight(25)
    debugTest:SetText("Debug")
    debugTest:SetScript("OnClick", DebugPrintCharacterProfessionsDB)

    -- === Generate Death Log Data ===
    GenerateDeathLog()

    -- === Show default view ===
    
    
    
    -- Initialize with Start button pressed
    SetButtonState(startBtn, true)
    ShowFrame(StartFrame)
end

CloseUI = function()
    if MainFrame then
        MainFrame:Hide()
    end
end

-- Update Loop (uncomment below if needed and remove this parenteses)
-- systemFrame:SetScript("OnUpdate",function(s,e)

-- end);


-- Event Handler
local deathReportSent = false;

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

        deathReportSent = false;
        this.loaded = true
        InitializeSystem();
        RecordPlayerLogin()
   
    elseif event == "SKILL_LINES_CHANGED" then
        -- Update when skills change
        SetCharacterProfessions()
        
        -- Update table if frame is visible
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
        
        -- if (currentHealth < 110) then
        --     print("[Sällskapsresan] Jag är ledsen, men du dog! Du kommer bli ihågkommen! Bara att resa sig upp och gå igen!")
        --     ReportDeath()
        --     deathReportSent = true
        --     ReloadUI()
        -- end

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
RecordPlayerLogin = function()
    
    -- Update current characters timestamp
    LastLogonDB = {}
    local playerName = UnitName("player")
    local dateTime = date("%y-%m-%d %H:%M:%S")
    LastLogonDB[playerName] = dateTime
end


function DebugPrintCharacterProfessionsDB()
    print("CharacterProfessionsDB debug:")
    if not CharacterProfessionsDB then
        print("CharacterProfessionsDB is nil")
        return
    end
    
    local count = 0
    for character, data in pairs(CharacterProfessionsDB) do
        count = count + 1
        print("Character: [" .. tostring(character) .. "]")
        if type(data) == "table" then
            print("  Data is a table")
            print("  professionString: [" .. tostring(data.professionString) .. "]")
            print("  lastModified: [" .. tostring(data.lastModified) .. "]")
        else
            print("  Data type: " .. type(data))
            print("  Data: [" .. tostring(data) .. "]")
        end
    end
    
    print("Total entries:", count)
end

-- Modified populate function for FauxScrollFrame
function PopulateProfessionsTable()
    -- Clear previous entries
    local children = { contentFrame:GetChildren() }
    for _, child in ipairs(children) do
        if child:GetName() ~= "ProfessionsHeader" then  -- Keep header
            child:Hide()
            child:SetParent(nil)
        end
    end
    
    -- Create header if it doesn't exist
    local headerRow = getglobal("ProfessionsHeader") or CreateFrame("Frame", "ProfessionsHeader", contentFrame)
    if not headerRow:GetParent() then
        headerRow:SetParent(contentFrame)
    end
    
    headerRow:SetHeight(25)
    headerRow:SetWidth(contentFrame:GetWidth())
    headerRow:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, 0)
    headerRow:Show()
    
    -- Create header text
    if not headerRow.characterTitle then
        headerRow.characterTitle = headerRow:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        headerRow.characterTitle:SetPoint("TOPLEFT", headerRow, "TOPLEFT", 5, -5)
        headerRow.characterTitle:SetText("Character")
        
        headerRow.professionsTitle = headerRow:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        headerRow.professionsTitle:SetPoint("TOPLEFT", headerRow, "TOPLEFT", 120, -5)
        headerRow.professionsTitle:SetText("Professions")
    end
    
    -- Table rows
    local yOffset = -30
    local rowHeight = 20
    local numRows = 0
    
    -- FauxScrollFrame setup
    local maxDisplayedRows = math.floor((contentFrame:GetHeight() - 30) / (rowHeight + 2))
    local totalRows = 0
    
    -- Count total entries
    if CharacterProfessionsDB then
        for _ in pairs(CharacterProfessionsDB) do
            totalRows = totalRows + 1
        end
    end
    
    -- Update FauxScrollFrame
    FauxScrollFrame_Update(fauxScroll, totalRows, maxDisplayedRows, rowHeight)
    local offset = FauxScrollFrame_GetOffset(fauxScroll)
    
    -- Get data from saved variables
    if CharacterProfessionsDB then
        local index = 0
        for character, profData in pairs(CharacterProfessionsDB) do
            index = index + 1
            
            -- Only show rows that are in view based on scroll position
            if index > offset and numRows < maxDisplayedRows then
                numRows = numRows + 1
                
                -- Create or reuse a row
                local rowName = "ProfRow"..numRows
                local row = getglobal(rowName) or CreateFrame("Frame", rowName, contentFrame)
                row:SetHeight(rowHeight)
                row:SetWidth(contentFrame:GetWidth())
                row:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, yOffset)
                row:Show()
                
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
                    row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    row.nameText:SetPoint("TOPLEFT", row, "TOPLEFT", 5, 0)
                end
                row.nameText:SetText(character)
                
                -- Profession data
                if not row.profText then
                    row.profText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    row.profText:SetPoint("TOPLEFT", row, "TOPLEFT", 120, 0)
                end
                
                local profText = "No data"
                if type(profData) == "table" and profData.professionString then
                    profText = profData.professionString
                elseif type(profData) == "string" then
                    profText = profData
                end
                row.profText:SetText(profText)
                
                yOffset = yOffset - (rowHeight + 2)
            end
        end
    else
        -- Add a "no data" row
        local noDataText = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noDataText:SetPoint("TOP", contentFrame, "TOP", 0, -50)
        noDataText:SetText("No profession data available")
    end
    
    -- Hide unused rows
    for i = numRows + 1, 20 do -- Assuming we never display more than 20 rows
        local row = getglobal("ProfRow"..i)
        if row then
            row:Hide()
        end
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
    print("Setting professions for: [" .. tostring(playerName) .. "]")
    
    local primaryProfessions = {}
    local outputString = ""
    
    -- Loop through all skills
    for i = 1, GetNumSkillLines() do
        local skillName, isHeader, _, skillRank, _, _, maxRank = GetSkillLineInfo(i)
        
        -- If not a header and is a primary profession
        if not isHeader and IsProfession(skillName) then
            local profData = skillName .. ": " .. skillRank .. "/" .. maxRank
            table.insert(primaryProfessions, profData)
            print("Found profession: " .. profData)
        end
    end
    
    -- Add primary professions to the output string
    for _, profData in ipairs(primaryProfessions) do
        outputString = outputString .. profData .. " | "
    end
    print("Output string: [" .. outputString .. "]")

    -- Get current timestamp
    local lastModified = date("%Y-%m-%d %H:%M:%S")
    print("Timestamp: [" .. lastModified .. "]")
    
    -- Create data table with outputString and lastModified
    local characterData = {
        professionString = outputString,
        lastModified = lastModified
    }
    
    -- Save to stored variables
    if CharacterProfessionsDB == nil then
        print("Creating CharacterProfessionsDB")
        CharacterProfessionsDB = {}
    end
    
    print("Saving to CharacterProfessionsDB[" .. tostring(playerName) .. "]")
    CharacterProfessionsDB[playerName] = characterData
    print("Save complete")
end



local function CreateDeathLogRow(timestamp, zone, playerName, classColor, level, killer)
    local enemyColor = "|cffff0000" -- Red
    local reset = "|r"

    local log = string.format(
        "%s | %s | %s%s%s [Lvl %d] blev dräpt av %s%s%s",
        timestamp, zone,
        classColor, playerName, reset,
        level,
        enemyColor, killer, reset
    )
        return log;
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
    local classColor = GetColorFromClassName(playerClass)
    print("playerClass: " .. playerClass .. " classColor: " .. classColor)
    
    local deathMessage = CreateDeathLogRow(timestamp, zone, playerName, classColor, level, killer);

    print("[Sällskapsresan] " .. deathMessage)

    if not TableContains(DeathLoggerDB, deathMessage) then
        table.insert(DeathLoggerDB, deathMessage)
    end
    
    -- TODO - Finish print guild message or some kind of dramatic announcment that guild member died 
    -- SendChatMessage(CreateRandomGuildDeathMessage(level, killer))
    -- DEFAULT_CHAT_FRAME:AddMessage(deathMessage, 1, 0.5, 0)
end

function RefreshDeathLog()
    -- GenerateDeathLog() -- Refresh the UI
    DeathLoggerDB = { }
    ReloadUI()
    OpenUI()
end

-- Table to store references to the font strings so we can clear them later

function GenerateDeathLog()
    local deathFontStrings = {}
    -- Ensure the deathFontStrings table exists
    if not deathFontStrings then
        deathFontStrings = {}  -- Initialize the table if it doesnt exist
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
    local fontPath = "Fonts\\FRIZQT__.TTF"
    local fontSize = 11
    local fontFlags = nil

    -- Rebuild the UI from current DB
    -- print("[Sällskapsresan] Uppdaterar " .. tostring(GetTableLength(DeathLoggerDB)) .. "st dödsfall i dödslistan" );
    
    for i, entry in ipairs(DeathLoggerDB or {}) do
        local fontString = logList:CreateFontString("deathEntry"..i, "OVERLAY")
        fontString:SetFont(fontPath, fontSize, fontFlags)
        fontString:SetPoint("TOPLEFT", 0, yOffset - ((i - 1) * spacing) + 20)
        fontString:SetText(entry)
        fontString:Show()
        table.insert(deathFontStrings, fontString) -- Track it<<<<<>
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
LastKiller = "Främmande varelse"
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

function ShowErrorPopup(message)
    StaticPopupDialogs["SALLSKAPSRESAN_ERROR"] = {
        text = message,
        button1 = "OK",
        timeout = 0,
        whileDead = 1,
        hideOnEscape = 1,
        preferredIndex = 3,
    }
    StaticPopup_Show("SALLSKAPSRESAN_ERROR")
end


-- slash Commands
SLASH_SSR1 = "/sr"
SLASH_SSR2 = "/ssr"
SLASH_SSR3 = "/sällskapsresan"
SLASH_SSR4 = "/saellskapsresan"
SlashCmdList["SSR"] = OpenUI


local LDB = LibStub("LibDataBroker-1.1")
local icon = LibStub("LibDBIcon-1.0")

Saellskaspresan = {}
Saellskaspresan.dataObject = LDB:NewDataObject("Saellskapsresan", {
    type = "data source",
    text = "Saellskapsresan",
    icon = "Interface\\AddOns\\SaellskapsresanMod\\UI\\addonlogo.tga",
    OnClick = function(self, button)
        OpenUI();
    end,
    OnTooltipShow = function(tooltip)
        tooltip:AddLine("Saellskapsresan")
        tooltip:AddLine("Click to open!")
    end,
})

SSR_DB = SSR_DB or { minimap = { hide = false } }

icon:Register("Saellskapsresan", Saellskaspresan.dataObject, SSR_DB.minimap)



 -- UnitXP("debug", "breakpoint");


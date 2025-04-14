--Sällskapsresan Mod v0.1 - Made by Tzaa 
local addonVersion = "0.1";

-- Register frames
local systemFrame = CreateFrame("Frame", "SaellskapsresanSystemFrame")
local logList = CreateFrame("Frame", "SaellskapsresanModFrame", UIParent)

--Register Events
systemFrame:RegisterEvent("ADDON_LOADED")
systemFrame:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH")
systemFrame:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS")
systemFrame:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_SELF_SPELL_DAMAGE")

-- Initialize UI function (called in ADDON_LOADED)
InitializeSystem = function()
    DeathLoggerDB = DeathLoggerDB or {}
    DEFAULT_CHAT_FRAME:AddMessage("Sällskapsresan-Mod v0.1 har initierats!", 1, 0.5, 0)
end

-- UI Creation 
local MainFrame, StartFrame, LogFrame, StatsFrame

OpenUI = function()
    if MainFrame and MainFrame:IsShown() then
        return
    end

    -- === Main Frame ===
    MainFrame = CreateFrame("Frame", "SallskaModMainFrame", UIParent)
    MainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    MainFrame:SetWidth(600)
    MainFrame:SetHeight(450)
    MainFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
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

    -- === Subframe Toggle Logic ===
    local function ShowFrame(frame)
        StartFrame:Hide()
        LogFrame:Hide()
        StatsFrame:Hide()
        frame:Show()
    end

    -- === Subframes ===

    -- START Frame
    StartFrame = CreateFrame("Frame", nil, MainFrame)
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

    -- LOG Frame (your original UI reused)
    LogFrame = CreateFrame("Frame", nil, MainFrame)
    LogFrame:SetAllPoints(MainFrame)
    LogFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    LogFrame:SetPoint("TOPLEFT", MainFrame, "TOPLEFT", 15, -75)
    LogFrame:SetPoint("BOTTOMRIGHT", MainFrame, "BOTTOMRIGHT", -15, 50)
    LogFrame:Hide()

    -- Move existing logList content into LogFrame
    logList:SetParent(LogFrame)
    logList:ClearAllPoints()
    logList:SetPoint("TOPLEFT", LogFrame, "TOPLEFT", 20, -20)
    logList:SetWidth(550)
    logList:SetHeight(340)

    -- STATS Frame
    StatsFrame = CreateFrame("Frame", nil, MainFrame)
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

    -- === Navigation Buttons Hookup ===
    CreateNavButton("StartBtn", "Start", 20, function() ShowFrame(StartFrame) end)
    CreateNavButton("LogBtn", "Dödslogg", 150, function() ShowFrame(LogFrame) end)
    CreateNavButton("StatsBtn", "Statistik", 280, function() ShowFrame(StatsFrame) end)

    -- === Close Button ===
    local close = CreateFrame("Button", nil, MainFrame, "GameMenuButtonTemplate")
    close:SetPoint("BOTTOMRIGHT", MainFrame, "BOTTOMRIGHT", -20, 20)
    close:SetWidth(90)
    close:SetHeight(25)
    close:SetText("Stäng")
    close:SetScript("OnClick", function() MainFrame:Hide() end)

    -- === Reset Button (moved from uiFrame) ===
    local refresh = CreateFrame("Button", nil, MainFrame, "GameMenuButtonTemplate")
    refresh:SetPoint("BOTTOMRIGHT", MainFrame, "BOTTOMRIGHT", -120, 20)
    refresh:SetWidth(90)
    refresh:SetHeight(25)
    refresh:SetText("Refresh")
    refresh:SetScript("OnClick", RefreshDeathLog)

    -- === Generate Death Log Data ===
    GenerateDeathLog()

    -- === Show default view ===
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
systemFrame:SetScript("OnEvent", function()

    -- Uncomment to test all events
    -- DEFAULT_CHAT_FRAME:AddMessage("DebugEvent: " .. event, 1, 0.5, 0)
    -- DEFAULT_CHAT_FRAME:AddMessage("DebugArg1: " .. arg1, 1, 0.5, 0)
    -- DEFAULT_CHAT_FRAME:AddMessage("DebugArg2: " .. arg2, 1, 0.5, 0)

    -- Handle all initialization inside addon loaded
    if event == "ADDON_LOADED" and arg1 == "SaellskapsresanMod" and not this.loaded then

        this.loaded = true
        InitializeSystem();
        
    
    -- If we get hit by creature melee/spell hits. I use this for testing somethings.
    elseif event == "CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS" or event == "CHAT_MSG_COMBAT_CREATURE_VS_SELF_SPELL_DAMAGE" then

        local text = arg1
        local lowerText = string.lower(text)
        
        -- Match "hits" in lowercase and grab the number after
        local damage = GetFirstNumberInString(lowerText);

        local currentHealth = UnitHealth("player")

        DEFAULT_CHAT_FRAME:AddMessage("damage: " .. damage .. " previousHealth: " .. currentHealth .. "new health: " .. currentHealth - damage, 1, 0.5, 0)

        ParseKiller(arg1)

        if currentHealth - damage <= 125 then
            ReportDeath()
        end

        -- If player dies
    elseif event == "PLAYER_DEAD" then
        ReportDeath()
    end
end)

local function CreateDeathLogRow(timestamp, zone, name, level, killer)
    local green = "|cff00ff00"
    local red = "|cffff0000"
    local reset = "|r"

    local log = string.format(
        "%s | %s | %s%s%s [Lvl %d] blev dödad av %s%s%s",
        timestamp, zone,
        green, name, reset,
        level,
        red, killer, reset
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


-- Send message and report when dead
ReportDeath = function()
    local timestamp = date("%y-%m-%d %H:%M:%S")
            local level = UnitLevel("player") or "??"
            local playerName = UnitName("player")
            local zone = GetZoneText()
            local killer = LastKiller or "en främmande varelse"
            local deathMessage = CreateDeathLogRow(timestamp, zone,playerName, level, killer);
            DEFAULT_CHAT_FRAME:AddMessage("Du dog!")
            
            table.insert(DeathLoggerDB, deathMessage)
            DeathLoggerExport = table.concat(DeathLoggerDB, "\n")
            
            SendChatMessage(CreateRandomGuildDeathMessage(level, killer))
            DEFAULT_CHAT_FRAME:AddMessage(deathMessage, 1, 0.5, 0)
end

function RefreshDeathLog()
    DeathLoggerDB = {}
    print("Death log cleared!")
    GenerateDeathLog() -- Refresh the UI
end

-- Table to store references to the font strings so we can clear them later

function GenerateDeathLog()
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
    local fontPath = "Fonts\\FRIZQT__.TTF"
    local fontSize = 11
    local fontFlags = nil

    -- Rebuild the UI from current DB
    for i, entry in ipairs(DeathLoggerDB or {}) do
        local fontString = logList:CreateFontString("deathEntry"..i, "OVERLAY")
        fontString:SetFont(fontPath, fontSize, fontFlags)
        fontString:SetPoint("TOPLEFT", 0, yOffset - ((i - 1) * spacing) + 20)
        fontString:SetText(entry)
        fontString:Show()
        table.insert(deathFontStrings, fontString) -- Track it<<<<<>
    end
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

            DEFAULT_CHAT_FRAME:AddMessage("Converted to DamageNumber: " .. numberStr)
            return tonumber(numberStr)
        end
    end

    -- DEBUG: Show that nothing was found
    DEFAULT_CHAT_FRAME:AddMessage("No DamageNumber found in: " .. text)
    return nil
end


-- slash Commands
SLASH_SSR1 = "/sr"
SLASH_SSR2 = "/ssr"
SLASH_SSR3 = "/sällskapsresan"
SLASH_SSR4 = "/saellskapsresan"
SlashCmdList["SSR"] = OpenUI

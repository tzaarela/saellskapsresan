-- modules/death.lua
-- Death tracking functionality

Saellskapsresan = Saellskapsresan or {}
local SSR = Saellskapsresan

-- Parse killer name from combat message
function SSR.ParseKillerName(msg)
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

-- Parse killer from combat message
function SSR.ParseKiller(hitMessage)
    if hitMessage then
        SSR.LastKiller = SSR.ParseKillerName(hitMessage)
    end
end

-- Send random death message to guild
function SSR.SendRandomDeathMessage(level, killer)
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
    local pick = math.random(1, table.getn(messages))
    local msg = messages[pick]()
    SendChatMessage(msg, "GUILD")
end

-- Report player death to the database
function SSR.ReportDeath()
    local timestamp = date("%y-%m-%d %H:%M:%S")
    local level = UnitLevel("player") or "??"
    local playerName = UnitName("player")
    local zone = GetZoneText()
    local killer = SSR.LastKiller or "en främmande varelse"
    local playerClass = UnitClass("player")
    
    local deathMessageTable = {
        zone = zone,
        killer = killer,
        level = level,
        playerClass = playerClass,
        playerName = playerName,
        timestamp = timestamp
    }

    if not SSR.TableContains(LocalDeathLoggerDB, deathMessageTable) then
        table.insert(LocalDeathLoggerDB, deathMessageTable)
    end
    
    -- Uncomment to enable guild death messages
    -- SSR.SendRandomDeathMessage(level, killer)
end

-- Populate death logs in the UI
function SSR.PopulateDeathLogs()
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
    -- print("[Sällskapsresan] Uppdaterar " .. tostring(SSR.GetTableLength(DeathLoggerDB)) .. "st dödsfall i dödslistan" );
    
    for i, entry in ipairs(DeathLoggerDB or {}) do
        local fontString = SSR.frames.logList:CreateFontString("deathEntry"..i, "OVERLAY")
        fontString:SetFont(SSR.UI.StandardTextFont.font, SSR.UI.StandardTextFont.size, SSR.UI.StandardTextFont.flags)
        fontString:SetPoint("TOPLEFT", 0, yOffset - ((i - 1) * spacing) + 20)
        
        -- Format the death entry text with the new structure
        local formattedText = entry.timestamp .. " - " .. "(" .. "|cFFFFFF00" .. entry.accountName .. "|r) - " ..  
                              SSR.GetColorFromClassName(entry.playerClass) .. entry.playerName .. "|r".. " (" .. "Level " .. 
                              entry.level .. ") blev dräpt av " .. 
                              "|cFFFF0000" .. entry.killer .. "|r" .. " i " .. 
                              entry.zone
        
        fontString:SetText(formattedText)
        fontString:Show()
        table.insert(deathFontStrings, fontString) -- Track it
    end
end
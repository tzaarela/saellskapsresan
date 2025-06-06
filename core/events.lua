-- core/events.lua
-- Event handling

Saellskapsresan = Saellskapsresan or {}
local SSR = Saellskapsresan

-- Register frames
SSR.systemFrame = CreateFrame("Frame", "SaellskapsresanSystemFrame")

-- Register Events
SSR.systemFrame:RegisterEvent("ADDON_LOADED")
SSR.systemFrame:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH")
SSR.systemFrame:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS")
SSR.systemFrame:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_SELF_SPELL_DAMAGE")
SSR.systemFrame:RegisterEvent("CHAT_MSG_COMBAT_SELF_HITS")
SSR.systemFrame:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_SELF_MISSES")
SSR.systemFrame:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
SSR.systemFrame:RegisterEvent("PLAYER_DEAD")
SSR.systemFrame:RegisterEvent("PLAYER_LOGOUT")
SSR.systemFrame:RegisterEvent("PLAYER_LOGIN")
SSR.systemFrame:RegisterEvent("SKILL_LINES_CHANGED")
-- Add to your event registration
SSR.systemFrame:RegisterEvent("PLAYER_TARGET_CHANGED")

-- Local variables for event tracking
local deathReportSent = false
local isGameValid = false
local critterKillCooldown = 0
SSR.LastKiller = "Främmande varelse"

-- Event Handler
SSR.systemFrame:SetScript("OnEvent", function()
    -- For debugging
    -- DEFAULT_CHAT_FRAME:AddMessage("DebugEvent: " .. event, 1, 0.5, 0)
    -- DEFAULT_CHAT_FRAME:AddMessage("DebugArg1: " .. arg1, 1, 0.5, 0)
    -- DEFAULT_CHAT_FRAME:AddMessage("DebugArg2: " .. arg2, 1, 0.5, 0)

    -- Handle all initialization inside addon loaded
    if event == "ADDON_LOADED" and arg1 == "SaellskapsresanMod" and not this.loaded then
        if not SyncLoaded then
            SSR.ShowErrorPopup("Du startade inte spelet med Saellskapsresan.bat! Synkningen kommer inte fungera!")
        end

        SSR_CONFIG = SSR_CONFIG or { 
            minimap = { 
                hide = false,
                minimapPos = 225 
            } 
        }
        
        -- Register minimap button
        SSR.SetupDataBroker()

        deathReportSent = false
        this.loaded = true
        SSR.InitializeSystem()
        
        isGameValid = SSR.ValidatePlayerLogin()


        if isGameValid then
            print("[Sällskapsresan] Allt är okej!")
        else
            print("[Sällskapsresan] VIKTIGT! Antingen är det första gången du loggar in, eller så har du bytt karaktär. Tryck LADDA OM i addonet eller skriv /reload")
            return
        end

        SSR.CacheRemoteCharacterStats()
        SSR.UpdateRemoteCharacterStats()
            
    elseif not isGameValid then
        print("[Sällskapsresan] VIKTIGT! Antingen är det första gången du loggar in, eller så har du bytt karaktär. Tryck LADDA OM i addonet eller skriv /reload")
        return
   
    -- Update when skills change
    elseif event == "SKILL_LINES_CHANGED" then
        SSR.SetCharacterProfessions()
        
    -- If we get hit by creature melee/spell hits
    elseif event == "CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS" or event == "CHAT_MSG_COMBAT_CREATURE_VS_SELF_SPELL_DAMAGE" then
        SSR.ParseKiller(arg1)
    
    -- Handle critter kills separately
    elseif event == "CHAT_MSG_COMBAT_HOSTILE_DEATH" then
        -- Check if the death message is about our target and it's a critter
        local targetName = UnitName("target")
        if targetName and string.find(arg1, targetName) and UnitCreatureType("target") == "Critter" then
            -- Check if we're not on cooldown
            local currentTime = GetTime()
            if currentTime >= critterKillCooldown then
                -- print("[Sällskapsresan] Killed a critter!")
                SSR.TryIncrementStat("CrittersKilled", 1)
                
                -- Set cooldown for 2 seconds
                critterKillCooldown = currentTime + 2
            end
        end
    end
   
    -- If player dies
    if event == "PLAYER_DEAD" and not deathReportSent then
        print("[Sällskapsresan] Jag är ledsen, men du dog! Du kommer bli ihågkommen! Bara att resa sig upp och gå igen!")
        SSR.ReportDeath()
        deathReportSent = true

        -- This does not seem to trigger. But ALT-F4 seems to save to SavedVariables either way. So maybe not necessary.
        ReloadUI()
    end
end)
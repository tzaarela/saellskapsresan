-- core/init.lua
-- Initial setup and addon initialization

Saellskapsresan = Saellskapsresan or {}
local SSR = Saellskapsresan

-- Initialize UI function (called in ADDON_LOADED)
function SSR.InitializeSystem()
    CurrentCharacter = CurrentCharacter or ""
    DeathLoggerDB = DeathLoggerDB or {}
    LastLogonDB = LastLogonDB or {}
    SyncLoaded = SyncLoaded or false
    CharacterProfessionsDB = CharacterProfessionsDB or {}
    CharacterStatsDB = CharacterStatsDB or {}
    LocalCurrentCharacter = LocalCurrentCharacter or ""
    LocalDeathLoggerDB = LocalDeathLoggerDB or {}
    LocalLastLogonDB = LocalLastLogonDB or {}
    LocalSyncLoaded = LocalSyncLoaded or false
    LocalCharacterProfessionsDB = LocalCharacterProfessionsDB or {}
    LocalCharacterStatsDB = LocalCharacterStatsDB or {}
    print("[Sällskapsresan] v" .. SSR.addonVersion .." har initierats!")
end

-- Register DataBroker for minimap button
function SSR.SetupDataBroker()
    local LDB = LibStub("LibDataBroker-1.1")
    local icon = LibStub("LibDBIcon-1.0")
    
    SSR.dataObject = LDB:NewDataObject("Saellskapsresan", {
        type = "data source",
        text = "Saellskapsresan",
        icon = "Interface\\AddOns\\SaellskapsresanMod\\art\\addonlogo.tga",
        OnClick = function(self, button)
            SSR.OpenUI()
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("Sällskapsresan")
            tooltip:AddLine("Öppna!")
        end,
    })
    
    -- Register the button with the minimap
    icon:Register("Saellskapsresan", SSR.dataObject, SSR_CONFIG.minimap)
end

-- Function to validate player login
function SSR.ValidatePlayerLogin()
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
        SSR.ShowErrorPopup(
            "Viktigt! Du har bytt karaktär sen du spelade sist, du måste skriva /reload eller trycka 'Ladda om' i Saellskapsresan Addonet.", 
            "Ladda Om", 
            ReloadUI
        )
        return false
    end 
end
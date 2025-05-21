Saellskapsresan = Saellskapsresan or {}
local SSR = Saellskapsresan

function SSR.GetRemoteCharacterStats()
    if CachedCharacterStatsDB == nil then
        CachedCharacterStatsDB = {}
    end

    local characterName = UnitName("player")
    local remoteCharacterData = CharacterStatsDB[characterName]

    local characterStatsData = {}
    if remoteCharacterData then
        characterStatsData.CrittersKilled = remoteCharacterData.CrittersKilled or 0
        characterStatsData.HighestCrit = remoteCharacterData.HighestCrit or 0
    else
        characterStatsData.CrittersKilled = 0
        characterStatsData.HighestCrit = 0
    end

    -- Cache the stats for future updates
    CachedCharacterStatsDB[characterName] = characterStatsData
end

function SSR.UpdateRemoteCharacterStats()

    local characterName = UnitName("player")
    local cachedCharacterStats = CachedCharacterStatsDB[characterName]

    local characterStatsData = {
        CharacterName = characterName,
        IsAlive = not UnitIsDeadOrGhost("player"),
        Level =  UnitLevel("player"),
        Class = UnitClass("player"),
        Race = UnitRace("player"),
        HighestCrit = cachedCharacterStats.HighestCrit,
        CrittersKilled = cachedCharacterStats.CrittersKilled,
        LastModified = date("%Y-%m-%d %H:%M:%S")
    }
    
    if LocalCharacterStatsDB == nil then
        LocalCharacterStatsDB = {}
    end
    
    LocalCharacterStatsDB[characterName] = characterStatsData
    CharacterStatsDB[characterName] = characterStatsData
end

function SSR.TryUpdateStat(statKey, statValue)

    local characterName = UnitName("player")
    local cachedStats = CachedCharacterStatsDB[characterName]

    if statKey == "HighestCrit" and statValue > cachedStats.HighestCrit then
        cachedStats.HighestCrit = statValue
    end

    CachedCharacterStatsDB[characterName] = cachedStats
end

function SSR.TryIncrementStat(statKey, incrementValue)
    local characterName = UnitName("player")
    local cachedStats = CachedCharacterStatsDB[characterName]
    
    if statKey == "CrittersKilled" then
        cachedStats.CrittersKilled = cachedStats.CrittersKilled + incrementValue
    end

    CachedCharacterStatsDB[characterName] = cachedStats
end
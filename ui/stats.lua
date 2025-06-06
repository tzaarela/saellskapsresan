-- ui/stats.lua
-- Stats UI

Saellskapsresan = Saellskapsresan or {}
local SSR = Saellskapsresan

-- Create the stats layout
function SSR.CreateStatsLayout()


   
    -- Stats Frame
    local StatsFrame = CreateFrame("Frame", "StatsFrame", SSR.frames.MainFrame)
    StatsFrame:SetAllPoints(SSR.frames.MainFrame)
    
    local statsFrameBg = StatsFrame:CreateTexture(nil, "BACKGROUND")
    statsFrameBg:SetAllPoints(StatsFrame)
    statsFrameBg:SetTexture(SSR.UI.navWindowColor.r, SSR.UI.navWindowColor.g, SSR.UI.navWindowColor.b, SSR.UI.navWindowColor.a)

    StatsFrame:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })

    StatsFrame:SetPoint("TOPLEFT", SSR.frames.MainFrame, "TOPLEFT", 15, -75)
    StatsFrame:SetPoint("BOTTOMRIGHT", SSR.frames.MainFrame, "BOTTOMRIGHT", -15, 50)
    StatsFrame:Hide()

    -- Create a simple container frame
    local statsContainer = CreateFrame("Frame", "statsContainer", StatsFrame)
    statsContainer:SetPoint("TOPLEFT", StatsFrame, "TOPLEFT", 20, -20)
    statsContainer:SetPoint("BOTTOMRIGHT", StatsFrame, "BOTTOMRIGHT", -35, 20)
    statsContainer:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })

    
    
    -- Create the 4 leaderboard columns
    local leaderboardTitles = {
        "Biggest Crit", "Critter Killer", "Highest Level", "Most Deaths"
    }
    
    -- Column width calculation (divide container width by 4 for 4 columns)
    local columnWidth = SSR.frames.MainFrame:GetWidth() / 4 - 30
    local columnSpacing = 2
    local columnHeight = SSR.frames.MainFrame:GetHeight() - 200
    
    -- Create the four leaderboards
    for i = 1, 4 do
        
        -- print("Creating leaderboard column. Width: " .. columnWidth .. " Height: " .. columnHeight)
        -- Create frame for this leaderboard column
        local leaderboard = CreateFrame("Frame", "Leaderboard"..i, statsContainer)
        leaderboard:SetPoint("TOPLEFT", statsContainer, "TOPLEFT", (i-1)*(columnWidth + columnSpacing) + 10, -20)
        leaderboard:SetWidth(columnWidth)
        leaderboard:SetHeight(columnHeight)
        leaderboard:SetBackdrop({
        -- bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })

            -- DEBUG AREA
        leaderboard:SetBackdropColor(0.1, 0.1, 0.3, 0.8)
        leaderboard:SetBackdropBorderColor(1, 0.8, 0, 1)
        
        -- print("Creating leaderboard column.")

        -- Create title for this leaderboard
        local title = statsContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOP", leaderboard, "TOP", 0, -10)
        title:SetText(leaderboardTitles[i])

        -- Store the leaderboard frame for later access
        if not SSR.frames.leaderboards then
            SSR.frames.leaderboards = {}
        end
        SSR.frames.leaderboards[i] = leaderboard
        
        -- Create the top 10 entries for this leaderboard
        for j = 1, 10 do
            local entry = leaderboard:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            entry:SetPoint("TOPLEFT", leaderboard, "TOPLEFT", 20, -((j-1)*22 + 30))
            entry:SetText("#"..j.." ---") -- Placeholder text
            
            -- Store the entry for later update
            if not SSR.frames.leaderboardEntries then
                SSR.frames.leaderboardEntries = {}
            end
            if not SSR.frames.leaderboardEntries[i] then
                SSR.frames.leaderboardEntries[i] = {}
            end
            SSR.frames.leaderboardEntries[i][j] = entry
        end
    end
    
    -- Store frame reference
    SSR.frames.StatsFrame = StatsFrame
    SSR.UpdateLeaderboards()

end

-- Function to update leaderboard data
function SSR.UpdateLeaderboards()
    -- print("Updating leaderboards...")

    if not CharacterStatsDB then 
        print("No character stats found")
        return 
    end

    if not SSR.frames.leaderboardEntries then 
        print("No leaderboard entries found")    
        return 
    end
    
    -- Create arrays for each leaderboard category
    local biggestCrit = {}
    local critterKiller = {}
    local highestLevel = {}
    local mostDeaths = {}
    
    -- Process all characters and populate arrays
    for charName, charData in pairs(CharacterStatsDB) do
        -- Only include alive characters (you can remove this check if needed)
        if charData.IsAlive == "TRUE" or charData.IsAlive then
            -- Biggest Crit leaderboard
            table.insert(biggestCrit, {
                name = charName,
                score = tonumber(charData.HighestCrit) or 0
            })
            
            -- Critter Killer leaderboard
            table.insert(critterKiller, {
                name = charName,
                score = tonumber(charData.CrittersKilled) or 0
            })
            
            -- Highest Level leaderboard
            table.insert(highestLevel, {
                name = charName,
                score = tonumber(charData.Level) or 0
            })
            
            -- Most Deaths leaderboard - we'll calculate this separately from DeathLoggerDB
            -- We'll add characters here but calculate deaths after processing all characters
        end
    end
    
    -- Calculate deaths for each account from DeathLoggerDB
    local accountDeaths = {}
    if DeathLoggerDB then
        for i = 1, table.getn(DeathLoggerDB) do
            local deathEntry = DeathLoggerDB[i]
            if deathEntry and deathEntry.accountName then
                local accountName = deathEntry.accountName
                if not accountDeaths[accountName] then
                    accountDeaths[accountName] = 0
                end
                accountDeaths[accountName] = accountDeaths[accountName] + 1
            end
        end
    end
    
    -- Convert accountDeaths table to array for sorting
    local deathsArray = {}
    for accountName, deathCount in pairs(accountDeaths) do
        table.insert(deathsArray, {
            name = accountName,
            score = deathCount
        })
    end
    
    -- Sort by death count (highest first)
    table.sort(deathsArray, function(a, b) return a.score > b.score end)
    
    -- -- Print top 3
    -- print("Top 3 accounts with most deaths:")
    -- for i = 1, 3 do
    --     if deathsArray[i] then
    --         print("#" .. i .. ": " .. deathsArray[i].name .. " (" .. deathsArray[i].score .. " deaths)")
    --     end
    -- end


    -- Sort each leaderboard (highest to lowest)
    table.sort(biggestCrit, function(a, b) return a.score > b.score end)
    table.sort(critterKiller, function(a, b) return a.score > b.score end)
    table.sort(highestLevel, function(a, b) return a.score > b.score end)
    table.sort(mostDeaths, function(a, b) return a.score > b.score end)
    
    -- Store sorted arrays for easy access
    local leaderboards = {biggestCrit, critterKiller, highestLevel, deathsArray}
    
    -- Update the UI
    for i = 1, 4 do
        for j = 1, 10 do
            if leaderboards[i][j] and SSR.frames.leaderboardEntries[i][j] then
                local name = leaderboards[i][j].name or "---"
                local score = leaderboards[i][j].score or 0

                if score == 0 then
                    SSR.frames.leaderboardEntries[i][j]:SetText("#"..j.." ---")
                else 
                    SSR.frames.leaderboardEntries[i][j]:SetText("#"..j.." "..name.." ("..score..")")
                end
                
            elseif SSR.frames.leaderboardEntries[i][j] then
                -- No data for this entry, show placeholder
                SSR.frames.leaderboardEntries[i][j]:SetText("#"..j.." ---")
            end
        end
    end
    
    -- print("Leaderboards updated successfully!")
end
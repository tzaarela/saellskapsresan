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
        
        print("Creating leaderboard column. Width: " .. columnWidth .. " Height: " .. columnHeight)
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
end

-- Function to update leaderboard data
function SSR.UpdateLeaderboards(leaderboardData)
    -- leaderboardData should be a table with 4 subtables, one for each leaderboard
    -- Each subtable should contain up to 10 entries with name and score
    
    if not SSR.frames.leaderboardEntries then return end
    
    for i = 1, 4 do
        if leaderboardData and leaderboardData[i] then
            for j = 1, 10 do
                if leaderboardData[i][j] and SSR.frames.leaderboardEntries[i][j] then
                    local name = leaderboardData[i][j].name or "---"
                    local score = leaderboardData[i][j].score or 0
                    SSR.frames.leaderboardEntries[i][j]:SetText("#"..j.." "..name.." ("..score..")")
                elseif SSR.frames.leaderboardEntries[i][j] then
                    -- No data for this entry, show placeholder
                    SSR.frames.leaderboardEntries[i][j]:SetText("#"..j.." ---")
                end
            end
        end
    end
end

-- Example of how to call the update function:
-- SSR.UpdateLeaderboards({
--     { -- First leaderboard data (Total Quests)
--         {name = "Player1", score = 250},
--         {name = "Player2", score = 220},
--         -- ... more entries
--     },
--     -- ... data for other leaderboards
-- })
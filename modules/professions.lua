-- modules/professions.lua
-- Professions tracking functionality

Saellskapsresan = Saellskapsresan or {}
local SSR = Saellskapsresan

-- Helper function to check if a skill is a profession
function SSR.IsProfession(skillName)
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

-- Set character profession data
function SSR.SetCharacterProfessions()
    local playerName = UnitName("player")
    local primaryProfessions = {}
    local outputString = ""
    
    -- Loop through all skills
    for i = 1, GetNumSkillLines() do
        local skillName, isHeader, _, skillRank, _, _, maxRank = GetSkillLineInfo(i)
        
        -- If not a header and is a primary profession
        if not isHeader and SSR.IsProfession(skillName) then
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

    -- Update the display if needed
    if SSR.frames.ProfessionsFrame and SSR.frames.ProfessionsFrame:IsVisible() then
        SSR.ProfessionsScrollUpdate()
    end
end
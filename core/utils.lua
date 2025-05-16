-- core/utils.lua
-- Utility functions

Saellskapsresan = Saellskapsresan or {}
local SSR = Saellskapsresan

-- Get the color code for a class
function SSR.GetColorFromClassName(class)
    class = string.upper(class) 
    local hex = SSR.classColors[class]
    if hex then
        return "|cFF" .. hex
    else
        return class
    end
end

-- Get the first number in a string
function SSR.GetFirstNumberInString(text)
    for i = 1, string.len(text) do
        local c = string.sub(text, i, i)
        local byte = string.byte(c)

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
            return tonumber(numberStr)
        end
    end
    return nil
end

-- Check if table contains a value
function SSR.TableContains(t, value)
    for _, v in ipairs(t) do
        if v == value then
            return true
        end
    end
    return false
end

-- Get table length
function SSR.GetTableLength(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

-- Show an error popup
function SSR.ShowErrorPopup(message, customButtonText, customFunction)
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


function SSR.CreateScrollFrameRows(rowContainer, rowName, includeKey)
    for i = 1, SSR.ProfessionSettings.maxDisplayed do
        local row = CreateFrame("Frame", rowName..i, rowContainer)
        row:SetHeight(SSR.ProfessionSettings.rowHeight)
        row:SetWidth(rowContainer:GetWidth() - 30) -- Leave room for scrollbar
        row:SetPoint("TOPLEFT", rowContainer, "TOPLEFT", 10, -35 - ((i-1) * SSR.ProfessionSettings.rowHeight))
        
        -- Make rows visible for debugging
        row:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            tile = true
        })
        
        -- Alternate row colors
        if math.mod(i, 2) == 0 then
            row:SetBackdropColor(0.1, 0.1, 0.1, 0.3)
        else
            row:SetBackdropColor(0.2, 0.2, 0.2, 0.2)
        end
        
        if includeKey then 
            row.key = row:CreateFontString(nil, "OVERLAY")
            row.key:SetFont(SSR.UI.StandardTextFont.font, SSR.UI.StandardTextFont.size, SSR.UI.StandardTextFont.flags)
            row.key:SetPoint("LEFT", row, "LEFT", 5, 0)
            row.key:SetText("") -- Will be set in update function
            
            row.value = row:CreateFontString(nil, "OVERLAY")
            row.value:SetFont(SSR.UI.StandardTextFont.font, SSR.UI.StandardTextFont.size, SSR.UI.StandardTextFont.flags)
            row.value:SetPoint("LEFT", row, "LEFT", 120, 0)
            row.value:SetText("") -- Will be set in update function
            
        else
            row.value = row:CreateFontString(nil, "OVERLAY")
            row.value:SetFont(SSR.UI.StandardTextFont.font, SSR.UI.StandardTextFont.size, SSR.UI.StandardTextFont.flags)
            row.value:SetPoint("LEFT", row, "LEFT", 5, 0)
            row.value:SetText("") -- Will be set in update function
        end
        
        row:Hide()
    end
end

function SSR.UpdateScrollFrameRows(scrollFrame, dataTable, rowName, totalEntries)

    local maxDisplayed = SSR.ProfessionSettings.maxDisplayed
    local rowHeight = SSR.ProfessionSettings.rowHeight

        -- Update the scroll frame
    FauxScrollFrame_Update(scrollFrame, totalEntries, maxDisplayed, rowHeight)
    
    -- Get current offset
    local offset = FauxScrollFrame_GetOffset(scrollFrame)
    -- print("Current offset: " .. offset .. " Total entries: " .. totalEntries .. " maxDisplayed: " .. maxDisplayed .. " rowHeight: " .. rowHeight)
    -- print("Updating rows for scrollFrame. RowName: " .. rowName)

    for i = 1, maxDisplayed do
        local row = getglobal(rowName .. i)
        local dataIndex = i + offset
        
        if dataIndex <= totalEntries then
            local data = dataTable[dataIndex]

            -- Set text
            
            local value = "No data"
            
            if rowName == "ProfessionRow" then
                row.key:SetText(data.key)
                value = data.entry.professionString
            elseif rowName == "DeathLogRow" then
                local formattedText = 
                    data.entry.timestamp .. " - " .. "(" .. "|cFFFFFF00" .. data.entry.accountName .. "|r) - " ..  
                    SSR.GetColorFromClassName(data.entry.playerClass) .. data.entry.playerName .. "|r".. " (" .. "Level " .. 
                    data.entry.level .. ") blev dräpt av " .. 
                    "|cFFFF0000" .. data.entry.killer .. "|r" .. " i " .. 
                    data.entry.zone

                value = formattedText
            end
            
            row.value:SetText(value)
            row:Show()
            -- print("Showing row " .. i .. " with data index " .. dataIndex)
        end
    end
end
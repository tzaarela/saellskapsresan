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
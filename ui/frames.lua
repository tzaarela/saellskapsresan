-- ui/frames.lua
-- Base frame management

Saellskapsresan = Saellskapsresan or {}
local SSR = Saellskapsresan

-- Frame references
SSR.frames = {}

-- OpenUI function that creates all frames
function SSR.OpenUI()
    -- IF we already created the layout
    if SSR.frames.MainFrame then 
        -- return if already open
        if SSR.frames.MainFrame:IsShown() then
            return
        end

        SSR.frames.MainFrame:Show()
    -- Create Layout
    else
        SSR.CreateMainLayout()
        SSR.CreateStartLayout()
        SSR.CreateDeathLoggerLayout()
        SSR.CreateStatsLayout()
        SSR.CreateCharacterProfessionsLayout()
        SSR.CreateNavigationButtons()
        SSR.CreateSystemButtons()
    end
end

-- Close the UI
function SSR.CloseUI()
    if SSR.frames.MainFrame then
        SSR.frames.MainFrame:Hide()
    end
end
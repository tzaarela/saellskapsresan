-- ui/frames.lua
-- Base frame management

Saellskapsresan = Saellskapsresan or {}
local SSR = Saellskapsresan

-- Frame references
SSR.frames = {}

-- OpenUI function that creates all frames
function SSR.OpenUI()
    if SSR.frames.MainFrame and SSR.frames.MainFrame:IsShown() then
        return
    end
    
    SSR.CreateMainLayout()
    SSR.CreateStartLayout()
    SSR.CreateDeathLoggerLayout()
    SSR.CreateStatsLayout()
    SSR.CreateCharacterProfessionsLayout()
    SSR.CreateNavigationButtons()
    SSR.CreateSystemButtons()
end

-- Close the UI
function SSR.CloseUI()
    if SSR.frames.MainFrame then
        SSR.frames.MainFrame:Hide()
    end
end
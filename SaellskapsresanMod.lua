--Sällskapsresan Mod v0.2.3 - Made by Tzaa 
-- Main file - Acts as entry point

-- Initialize our addon namespace if not already done
Saellskapsresan = Saellskapsresan or {}

-- Register slash commands
SLASH_SSR1 = "/sr"
SLASH_SSR2 = "/ssr"
SLASH_SSR3 = "/sällskapsresan"
SLASH_SSR4 = "/saellskapsresan"
SlashCmdList["SSR"] = function()
    Saellskapsresan.OpenUI()
end

-- This is the main entry point, but most functionality is delegated to the other files
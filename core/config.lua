-- core/config.lua
-- Configuration and styles

-- Initialize addon namespace
Saellskapsresan = Saellskapsresan or {}
local SSR = Saellskapsresan

-- Version
SSR.addonVersion = "0.2.1"

-- UI Style
SSR.UI = {}
SSR.UI.mainWindowWidth = 700
SSR.UI.mainWindowHeight = 500

SSR.UI.mainWindowColor = {r = 0, g = 0, b = 0, a = 0.9} -- Black with little transparency
SSR.UI.navWindowColor = {r = 0.1, g = 0.1, b = 0.1, a = 1} -- Dark gray with no transparency

SSR.UI.Header1Font = { layer = "OVERLAY", font = "Interface\\AddOns\\SaellskapsresanMod\\fonts\\Myriad-Pro.ttf", size = 24, flags = "OUTLINE" }
SSR.UI.Header2Font = { layer = "OVERLAY", font = "Interface\\AddOns\\SaellskapsresanMod\\fonts\\Myriad-Pro.ttf", size = 20, flags = "OUTLINE" }
SSR.UI.Header3Font = { layer = "OVERLAY", font = "Interface\\AddOns\\SaellskapsresanMod\\fonts\\Myriad-Pro.ttf", size = 18, flags = "OUTLINE" }
SSR.UI.StandardTextFont = { layer = "OVERLAY", font = "Interface\\AddOns\\SaellskapsresanMod\\fonts\\Myriad-Pro.ttf", size = 14, flags = "OUTLINE" }

-- Class Colors
SSR.classColors = {
    ["WARRIOR"] = "C79C6E",
    ["PALADIN"] = "F48CBA",
    ["HUNTER"]  = "AAD372",
    ["ROGUE"]   = "FFF468",
    ["PRIEST"]  = "FFFFFF",
    ["SHAMAN"]  = "0070DD",
    ["MAGE"]    = "3FC7EB",
    ["WARLOCK"] = "8788EE",
    ["DRUID"]   = "FF7C0A",
}
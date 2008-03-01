if( not Spellbreak ) then
	return
end

local Config = Spellbreak:NewModule("Config")
local L = SpellbreakLocals

local OptionHouse
local HouseAuthority
local OHObj

function Config:OnInitialize()
	-- Open the OH UI
	SLASH_SPELLBREAK1 = "/spellbreak"
	SLASH_SPELLBREAK2 = "/spellbreaker"
	SlashCmdList["SPELLBREAK"] = function(msg)
		OptionHouse:Open("Spellbreak")
	end
		
	-- Register with OptionHouse
	OptionHouse = LibStub("OptionHouse-1.1")
	HouseAuthority = LibStub("HousingAuthority-1.2")
	
	OHObj = OptionHouse:RegisterAddOn("Afflicted", nil, "Mayen", "r" .. max(tonumber(string.match("$Revision: 599 $", "(%d+)") or 1), Afflicted.revision))
	OHObj:RegisterCategory(L["General"], self, "CreateUI", nil, 1)
end

-- GUI
function Config:Set(var, value)
	Spellbreak.db.profile[var] = value
end

function Config:Get(var)
	return Spellbreak.db.profile[var]
end

function Config:Reload()
	Spellbreak:Reload()
end

function Config:CreateUI()
	local config = {
	--[[
		{ group = L["General"], type = "groupOrder", order = 1 },
		{ order = 1, group = L["General"], text = L["Only enable inside"], help = L["Only enable Afflicted inside the specified areas."], type = "dropdown", list = {{"none", L["Everywhere else"]}, {"pvp", L["Battlegrounds"]}, {"arena", L["Arenas"]}, {"raid", L["Raid Instances"]}, {"party", L["Party Instances"]}}, multi = true, var = "inside"},
		{ order = 2, group = L["General"], text = L["Show icons in local alerts"], help = L["Shows the spell icon when the alert is sent to a local channel like middle of screen, or a chat frame."], type = "check", var = "showIcons"},
		{ order = 3, group = L["General"], text = L["Show timers anchor"], help = L["ALT + Drag the anchors to move the frames."], type = "check", var = "showAnchors"},

		{ group = L["Dispel Alerts"], type = "groupOrder", order = 2 },
		{ order = 1, group = L["Dispel Alerts"], text = L["Enable dispel alerts"], help = L["Enable alerts when you dispel a player while Afflicted is enabled."], type = "check", var = "dispelEnabled"},
		{ order = 1, group = L["Dispel Alerts"], text = L["Show hostile dispels"], help = L["Displays alerts when you dispel hostile players as well, instead of just friendly players."], type = "check", var = "dispelHostile"},
		{ order = 2, group = L["Dispel Alerts"], text = L["Announce channel"], help = L["Channel to send abilities announcements to."], type = "dropdown", list = {{"ct", L["Combat Text"]}, {"rw", L["Raid Warning"]}, {"rwframe", L["Middle of screen"]}, {"party", L["Party"]}, {1, string.format(L["Chat frame #%d"], 1)}, {2, string.format(L["Chat frame #%d"], 2)}, {3, string.format(L["Chat frame #%d"], 3)}, {4, string.format(L["Chat frame #%d"], 4)}, {5, string.format(L["Chat frame #%d"], 5)}, {6, string.format(L["Chat frame #%d"], 6)}, {7, string.format(L["Chat frame #%d"], 7)}}, var = "dispelDest"},
		{ order = 3, group = L["Dispel Alerts"], text = L["Announce color"], help = L["Color the text should be shown in if you're outputting using \"Middle of screen\" or \"Combat text\"."], type = "color", var = "dispelColor"},

		{ group = L["Interrupt Alerts"], type = "groupOrder", order = 3 },
		{ order = 1, group = L["Interrupt Alerts"], text = L["Enable interrupt alerts"], help = L["Enable alerts when you interrupt an enemies player spell."], type = "check", var = "interruptEnabled"},
		{ order = 2, group = L["Interrupt Alerts"], text = L["Announce channel"], help = L["Channel to send abilities announcements to."], type = "dropdown", list = {{"ct", L["Combat Text"]}, {"rw", L["Raid Warning"]}, {"rwframe", L["Middle of screen"]}, {"party", L["Party"]}, {1, string.format(L["Chat frame #%d"], 1)}, {2, string.format(L["Chat frame #%d"], 2)}, {3, string.format(L["Chat frame #%d"], 3)}, {4, string.format(L["Chat frame #%d"], 4)}, {5, string.format(L["Chat frame #%d"], 5)}, {6, string.format(L["Chat frame #%d"], 6)}, {7, string.format(L["Chat frame #%d"], 7)}}, var = "interruptDest"},
		{ order = 3, group = L["Interrupt Alerts"], text = L["Announce color"], help = L["Color the text should be shown in if you're outputting using \"Middle of screen\" or \"Combat text\"."], type = "color", var = "interruptColor"},
	]]
	}

	return HouseAuthority:CreateConfiguration(config, {set = "Set", get = "Get", onSet = "Reload", handler = self})	
end

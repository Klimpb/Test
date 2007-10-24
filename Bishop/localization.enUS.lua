BishopLocals = {
	-- Druid
	["Lifebloom"] = "Lifebloom",
	["Regrowth"] = "Regrowth",
	["Rejuvenation"] = "Rejuvenation",
	
	["Gift of Nature"] = "Gift of Nature",
	["Improved Rejuvenation"] = "Improved Rejuvenation",
	["Empowered Rejuvenation"] = "Empowered Rejuvenation",
	
	-- Priest
	["Renew"] = "Renew",
	["Improved Renew"] = "Improved Renew",
	["Spiritual Healing"] = "Spiritual Healing",
	
	
	-- Spells that have two effects, so we can broke it down more
	-- then just counting the direct heal and the hot as one effect
	["HOT"] = {
		["Lifebloom"] = "Lifebloom HoT",
		["Regrowth"] = "Regrowth HoT",
	},
	
	["HEAL"] = {
		["Lifebloom"] = "Lifebloom Heal",
		["Regrowth"] = "Regrowth Heal",
	},
	
	["Your class %s, does not have any healing spells, Bishop disabled."] = "Your class %s, does not have any healing spells, Bishop disabled.",

	-- Slash command
	["Bishop slash commands"] = "Bishop slash commands",
	
	["ui - Pulls up the configuration page"] = "ui - Pulls up the configuration page",
	["toggle - Toggles the meter open/closed"] = "toggle - Toggles the meter open/closed",
	["reset - Resets all saved healing data"] = "reset - Resets all saved healing data",
	
	["All healing information has been reset!"] = "All healing information has been reset!",
	
	-- GUI
	["Total"] = "Total",
	["Display"] = "Display",
	["General"] = "General",
	["Frame"] = "Frame",
	["Color"] = "Color",
	
	["Format numbers in healing meter"] = "Format numbers in healing meter",
	
	["Bar texture"] = "Bar texture",
	["Bar color"] = "Bar color",
	["Show frame"] = "Show frame",
	["Lock frame"] = "Lock frame",
	["Frame scale: %d%%"] = "Frame scale: %d%%",
}
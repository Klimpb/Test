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
	["disable - Disables Bishop"] = "disable - Disables Bishop",
	["enable - Enables Bishop"] = "enable - Enables Bishop",
	["toggle - Toggles the meter open/closed"] = "toggle - Toggles the meter open/closed",
	["reset - Resets all saved healing data"] = "reset - Resets all saved healing data",
	
	["All healing information has been reset!"] = "All healing information has been reset!",
	
	["Enabled, now recording healing data."] = "Enabled, now recording healing data.",
	["Disabled, reset saved data and stopped recording."] = "Disabled, reset saved data and stopped recording.",
	
	-- GUI
	["Total"] = "Total",
	["Display"] = "Display",
	["General"] = "General",
	["Frame"] = "Frame",
	["Color"] = "Color",
	["Syncing"] = "Syncing",
	
	["Format numbers in healing meter"] = "Format numbers in healing meter",
	
	["Bar texture"] = "Bar texture",
	["Bar color"] = "Bar color",
	["Show frame"] = "Show frame",
	["Lock frame"] = "Lock frame",
	["Frame scale: %d%%"] = "Frame scale: %d%%",
	
	["Sync spirit with other Bishop users"] = "Sync spirit with other Bishop users",
	["This enables sending your total spirit, this is only needed if you are a Druid. It's highly recommended that you enable this if you're a Tree of Life Druid, or else other Bishop users cannot calculate HoTs off of people in your group accurately."] = "This enables sending your total spirit, this is only needed if you are a Druid. It's highly recommended that you enable this if you're a Tree of Life Druid, or else other Bishop users cannot calculate HoTs off of people in your group accurately.",
}
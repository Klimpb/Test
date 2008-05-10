if( not Trackery ) then return end

local Config = Trackery:NewModule("Config")
local L = TrackeryLocals

local registered, options, config, dialog

function Config:OnInitialize()
	config = LibStub("AceConfig-3.0")
	dialog = LibStub("AceConfigDialog-3.0")
end

-- GUI
local function set(info, value)
	local arg1, arg2, arg3 = string.split(".", info.arg)
	if( tonumber(arg2) ) then arg2 = tonumber(arg2) end
	
	if( arg2 and arg3 ) then
		Trackery.db.profile[arg1][arg2][arg3] = value
	elseif( arg2 ) then
		Trackery.db.profile[arg1][arg2] = value
	else
		Trackery.db.profile[arg1] = value
	end
	
	Trackery:Reload()
end

local function get(info)
	local arg1, arg2, arg3 = string.split(".", info.arg)
	if( tonumber(arg2) ) then arg2 = tonumber(arg2) end
	
	if( arg2 and arg3 ) then
		return Trackery.db.profile[arg1][arg2][arg3]
	elseif( arg2 ) then
		return Trackery.db.profile[arg1][arg2]
	else
		return Trackery.db.profile[arg1]
	end
end

local function setMulti(info, value, state)
	local arg1, arg2, arg3 = string.split(".", info.arg)
	if( tonumber(arg2) ) then arg2 = tonumber(arg2) end

	if( arg2 and arg3 ) then
		Trackery.db.profile[arg1][arg2][arg3][value] = state
	elseif( arg2 ) then
		Trackery.db.profile[arg1][arg2][value] = state
	else
		Trackery.db.profile[arg1][value] = state
	end

	Trackery:Reload()
end

local function getMulti(info, value)
	local arg1, arg2, arg3 = string.split(".", info.arg)
	if( tonumber(arg2) ) then arg2 = tonumber(arg2) end
	
	if( arg2 and arg3 ) then
		return Trackery.db.profile[arg1][arg2][arg3][value]
	elseif( arg2 ) then
		return Trackery.db.profile[arg1][arg2][value]
	else
		return Trackery.db.profile[arg1][value]
	end
end


-- Anchor config
local displayTypes = {["top"] = L["Bottom -> Top"], ["down"] = L["Top -> Bottom"], ["left"] = L["Right -> Left"], ["right"] = L["Left -> Right"]}
function Config:CreateAnchorDisplay(info, id, text)
	options.args.anchors.args[id] = {
		order = 1,
		type = "group",
		name = text,
		get = get,
		set = set,
		handler = Config,
		args = {
			enabled = {
				order = 1,
				type = "toggle",
				name = L["Enable anchor"],
				desc = L["Show timers that are triggered for this anchor."],
				width = "double",
				arg = "anchors." .. id .. ".enabled",
			},
			scale = {
				order = 2,
				type = "range",
				name = L["Display scale"],
				desc = L["How big the actual timers should be."],
				min = 0, max = 2, step = 0.1,
				set = setNumber,
				arg = "anchors." .. id .. ".scale",
			},
			displayType = {
				order = 3,
				type = "select",
				name = L["Display type"],
				desc = L["How timers should be displayed."],
				values = displayTypes,
				arg = "anchors." .. id .. ".displayType",
			},
		},
	}
end


-- General options
local enabledIn = {["none"] = L["Everywhere else"], ["pvp"] = L["Battlegrounds"], ["arena"] = L["Arenas"], ["raid"] = L["Raid instances"], ["party"] = L["Party instances"]}

local function loadOptions()
	options = {}
	options.type = "group"
	options.name = "Trackery"
	
	options.args = {}
	options.args.general = {
		type = "group",
		order = 1,
		name = L["General"],
		get = get,
		set = set,
		handler = Config,
		args = {
			enabled = {
				order = 1,
				type = "toggle",
				name = L["Show anchors"],
				desc = L["Display timer anchors for moving around."],
				width = "double",
				arg = "showAnchors",
			},
			silent = {
				order = 2,
				type = "toggle",
				name = L["Silent mode"],
				desc = L["Disables everything except timer syncing, this is basically for people who only want this mod for broadcasting your debuff timers to someone else.."],
				width = "double",
				arg = "silent",
			},
			enabledIn = {
				order = 3,
				type = "multiselect",
				name = L["Enable Trackery inside"],
				desc = L["Allows you to set what scenario's Trackery should be enabled inside."],
				values = enabledIn,
				set = setMulti,
				get = getMulti,
				width = "double",
				arg = "inside"
			},
		},
	}
	
	-- ANCHOR GROUP
	options.args.anchors = {
		type = "group",
		order = 3,
		name = L["Anchors"],
		get = get,
		set = set,
		handler = Config,
		args = {
		},
	}

	-- Load our created anchors in
	for id, data in pairs(Trackery.db.profile.anchors) do
		if( not data.text ) then
			data.text = id
		end
		
		Config:CreateAnchorDisplay(nil, id, data.text)
	end	
	
	-- SPELL GROUP
	options.args.spells = {
		type = "group",
		order = 4,
		name = L["Spells"],
		get = get,
		set = set,
		handler = Config,
		args = {
			desc = {
				order = 0,
				type = "description",
				name = L["Lets you choose which spells should be displayed in the party timer anchors, this will not change how you actually send data to others."],
			},
			list = {
				order = 1,
				type = "group",
				inline = true,
				name = L["List"],
				args = {},
			},
		},
	}

	-- Load spell list
	for spellName, spellID in pairs(Trackery.db.profile.spellList) do
		options.args.spells.args.list.args[tostring(spellID)] = {
			order = 1,
			type = "toggle",
			name = spellName,
			desc = string.format(L["Enable timers for %s."], spellName),
			arg = "spellList." .. spellName,
		}
	end

	-- DB Profiles
	options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(Trackery.db)
	options.args.profile.order = 2
end

-- Slash commands
SLASH_TRACKERY1 = "/trackery"
SLASH_TRACKERY2 = "/partydebufftracker"
SLASH_TRACKERY3 = "/pdt"
SlashCmdList["TRACKERY"] = function(msg)
	if( msg == "clear" ) then
		for id in pairs(Trackery.db.profile.anchors) do
			Trackery.visual:ClearTimers(id)
		end
		
	elseif( msg == "test" ) then
		local testList = {[26989] = 10, [11719] = 30, [18223] = 12, [33786] = 6, [27088] = 8}
		for i=1, MAX_NUM_PARTY_MEMBERS do
			Trackery.visual:ClearTimers("party" .. i)

			for spellID, seconds in pairs(testList) do
				local spellName, _, icon = GetSpellInfo(spellID)
				Trackery.visual:CreateTimer("party" .. i, spellID, spellName, icon, seconds, math.random(5), UnitGUID("player"))
			end
		end
	
	elseif( msg == "ui" ) then
		if( not registered ) then
			if( not options ) then
				loadOptions()
			end
			
			config:RegisterOptionsTable("Trackery", options)
			dialog:SetDefaultSize("Trackery", 600, 500)
			registered = true
		end

		dialog:Open("Trackery")
	else
		DEFAULT_CHAT_FRAME:AddMessage(L["Trackery slash commands"])
		DEFAULT_CHAT_FRAME:AddMessage(L["- clear - Clears all running timers."])
		DEFAULT_CHAT_FRAME:AddMessage(L["- test - Shows test timers in Trackery."])
		DEFAULT_CHAT_FRAME:AddMessage(L["- ui - Opens the configuration for Trackery."])
	end
end

-- Add the general options + profile, we don't add spells/anchors because it doesn't support sub cats
local register = CreateFrame("Frame", nil, InterfaceOptionsFrame)
register:SetScript("OnShow", function(self)
	self:SetScript("OnShow", nil)
	loadOptions()

	config:RegisterOptionsTable("Trackery-Bliz", {
		name = "Trackery",
		type = "group",
		args = {
			help = {
				type = "description",
				name = string.format("Trackery r%d is a PvP timer tracking mod for party members, to make things like timing Cyclone end easier.", Trackery.revision or 0),
			},
		},
	})
	
	dialog:SetDefaultSize("Trackery-Bliz", 600, 400)
	dialog:AddToBlizOptions("Trackery-Bliz", "Trackery")
	
	config:RegisterOptionsTable("Trackery-General", options.args.general)
	dialog:AddToBlizOptions("Trackery-General", options.args.general.name, "Trackery")

	config:RegisterOptionsTable("Trackery-Profile", options.args.profile)
	dialog:AddToBlizOptions("Trackery-Profile", options.args.profile.name, "Trackery")
end)
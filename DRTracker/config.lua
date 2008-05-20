if( not DRTracker ) then return end

local Config = DRTracker:NewModule("Config")
local L = DRTrackerLocals

local SML, registered, options, config, dialog

function Config:OnInitialize()
	config = LibStub("AceConfig-3.0")
	dialog = LibStub("AceConfigDialog-3.0")
	

	SML = LibStub:GetLibrary("LibSharedMedia-3.0")
	SML:Register(SML.MediaType.STATUSBAR, "BantoBar", "Interface\\Addons\\DRTracker\\images\\banto")
	SML:Register(SML.MediaType.STATUSBAR, "Smooth",   "Interface\\Addons\\DRTracker\\images\\smooth")
	SML:Register(SML.MediaType.STATUSBAR, "Perl",     "Interface\\Addons\\DRTracker\\images\\perl")
	SML:Register(SML.MediaType.STATUSBAR, "Glaze",    "Interface\\Addons\\DRTracker\\images\\glaze")
	SML:Register(SML.MediaType.STATUSBAR, "Charcoal", "Interface\\Addons\\DRTracker\\images\\Charcoal")
	SML:Register(SML.MediaType.STATUSBAR, "Otravi",   "Interface\\Addons\\DRTracker\\images\\otravi")
	SML:Register(SML.MediaType.STATUSBAR, "Striped",  "Interface\\Addons\\DRTracker\\images\\striped")
	SML:Register(SML.MediaType.STATUSBAR, "LiteStep", "Interface\\Addons\\DRTracker\\images\\LiteStep")
end

-- GUI
local function set(info, value)
	local arg1, arg2, arg3 = string.split(".", info.arg)
	if( tonumber(arg2) ) then arg2 = tonumber(arg2) end
	
	if( arg2 and arg3 ) then
		DRTracker.db.profile[arg1][arg2][arg3] = value
	elseif( arg2 ) then
		DRTracker.db.profile[arg1][arg2] = value
	else
		DRTracker.db.profile[arg1] = value
	end
	
	DRTracker:Reload()
end

local function get(info)
	local arg1, arg2, arg3 = string.split(".", info.arg)
	if( tonumber(arg2) ) then arg2 = tonumber(arg2) end
	
	if( arg2 and arg3 ) then
		return DRTracker.db.profile[arg1][arg2][arg3]
	elseif( arg2 ) then
		return DRTracker.db.profile[arg1][arg2]
	else
		return DRTracker.db.profile[arg1]
	end
end

local function setNumber(info, value)
	set(info, tonumber(value))
end

local function setMulti(info, value, state)
	local arg1, arg2, arg3 = string.split(".", info.arg)
	if( tonumber(arg2) ) then arg2 = tonumber(arg2) end

	if( arg2 and arg3 ) then
		DRTracker.db.profile[arg1][arg2][arg3][value] = state
	elseif( arg2 ) then
		DRTracker.db.profile[arg1][arg2][value] = state
	else
		DRTracker.db.profile[arg1][value] = state
	end

	DRTracker:Reload()
end

local function getMulti(info, value)
	local arg1, arg2, arg3 = string.split(".", info.arg)
	if( tonumber(arg2) ) then arg2 = tonumber(arg2) end
	
	if( arg2 and arg3 ) then
		return DRTracker.db.profile[arg1][arg2][arg3][value]
	elseif( arg2 ) then
		return DRTracker.db.profile[arg1][arg2][value]
	else
		return DRTracker.db.profile[arg1][value]
	end
end


-- Return all registered SML textures
local textures = {}
function Config:GetTextures()
	for k in pairs(textures) do textures[k] = nil end

	for _, name in pairs(SML:List(SML.MediaType.STATUSBAR)) do
		textures[name] = name
	end
	
	return textures
end

-- Return all registered GTB groups
local groups = {}
function Config:GetGroups()
	for k in pairs(groups) do groups[k] = nil end

	groups[""] = L["None"]
	for name, data in pairs(DRTracker.GTB:GetGroups()) do
		groups[name] = name
	end
	
	return groups
end

-- General options
local enabledIn = {["none"] = L["Everywhere else"], ["pvp"] = L["Battlegrounds"], ["arena"] = L["Arenas"], ["raid"] = L["Raid instances"], ["party"] = L["Party instances"]}

local function loadOptions()
	options = {}
	options.type = "group"
	options.name = "DRTracker"
	
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
				name = L["Show anchor"],
				desc = L["Display timer anchor for moving around."],
				width = "double",
				arg = "showAnchor",
			},
			scale = {
				order = 2,
				type = "range",
				name = L["Display scale"],
				desc = L["How big the actual timers should be."],
				min = 0, max = 2, step = 0.1,
				set = setNumber,
				width = "double",
				arg = "scale",
			},
			barWidth = {
				order = 3,
				type = "range",
				name = L["Bar width"],
				min = 0, max = 300, step = 1,
				set = setNumber,
				width = "double",
				arg = "width",
			},
			barName = {
				order = 4,
				type = "select",
				name = L["Bar texture"],
				values = "GetTextures",
				width = "double",
				arg = "texture",
			},
			location = {
				order =5,
				type = "select",
				name = L["Redirect bars to group"],
				desc = L["Group name to redirect bars to, this lets you show DRTracker timers under another addons bar group. Requires the bars to be created using GTB."],
				values = "GetGroups",
				width = "double",
				arg = "redirectTo",
			},
			enabledIn = {
				order = 6,
				type = "multiselect",
				name = L["Enable DRTracker inside"],
				desc = L["Allows you to set what scenario's DRTracker should be enabled inside."],
				values = enabledIn,
				set = setMulti,
				get = getMulti,
				width = "double",
				arg = "inside"
			},
		},
	}
	
	options.args.spells = {
		type = "group",
		order = 3,
		name = L["Spells"],
		get = get,
		set = set,
		handler = Config,
		args = {
			desc = {
				order = 0,
				type = "description",
				name = L["Lets you choose which spells should not be tracked in both time left, and diminishing returns."],
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
	local alreadyAdded = {}
	for spellID in pairs(DRTracker.spells) do
		local spellName = GetSpellInfo(spellID)
		if( not alreadyAdded[spellName] ) then
			alreadyAdded[spellName] = true
			
			options.args.spells.args.list.args[tostring(spellID)] = {
				order = 1,
				type = "toggle",
				name = spellName,
				desc = string.format(L["Disable timers for %s"], spellName),
				arg = "disableSpells." .. spellName,
			}
		end
	end

	-- DB Profiles
	options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(DRTracker.db)
	options.args.profile.order = 2
end

-- Slash commands
SLASH_DRTRACKER1 = "/drtracker"
SLASH_DRTracker = "/drt"
SlashCmdList["DRTRACKER"] = function(msg)
	if( msg == "clear" ) then
		DRTracker.GTBGroup:UnregisterAllBars()
	elseif( msg == "test" ) then
		local GTBGroup = DRTracker.GTBGroup
		GTBGroup:UnregisterAllBars()
		GTBGroup:SetTexture(SML:Fetch(SML.MediaType.STATUSBAR, DRTracker.db.profile.texture))
		GTBGroup:RegisterBar(1, 10, string.format("%s - %s", (select(1, GetSpellInfo(10890))), UnitName("player")), (select(3, GetSpellInfo(10890))))
		GTBGroup:RegisterBar(2, 15, string.format("%s - %s", (select(1, GetSpellInfo(26989))), UnitName("player")), (select(3, GetSpellInfo(26989))))
		GTBGroup:RegisterBar(3, 20, string.format("%s - %s", (select(1, GetSpellInfo(33786))), UnitName("player")), (select(3, GetSpellInfo(33786))))
	elseif( msg == "ui" ) then
		if( not registered ) then
			if( not options ) then
				loadOptions()
			end
			
			config:RegisterOptionsTable("DRTracker", options)
			dialog:SetDefaultSize("DRTracker", 600, 500)
			registered = true
		end

		dialog:Open("DRTracker")
	else
		DEFAULT_CHAT_FRAME:AddMessage(L["DRTracker slash commands"])
		DEFAULT_CHAT_FRAME:AddMessage(L["- clear - Clears all running timers."])
		DEFAULT_CHAT_FRAME:AddMessage(L["- test - Shows test timers in DRTracker."])
		DEFAULT_CHAT_FRAME:AddMessage(L["- ui - Opens the configuration for DRTracker."])
	end
end

-- Add the general options + profile, we don't add spells/anchors because it doesn't support sub cats
local register = CreateFrame("Frame", nil, InterfaceOptionsFrame)
register:SetScript("OnShow", function(self)
	self:SetScript("OnShow", nil)
	loadOptions()

	config:RegisterOptionsTable("DRTracker-Bliz", {
		name = "DRTracker",
		type = "group",
		args = {
			help = {
				type = "description",
				name = string.format("DRTracker r%d is a diminishing returns tracker for PvP", DRTracker.revision or 0),
			},
		},
	})
	
	dialog:SetDefaultSize("DRTracker-Bliz", 600, 400)
	dialog:AddToBlizOptions("DRTracker-Bliz", "DRTracker")
	
	config:RegisterOptionsTable("DRTracker-General", options.args.general)
	dialog:AddToBlizOptions("DRTracker-General", options.args.general.name, "DRTracker")

	config:RegisterOptionsTable("DRTracker-Profile", options.args.profile)
	dialog:AddToBlizOptions("DRTracker-Profile", options.args.profile.name, "DRTracker")
end)
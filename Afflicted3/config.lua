if( not Afflicted ) then return end

local Config = Afflicted:NewModule("Config")
local L = AfflictedLocals

local SML, registered, options, config, dialog

function Config:OnInitialize()
	config = LibStub("AceConfig-3.0")
	dialog = LibStub("AceConfigDialog-3.0")

	SML = Afflicted.SML
	SML:Register(SML.MediaType.STATUSBAR, "BantoBar", "Interface\\Addons\\Afflicted3\\images\\banto")
	SML:Register(SML.MediaType.STATUSBAR, "Smooth",   "Interface\\Addons\\Afflicted3\\images\\smooth")
	SML:Register(SML.MediaType.STATUSBAR, "Perl",     "Interface\\Addons\\Afflicted3\\images\\perl")
	SML:Register(SML.MediaType.STATUSBAR, "Glaze",    "Interface\\Addons\\Afflicted3\\images\\glaze")
	SML:Register(SML.MediaType.STATUSBAR, "Charcoal", "Interface\\Addons\\Afflicted3\\images\\Charcoal")
	SML:Register(SML.MediaType.STATUSBAR, "Otravi",   "Interface\\Addons\\Afflicted3\\images\\otravi")
	SML:Register(SML.MediaType.STATUSBAR, "Striped",  "Interface\\Addons\\Afflicted3\\images\\striped")
	SML:Register(SML.MediaType.STATUSBAR, "LiteStep", "Interface\\Addons\\Afflicted3\\images\\LiteStep")
end

-- Force deletes all modified default spells
function Config:Purge()
	for id in pairs(AfflictedSpells) do
		self.db.profile.spells[id] = nil
	end
end

-- GUI
local announceDest = {["none"] = L["None"], ["ct"] = L["Combat text"], ["party"] = L["Party"], ["raid"] = L["Raid"], ["rw"] = L["Raid warning"], ["rwframe"] = L["Middle of screen"], ["1"] = string.format(L["Chat frame #%d"], 1), ["2"] = string.format(L["Chat frame #%d"], 2), ["3"] = string.format(L["Chat frame #%d"], 3), ["4"] = string.format(L["Chat frame #%d"], 4), ["5"] = string.format(L["Chat frame #%d"], 5), ["6"] = string.format(L["Chat frame #%d"], 6), ["7"] = string.format(L["Chat frame #%d"], 7)}

-- Return all fonts
local fonts = {}
function Config:GetFonts()
	for k in pairs(fonts) do fonts[k] = nil end

	for _, name in pairs(SML:List(SML.MediaType.FONT)) do
		fonts[name] = name
	end
	
	return fonts
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
	for name, data in pairs(Afflicted.modules.Bars.GTB:GetGroups()) do
		groups[name] = name
	end
	
	return groups
end

-- Database things
local globalOptions = {["displayType"] = "", ["scale"] = 1, ["maxRows"] = 10, ["growUp"] = false}
local function getGlobalOption(info)
	return globalOptions[info[#(info)]]
end

local function setGlobalOption(info, value)
	if( info.arg == "displayType" and value == "" ) then
		return
	end
	
	for name, anchor in pairs(Afflicted.db.profile.anchors) do
		anchor[info[#(info)]] = value
	end
	
	globalOptions[info[#(info)]] = value

	Afflicted.modules.Bars:ReloadVisual()
	Afflicted.modules.Icons:ReloadVisual()
end

-- General option
local function loadOptions()
	options = {}
	options.type = "group"
	options.name = "Afflicted"
	
	options.args = {}
	options.args.general = {
		type = "group",
		order = 1,
		name = L["General"],
		set = function(info, value)
			Afflicted.db.profile[info[#(info)]] = value
			Afflicted:Reload()
		end,
		get = function(info)
			return Afflicted.db.profile[info[#(info)]]
		end,
		handler = Config,
		args = {
			showAnchors = {
				order = 1,
				type = "toggle",
				name = L["Show timer anchors"],
				desc = L["Show the anchors that lets you drag timer groups around."],
			},
			enabledIn = {
				order = 2,
				type = "multiselect",
				name = L["Enable inside"],
				values = {["none"] = L["Everywhere else"], ["pvp"] = L["Battlegrounds"], ["arena"] = L["Arenas"], ["raid"] = L["Raid instances"], ["party"] = L["Party instances"]},
				set = function(info, value, state)
					Afflicted.db.profile[info[#(info)]][value] = state
					Afflicted:Reload()
				end,
				get = function(info)
					return Afflicted.db.profile[info[#(info)]]
				end,
				width = "double",
				arg = "inside"
			},
			display = {
				order = 3,
				type = "group",
				inline = true,
				name = L["Display"],
				args = {
					desc = {
						order = 0,
						name = L["Global display setting, changing these will change all the anchors settings.\nNOTE: These values do not reflect each anchors configuration, this is just a quick way to set all of them to the same thing."],
						type = "description",
					},
					growUp = {
						order = 1,
						type = "toggle",
						name = L["Grow up"],
						desc = L["Instead of adding everything from top to bottom, timers will be shown from bottom to top."],
						get = getGlobalOption,
						set = setGlobalOption,
						width = "full",
					},
					targetOnly = {
						order = 2,
						type = "toggle",
						name = L["Only show target/focus timers"],
						desc = L["Only timers of people you have targeted, or focused will be triggered. They will not be removed if you change targets however."],   
						width = "full",
					},
					display = {
						order = 3,
						type = "select",
						name = L["Display style"],
						values = {[""] = "----", ["bar"] = L["Bars"], ["icon"] = L["Icons"]},
						get = getGlobalOption,
						set = setGlobalOption,
					},
					sep = {
						order = 4,
						name = "",
						type = "description",
					},
					scale = {
						order = 5,
						type = "range",
						name = L["Scale"],
						min = 0, max = 2, step = 0.01,
						get = getGlobalOption,
						set = setGlobalOption,
					},
					maxRows = {
						order = 6,
						type = "range",
						name = L["Max timers"],
						desc = L["Maximum amount of timers that should be ran per an anchor at the same time, if too many are running at the same time then the new ones will simply be hidden until older ones are removed."],
						min = 1, max = 50, step = 1,
						get = getGlobalOption,
						set = setGlobalOption,
					},
					display = {
						order = 8,
						type = "group",
						inline = true,
						name = L["Bar only"],
						args = {
							desc = {
								order = 0,
								name = L["Configuration that only applies to bar displays."],
								type = "description",
							},
							barNameOnly = {
								order = 1,
								type = "toggle",
								name = L["Only show triggered name in text"],
								desc = L["Instead of showing both the spell name and the triggered name, only the name will be shown in the bar."],
								width = "full",
								arg = "barNameOnly",
							},
							barWidth = {
								order = 2,
								type = "range",
								name = L["Width"],
								min = 0, max = 300, step = 1,
							},
							fontSize = {
								order = 3,
								type = "range",
								name = L["Font size"],
								min = 1, max = 20, step = 1,
							},
							sep = {
								order = 4,
								name = "",
								type = "description",
							},
							barName = {
								order = 5,
								type = "select",
								name = L["Texture"],
								dialogControl = "LSM30_Statusbar",
								values = "GetTextures",
							},
							fontName = {
								order = 6,
								type = "select",
								name = L["Font name"],
								dialogControl = "LSM30_Font",
								values = "GetFonts",
							},
						},
					},
				},
			},
		},
	}
	
	-- DB Profiles
	options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(Afflicted.db)
	options.args.profile.order = 2
end

-- Slash commands
SLASH_AFFLICTED1 = "/afflicted3"
SLASH_AFFLICTED2 = "/afflicted"
SLASH_AFFLICTED3 = "/afflict"
SlashCmdList["AFFLICTED"] = function(msg)
	msg = string.lower(msg or "")
	
	local self = Afflicted
	if( msg == "clear" ) then
		for name, data in pairs(self.db.profile.anchors) do
			self[data.display]:ClearTimers(name)
		end
	elseif( msg == "test" ) then
		-- Clear out any running timers first
		local totalAnchors = 0
		for name, data in pairs(self.db.profile.anchors) do
			totalAnchors = totalAnchors + 1
			self[data.display]:ClearTimers(name)
		end
		
		local added = {}
		local addedCount = 0
		for id in pairs(self.db.profile.spells) do
			local spell = self.spells[id]
			if( type(id) == "number" and type(spell) == "table" ) then
				local spellName, _, spellIcon = GetSpellInfo(id)
				
				if( spell.anchor and spell.duration and not added[spell.anchor] ) then
					added[spell.anchor] = true
					addedCount = addedCount + 1
					self:CreateTimer(UnitGUID("player"), UnitName("player"), spell.anchor, spell.repeating, false, spell.duration, id, spellName, spellIcon)
				end
				
				if( spell.cdAnchor and spell.cooldown and not added[spell.cdAnchor] ) then
					added[spell.cdAnchor] = true
					addedCount = addedCount + 1
					self:CreateTimer(UnitGUID("player"), UnitName("player"), spell.cdAnchor, false, true, spell.cooldown, id, spellName, spellIcon)
				end
				
				-- We have at least one timer in each anchor now
				if( addedCount >= totalAnchors ) then
					break
				end
			end
		end

	elseif( msg == "ui" ) then
		if( not registered ) then
			if( not options ) then
				loadOptions()
			end
			
			config:RegisterOptionsTable("Afflicted3", options)
			dialog:SetDefaultSize("Afflicted3", 640, 590)
			registered = true
		end

		dialog:Open("Afflicted3")
	else
		Afflicted:Print(L["Slash commands"])
		DEFAULT_CHAT_FRAME:AddMessage(L["- clear - Clears all running timers."])
		DEFAULT_CHAT_FRAME:AddMessage(L["- test - Shows test timers in Afflicted."])
		DEFAULT_CHAT_FRAME:AddMessage(L["- ui - Opens the configuration for Afflicted."])
	end
end
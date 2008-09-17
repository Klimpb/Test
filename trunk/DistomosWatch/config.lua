if( not DistWatch ) then return end

local Config = DistWatch:NewModule("Config")
local L = DistWatchLocals

local SML, registered, options, config, dialog

function Config:OnInitialize()
	config = LibStub("AceConfig-3.0")
	dialog = LibStub("AceConfigDialog-3.0")
	
	-- Register bar textures
	SML = LibStub:GetLibrary("LibSharedMedia-3.0")
	SML:Register(SML.MediaType.STATUSBAR, "BantoBar",   "Interface\\Addons\\DistomosWatch\\images\\banto")
	SML:Register(SML.MediaType.STATUSBAR, "Smooth",     "Interface\\Addons\\DistomosWatch\\images\\smooth")
	SML:Register(SML.MediaType.STATUSBAR, "Perl",       "Interface\\Addons\\DistomosWatch\\images\\perl")
	SML:Register(SML.MediaType.STATUSBAR, "Glaze",      "Interface\\Addons\\DistomosWatch\\images\\glaze")
	SML:Register(SML.MediaType.STATUSBAR, "Charcoal",   "Interface\\Addons\\DistomosWatch\\images\\Charcoal")
	SML:Register(SML.MediaType.STATUSBAR, "Otravi",     "Interface\\Addons\\DistomosWatch\\images\\otravi")
	SML:Register(SML.MediaType.STATUSBAR, "Striped",    "Interface\\Addons\\DistomosWatch\\images\\striped")
	SML:Register(SML.MediaType.STATUSBAR, "LiteStep",   "Interface\\Addons\\DistomosWatch\\images\\LiteStep")
	SML:Register(SML.MediaType.STATUSBAR, "Minimalist", "Interface\\Addons\\DistomosWatch\\images\\Minimalist")
end

local function set(info, value)
	DistWatch.db.profile[info[(#info)]] = value
	DistWatch:Reload()
end

local function get(info)
	return DistWatch.db.profile[info[(#info)]]
end

local function setNumber(info, value)
	set(info, tonumber(value))
end

local function setMulti(info, state, value)
	DistWatch.db.profile[info[(#info)]][state] = value
	DistWatch:Reload()
end

local function getMulti(info, state)
	return DistWatch.db.profile[info[(#info)]][state]
end

-- Set/Get colors
local function setColor(info, r, g, b)
	set(info, {r = r, g = g, b = b})
end

local function getColor(info)
	local value = get(info)
	if( type(value) == "table" ) then
		return value.r, value.g, value.b
	end
	
	return value
end

-- Grab textures/font
local textures = {}
function Config:GetTextures()
	for k in pairs(textures) do textures[k] = nil end

	for _, name in pairs(SML:List(SML.MediaType.STATUSBAR)) do
		textures[name] = name
	end
	
	return textures
end

local fonts = {}
function Config:GetFonts()
	for k in pairs(fonts) do fonts[k] = nil end

	for _, name in pairs(SML:List(SML.MediaType.FONT)) do
		fonts[name] = name
	end
	
	return fonts
end

local groups = {}
local GTB
function Config:GetGroups()
	for k in pairs(groups) do groups[k] = nil end
	
	if( not GTB ) then
		GTB = LibStub("GTB-1.0")
	end
	
	groups[""] = L["None"]
	for name, data in pairs(GTB:GetGroups()) do
		groups[name] = name
	end
	
	return groups
end

local function loadOptions()
	options = {}
	options.type = "group"
	options.name = "Distomos Watch"
	
	options.args = {}
	options.args.general = {
		type = "group",
		order = 1,
		name = L["General"],
		get = get,
		set = set,
		handler = Config,
		args = {
			general = {
				order = 1,
				type = "group",
				inline = true,
				name = L["General"],
				args = {
					showAnchor = {
						order = 0,
						type = "toggle",
						name = L["Show anchor"],
					},
					showOthers = {
						order = 0,
						type = "toggle",
						name = L["Show owner names"],
						desc = L["Shows who owns the Prayer of Mending as long as it's not yourself.\nThis feature is not perfect, and isn't 100% accurate."],
					},
					growUp = {
						order = 1,
						type = "toggle",
						name = L["Grow display up"],
						desc = L["Instead of adding everything from top to bottom, timers will be shown from bottom to top."],
					},
					gradient = {
						order = 2,
						type = "toggle",
						name = L["Enable color gradient"],
						desc = L["Fades the bar from your designated color to red depending on the duration left."],
					},
					sep = {
						order = 3,
						name = "",
						type = "description",
					},
					redirectTo = {
						order = 4,
						type = "select",
						name = L["Redirect bars to group"],
						values = "GetGroups",
					},
					icon = {
						order = 5,
						type = "select",
						name = L["Icon position"],
						values = {["LEFT"] = L["Left"], ["RIGHT"] = L["Right"]},
					},
					sep = {
						order = 6,
						name = "",
						type = "description",
					},
					fadeTime = {
						order = 7,
						type = "range",
						name = L["Fade time"],
						min = 0, max = 2, step = 0.01,
					},
					sep = {
						order = 8,
						name = "",
						type = "description",
					},
					scale = {
						order = 9,
						type = "range",
						name = L["Display scale"],
						min = 0, max = 2, step = 0.01,
					},
					maxRows = {
						order = 10,
						type = "range",
						name = L["Max timers"],
						min = 1, max = 100, step = 1,
					},
					sep = {
						order = 11,
						name = "",
						type = "description",
					},
					inside = {
						order = 12,
						type = "multiselect",
						name = L["Enable Distomos Watch inside"],
						desc = L["Allows you to choose which scenarios this mod should be enabled in."],
						values = {["none"] = L["Everywhere else"], ["pvp"] = L["Battlegrounds"], ["arena"] = L["Arenas"], ["raid"] = L["Raid instances"], ["party"] = L["Party instances"]},
						set = setMulti,
						get = getMulti,
					},
				}
			},
			bar = {
				order = 2,
				type = "group",
				inline = true,
				name = L["Bar display"],
				args = {
 					color = {
						order = 1,
						type = "color",
						--name = L["Others mend color"],
						name = L["Color"],
						--desc = L["Bar color for Prayer of Mending that someone in the raid casted."],
						set = setColor,
						get = getColor,
					},
 					--[[
 					ourColor = {
						order = 1,
						type = "color",
						name = L["My mend color"],
						desc = L["Bar color for Prayer of Mending that we casted."],
						set = setColor,
						get = getColor,
					},
					]]
					sep = {
						order = 4,
						name = "",
						type = "description",
					},
					width = {
						order = 3,
						type = "range",
						name = L["Width"],
						min = 50, max = 300, step = 1,
						set = setNumber,
					},
					texture = {
						order = 5,
						type = "select",
						name = L["Texture"],
						dialogControl = "LSM30_Statusbar",
						values = "GetTextures",
					},
				},
			},
			text = {
				order = 3,
				type = "group",
				inline = true,
				name = L["Text"],
				args = {
					fontSize = {
						order = 1,
						type = "range",
						name = L["Size"],
						min = 1, max = 20, step = 1,
						set = setNumber,
					},
					fontName = {
						order = 2,
						type = "select",
						name = L["Font"],
						dialogControl = "LSM30_Font",
						values = "GetFonts",
					},
				},
			},
		}
	}

	-- DB Profiles
	options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(DistWatch.db)
	options.args.profile.order = 5
end

-- Slash commands
SLASH_DISTWATCH1 = "/dw"
SLASH_DISTWATCH2 = "/distwatch"
SLASH_DISTWATCH3 = "/distomoswatch"
SlashCmdList["DISTWATCH"] = function(msg)
	msg = string.lower(msg or "")
	if( msg == "about" ) then
		DistWatch:Print("Made for a very picky Priest who can't make up her mind on anything at all!")
		return
	elseif( msg == "test" ) then
		DistWatch:Test()
		return
	elseif( msg == "clear" ) then
		DistWatch:Clear()
		return
	end
	
	if( not registered ) then
		if( not options ) then
			loadOptions()
		end

		config:RegisterOptionsTable("DistWatch", options)
		dialog:SetDefaultSize("DistWatch", 650, 525)
		registered = true
	end

	dialog:Open("DistWatch")
end

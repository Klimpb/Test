if( not Nameplates ) then return end

local Config = Nameplates:NewModule("Config")
local L = NameplatesLocals

local SML, registered, options, config, dialog

function Config:OnInitialize()
	config = LibStub("AceConfig-3.0")
	dialog = LibStub("AceConfigDialog-3.0")
	
	SML = LibStub:GetLibrary("LibSharedMedia-3.0")
	SML:Register(SML.MediaType.STATUSBAR, "BantoBar", "Interface\\Addons\\Nameplates\\images\\banto")
	SML:Register(SML.MediaType.STATUSBAR, "Smooth",   "Interface\\Addons\\Nameplates\\images\\smooth")
	SML:Register(SML.MediaType.STATUSBAR, "Perl",     "Interface\\Addons\\Nameplates\\images\\perl")
	SML:Register(SML.MediaType.STATUSBAR, "Glaze",    "Interface\\Addons\\Nameplates\\images\\glaze")
	SML:Register(SML.MediaType.STATUSBAR, "Charcoal", "Interface\\Addons\\Nameplates\\images\\Charcoal")
	SML:Register(SML.MediaType.STATUSBAR, "Otravi",   "Interface\\Addons\\Nameplates\\images\\otravi")
	SML:Register(SML.MediaType.STATUSBAR, "Striped",  "Interface\\Addons\\Nameplates\\images\\striped")
	SML:Register(SML.MediaType.STATUSBAR, "LiteStep", "Interface\\Addons\\Nameplates\\images\\LiteStep")
	SML:Register(SML.MediaType.STATUSBAR, "Nameplates Default", "Interface\\TargetingFrame\\UI-TargetingFrame-BarFill")
end

-- GUI
local function set(info, value)
	local arg1, arg2, arg3, arg4 = string.split(".", info.arg)
	if( tonumber(arg2) ) then arg2 = tonumber(arg2) end
	
	if( arg2 and arg3 and arg4 ) then
		Nameplates.db.profile[arg1][arg2][arg3][arg4] = value
	elseif( arg2 and arg3 ) then
		Nameplates.db.profile[arg1][arg2][arg3] = value
	elseif( arg2 ) then
		Nameplates.db.profile[arg1][arg2] = value
	else
		Nameplates.db.profile[arg1] = value
	end
	
	Nameplates:Reload()
end

local function get(info)
	local arg1, arg2, arg3, arg4 = string.split(".", info.arg)
	if( tonumber(arg2) ) then arg2 = tonumber(arg2) end
	
	if( arg2 and arg3 and arg4 ) then
		return Nameplates.db.profile[arg1][arg2][arg3][arg4]
	elseif( arg2 and arg3 ) then
		return Nameplates.db.profile[arg1][arg2][arg3]
	elseif( arg2 ) then
		return Nameplates.db.profile[arg1][arg2]
	else
		return Nameplates.db.profile[arg1]
	end
end

local function setNumber(info, value)
	set(info, tonumber(value))
end

local function getString(info)
	return tostring(get(info))
end

-- Yes this is a quick hack
local function setColor(info, r, g, b, a)
	local arg1, arg2, arg3 = string.split(".", info.arg)
	if( tonumber(arg2) ) then arg2 = tonumber(arg2) end
	
	if( arg2 and arg3 and arg4 ) then
		Nameplates.db.profile[arg1][arg2][arg3][arg4].r = r
		Nameplates.db.profile[arg1][arg2][arg3][arg4].g = g
		Nameplates.db.profile[arg1][arg2][arg3][arg4].b = b
		Nameplates.db.profile[arg1][arg2][arg3][arg4].a = a
	elseif( arg2 and arg3 ) then
		Nameplates.db.profile[arg1][arg2][arg3].r = r
		Nameplates.db.profile[arg1][arg2][arg3].g = g
		Nameplates.db.profile[arg1][arg2][arg3].b = b
		Nameplates.db.profile[arg1][arg2][arg3].a = a
	elseif( arg2 ) then
		Nameplates.db.profile[arg1][arg2].r = r
		Nameplates.db.profile[arg1][arg2].g = g
		Nameplates.db.profile[arg1][arg2].b = b
		Nameplates.db.profile[arg1][arg2].a = a
	else
		Nameplates.db.profile[arg1].r = r
		Nameplates.db.profile[arg1].g = g
		Nameplates.db.profile[arg1].b = b
		Nameplates.db.profile[arg1].a = a
	end
	
	Nameplates:Reload()
end

local function getColor(info)
	local value = get(info)
	return value.r, value.g, value.b, value.a
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

-- Return all registered SML textures
local borders = {}
function Config:GetBorderTextures()
	for k in pairs(borders) do borders[k] = nil end

	for _, name in pairs(SML:List(SML.MediaType.BORDER)) do
		borders[name] = name
	end
	
	return borders
end

-- Return all registered SML textures
local backgrounds = {}
function Config:GetBackgroundTextures()
	for k in pairs(backgrounds) do backgrounds[k] = nil end

	for _, name in pairs(SML:List(SML.MediaType.BACKGROUND)) do
		backgrounds[name] = name
	end
	
	return backgrounds
end

-- Return all registered SML fonts
local fonts = {}
function Config:GetFonts()
	for k in pairs(fonts) do fonts[k] = nil end

	for _, name in pairs(SML:List(SML.MediaType.FONT)) do
		fonts[name] = name
	end
	
	return fonts
end

local points = {[""] = L["None"], ["TOP"] = L["Top"], ["BOTTOM"] = L["Bottom"], ["LEFT"] = L["Left"], ["RIGHT"] = L["Right"], ["TOPRIGHT"] = L["Top Right"], ["TOPLEFT"] = L["Top Left"], ["CENTER"] = L["Center"], ["BOTTOMLEFT"] = L["Bottom Left"], ["BOTTOMRIGHT"] = L["Bottom Right"]}
function Config:CreateUIObject(id)
--[[
UIObject:
uiobject = {
	hide = <status>,
	width = 120,
	height = 10,
	alpha = 1.0,
	position = { point = "<point>", relativePoint = "<point>", x = 0, y = 0, },
},
]]
	return {
		order = 1,
		type = "group",
		inline = true,
		name = L["General UI"],
		args = {
			desc = {
				order = 0,
				type = "description",
				name = L["Basic ui object configuration, visability, size and positioning."],
			},
			hide = {
				order = 1,
				type = "toggle",
				name = L["Hide frame"],
				width = "double",
				arg = string.format("%s.uiobject.hide", id),
			},
			width = {
				order = 2,
				type = "range",
				name = L["Width"],
				min = 0, max = 300, step = 1,
				set = setNumber,
				arg = string.format("%s.uiobject.width", id),
			},
			height = {
				order = 3,
				type = "range",
				name = L["Height"],
				min = 0, max = 300, step = 1,
				set = setNumber,
				arg = string.format("%s.uiobject.height", id),
			},
			alpha = {
				order = 4,
				type = "range",
				name = L["Alpha"],
				min = 0, max = 1, step = 0.1,
				set = setNumber,
				width = "double",
				arg = string.format("%s.uiobject.alpha", id),
			},
			position = {
				order = 5,
				type = "group",
				inline = true,
				name = L["Positioning"],
				args = {
					enabled = {
						order = 0,
						type = "toggle",
						name = L["Enable positioning"],
						width = "double",
						arg = string.format("%s.uiobject.positionEnabled", id),
					},
					--[[
					point = {
						order = 1,
						type = "select",
						name = L["Point"],
						values = points,
						arg = string.format("%s.uiobject.position.point", id),
					},
					relativePoint = {
						order = 2,
						type = "select",
						name = L["Relative Point"],
						values = points,
						arg = string.format("%s.uiobject.position.relativePoint", id),
					},
					]]
					x = {
						order = 3,
						type = "input",
						name = L["X Position"],
						desc = L["How many seconds this timer should last."],
						validate = function(info, value) return tonumber(value) end,
						get = getString,
						set = setNumber,
						arg = string.format("%s.uiobject.x", id),
					},
					y = {
						order = 4,
						type = "input",
						name = L["Y Position"],
						desc = L["How many seconds this timer should last."],
						validate = function(info, value) return tonumber(value) end,
						get = getString,
						set = setNumber,
						arg = string.format("%s.uiobject.y", id),
					},
				},
			},
		},
	}
end

local fontBorders = {[""] = L["None"], ["OUTLINE"] = L["Outline"], ["THICKOUTLINE"] = L["Thick outline"], ["MONOCHROME"] = L["Monochrome"]}
local fontJustifyH = {["LEFT"] = L["Left"], ["CENTER"] = L["Center"], ["RIGHT"] = L["Right"]}
function Config:CreateFontString(id)
--[[
Font String:
font = {
	name = "<font name from SML>",
	size = <font size>
	border = <OUTLINE/THICKOUTLINE/MONOCHROME>,
	
	shadowColor = { r = 0, g = 0, b = 0, a = 1.0 },
	offset = { x = 0, y = 0 },
},
]]
	return {
		order = 1,
		type = "group",
		inline = true,
		name = L["Font String"],
		args = {
			desc = {
				order = 0,
				type = "description",
				name = L["Basic text configuration, like font, name or size."],
			},
			general = {
				order = 1,
				type = "group",
				inline = true,
				name = L["General"],
				args = {
					enabled = {
						order = 0,
						type = "toggle",
						name = L["Enable font"],
						width = "double",
						arg = string.format("%s.font.enabled", id),
					},
					font = {
						order = 1,
						type = "select",
						name = L["Font name"],
						values = "GetFonts",
						arg = string.format("%s.font.name", id)
					},
					type = {
						order = 2,
						type = "range",
						name = L["Font size"],
						min = 1, max = 20, step = 1,
						set = setNumber,
						arg = string.format("%s.font.size", id),
					},
					border = {
						order = 3,
						type = "select",
						name = L["Font border"],
						values = fontBorders,
						arg = string.format("%s.font.border", id)
					},
					justifyH = {
						order = 4,
						type = "select",
						name = L["Horizontal justify"],
						values = fontJustifyH,
						arg = string.format("%s.font.justifyH", id)
					},
				},
			},
			shadow = {
				order = 2,
				type = "group",
				inline = true,
				name = L["Shadow"],
				args = {
					enabled = {
						order = 0,
						type = "toggle",
						name = L["Enable shadow"],
						width = "double",
						arg = string.format("%s.font.shadowEnabled", id),
					},
					color = {
						order = 1,
						type = "color",
						name = L["Shadow color"],
						hasAlpha = true,
						set = setColor,
						get = getColor,
						arg = string.format("%s.font.shadowColor", id),
					},
					x = {
						order = 2,
						type = "range",
						name = L["Shadow offset X"],
						min = -2, max = 2, step = 1,
						set = setNumber,
						arg = string.format("%s.font.offset.x", id),
					},
					y = {
						order = 3,
						type = "range",
						name = L["Shadow offset Y"],
						min = -2, max = 2, step = 1,
						set = setNumber,
						arg = string.format("%s.font.offset.y", id),
					},
				},
			},
		},
	}
end

function Config:CreateFrame(id)
--[[
Frame:
frame = {
	bgColor = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 },
	borderColor = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 },
	bgName = "<border from SML>",
	edgeName = "<edge from SML>",
	edgeSize = <edge size>,
	insets = { left = 1, right = 1, top = 1, bottom = 1 },
},
]]
	return {
		order = 2,
		type = "group",
		inline = true,
		name = L["Frame"],
		args = {
			desc = {
				order = 0,
				type = "description",
				name = L["Basic frame configuration, like backdrop configuration."],
			},
			enabled = {
				order = 1,
				type = "toggle",
				name = L["Enable backdrop"],
				width = "double",
				arg = string.format("%s.frame.backdropEnabled", id),
			},
			bgColor = {
				order = 2,
				type = "color",
				name = L["Background color"],
				hasAlpha = true,
				set = setColor,
				get = getColor,
				arg = string.format("%s.frame.bgColor", id),
			},
			borderColor = {
				order = 3,
				type = "color",
				name = L["Border color"],
				hasAlpha = true,
				set = setColor,
				get = getColor,
				arg = string.format("%s.frame.borderColor", id),
			},
			borderName = {
				order = 4,
				type = "select",
				name = L["Border texture"],
				values = "GetBorderTextures",
				arg = string.format("%s.frame.edgeName", id),
			},
			bgName = {
				order = 5,
				type = "select",
				name = L["Background texture"],
				values = "GetBackgroundTextures",
				arg = string.format("%s.frame.bgName", id),
			},
			edgeSize = {
				order = 6,
				type = "range",
				name = L["Edge size"],
				min = 0.1, max = 30, step = 0.1,
				set = setNumber,
				arg = string.format("%s.frame.edgeSize", id),
			},
			insets = {
				order = 7,
				type = "group",
				inline = true,
				name = L["Insets"],
				args = {
					desc = {
						order = 0,
						type = "description",
						name = L["Padding between the frame and the border."],
					},
					left = {
						order = 1,
						type = "range",
						name = L["Left"],
						min = 0, max = 10, step = 0.1,
						set = setNumber,
						arg = string.format("%s.frame.insets.left", id),
					},
					right = {
						order = 2,
						type = "range",
						name = L["Right"],
						min = 0, max = 10, step = 0.1,
						set = setNumber,
						arg = string.format("%s.frame.insets.right", id),
					},
					top = {
						order = 3,
						type = "range",
						name = L["Top"],
						min = 0, max = 10, step = 0.1,
						set = setNumber,
						arg = string.format("%s.frame.insets.top", id),
					},
					bottom = {
						order = 4,
						type = "range",
						name = L["Bottom"],
						min = 0, max = 10, step = 0.1,
						set = setNumber,
						arg = string.format("%s.frame.insets.bottom", id),
					},
				},
			},
		},
	}
end

function Config:CreateTexture(id)
--[[
Texture:
texture = {
	name = "<texture name from SML>",
},
]]	return {
		order = 3,
		type = "group",
		inline = true,
		name = L["Texture"],
		args = {
			desc = {
				order = 0,
				type = "description",
				name = L["Basic texture configuration, like the actual bar texture."],
			},
			texture = {
				order = 1,
				type = "select",
				name = L["Texture"],
				values = "GetTextures",
				arg = string.format("%s.texture.name", id),
			},
		},
	}
end

local fontBorders = {[""] = L["None"], ["OUTLINE"] = L["Outline"], ["THICKOUTLINE"] = L["Thick outline"], ["MONOCHROME"] = L["Monochrome"]}

local function loadOptions()
	options = {}
	options.type = "group"
	options.name = "Nameplates"
	
	options.args = {}


	-- Name text
	options.args.name = {
		type = "group",
		order = 3,
		name = L["Name text"],
		get = get,
		set = set,
		handler = Config,
		args = {
			font = Config:CreateFontString("name"),
			uiobject = Config:CreateUIObject("name"),
		}
	}

	options.args.name.args.uiobject.args.width = nil
	options.args.name.args.uiobject.args.height = nil
	
	-- Level text
	options.args.level = {
		type = "group",
		order = 3,
		name = L["Level text"],
		get = get,
		set = set,
		handler = Config,
		args = {
			font = Config:CreateFontString("level"),
			uiobject = Config:CreateUIObject("level"),
		}
	}

	options.args.level.args.uiobject.args.width = nil
	options.args.level.args.uiobject.args.height = nil

	-- Health bar
	options.args.health = {
		type = "group",
		order = 3,
		name = L["Health bar"],
		get = get,
		set = set,
		handler = Config,
		args = {
			frame = Config:CreateFrame("health"),
			texture = Config:CreateTexture("health"),
			uiobject = Config:CreateUIObject("health"),
		}
	}
	
	options.args.health.args.frame.args.hide = nil

	-- Health bar border
	options.args.healthBorder = {
		type = "group",
		order = 3,
		name = L["Health border"],
		get = get,
		set = set,
		handler = Config,
		args = {
			general = {
				order = 1,
				type = "group",
				inline = true,
				name = L["General UI"],
				args = {
					desc = {
						order = 0,
						type = "description",
						name = L["Basic ui object configuration, visability, size and positioning."],
					},
					hide = {
						order = 1,
						type = "toggle",
						name = L["Hide frame"],
						width = "double",
						arg = string.format("%s.uiobject.hide", "healthBorder"),
					},
				},
			},
		}
	}

	-- Health bar text
	options.args.healthText = {
		type = "group",
		order = 3,
		name = L["Health bar text"],
		get = get,
		set = set,
		handler = Config,
		args = {
			health = {
				order = 0,
				type = "select",
				name = L["Health text display"],
				desc = L["Style of display for health bar text."],
				values = {["none"] = L["None"], ["minmax"] = L["Min / Max"], ["deff"] = L["Deficit"], ["percent"] = L["Percent"]},
				arg = "healthType",
			},
			
			font = Config:CreateFontString("healthText"),
			uiobject = Config:CreateUIObject("healthText"),
		}
	}

	options.args.healthText.args.uiobject.args.width = nil
	options.args.healthText.args.uiobject.args.height = nil

	-- Cast bar
	options.args.cast = {
		type = "group",
		order = 3,
		name = L["Cast bar"],
		get = get,
		set = set,
		handler = Config,
		args = {
			cast = {
				order = 0,
				type = "select",
				name = L["Cast text display"],
				desc = L["Style of display for cast bar text."],
				values = {["crtmax"] = L["Current / Max"], ["none"] = L["None"], ["crt"] = L["Current"], ["percent"] = L["Percent"], ["timeleft"] = L["Time left"]},
				arg = "castType",
			},

			frame = Config:CreateFrame("cast"),
			texture = Config:CreateTexture("cast"),
			uiobject = Config:CreateUIObject("cast"),
		}
	}

	options.args.health.args.frame.args.hide = nil

	-- Cast bar text
	options.args.castText = {
		type = "group",
		order = 3,
		name = L["Cast bar text"],
		get = get,
		set = set,
		handler = Config,
		args = {
			cast = {
				order = 0,
				type = "select",
				name = L["Cast text display"],
				desc = L["Style of display for cast bar text."],
				values = {["crtmax"] = L["Current / Max"], ["none"] = L["None"], ["crt"] = L["Current"], ["percent"] = L["Percent"], ["timeleft"] = L["Time left"]},
				arg = "castType",
			},

			font = Config:CreateFontString("castText"),
			uiobject = Config:CreateUIObject("castText"),
		}
	}

	options.args.castText.args.uiobject.args.width = nil
	options.args.castText.args.uiobject.args.height = nil

	-- Cast bar border
	options.args.castBorder = {
		type = "group",
		order = 3,
		name = L["Cast border"],
		get = get,
		set = set,
		handler = Config,
		args = {
			general = {
				order = 1,
				type = "group",
				inline = true,
				name = L["General UI"],
				args = {
					desc = {
						order = 0,
						type = "description",
						name = L["Basic ui object configuration, visability, size and positioning."],
					},
					hide = {
						order = 1,
						type = "toggle",
						name = L["Hide frame"],
						width = "double",
						arg = string.format("%s.uiobject.hide", "castBorder"),
					},
				},
			},
		}
	}
	

	-- Highlight texture
	options.args.highlightTexture = {
		type = "group",
		order = 3,
		name = L["Highlight texture"],
		get = get,
		set = set,
		handler = Config,
		args = {
			general = {
				order = 1,
				type = "group",
				inline = true,
				name = L["General UI"],
				args = {
					desc = {
						order = 0,
						type = "description",
						name = L["Basic ui object configuration, visability, size and positioning."],
					},
					hide = {
						order = 1,
						type = "toggle",
						name = L["Hide frame"],
						width = "double",
						arg = string.format("%s.uiobject.hide", "highlightTexture"),
					},
				},
			},
		}
	}

	-- DB Profiles
	options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(Nameplates.db)
	options.args.profile.order = 2
end

-- Slash commands
SLASH_NAMEPLATES1 = "/nameplates"
SLASH_NAMEPLATES2 = "/np"
SLASH_NAMEPLATES3 = "/nameplate"
SlashCmdList["NAMEPLATES"] = function(msg)
	if( not registered ) then
		if( not options ) then
			loadOptions()
		end

		config:RegisterOptionsTable("Nameplates", options)
		dialog:SetDefaultSize("Nameplates", 600, 500)
		registered = true
	end

	dialog:Open("Nameplates")
end

--[[
-- Add the general options + profile, we don't add spells/anchors because it doesn't support sub cats
local register = CreateFrame("Frame", nil, InterfaceOptionsFrame)
register:SetScript("OnShow", function(self)
	self:SetScript("OnShow", nil)
	loadOptions()

	config:RegisterOptionsTable("Nameplates-Bliz", {
		name = "Nameplates",
		type = "group",
		args = {
			help = {
				type = "description",
				name = string.format("Nameplates r%d is a basic nameplate modifier.", Nameplates.revision or 0),
			},
		},
	})
	
	dialog:SetDefaultSize("Nameplates-Bliz", 600, 400)
	dialog:AddToBlizOptions("Nameplates-Bliz", "Nameplates")
	
	config:RegisterOptionsTable("Nameplates-General", options.args.general)
	dialog:AddToBlizOptions("Nameplates-General", options.args.general.name, "Nameplates")

	config:RegisterOptionsTable("Nameplates-Profile", options.args.profile)
	dialog:AddToBlizOptions("Nameplates-Profile", options.args.profile.name, "Nameplates")
end)
]]
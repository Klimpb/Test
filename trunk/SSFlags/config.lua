if( not SSFlags ) then return end
SSFlags.Config = {}

local Config = SSFlags.Config
local L = SSFlagsLocals

local registered, options, config, dialog

-- GUI
local function set(info, value)
	SSFlags.db.profile[info[#(info) - 1]][info[(#info)]] = value
end

local function get(info)
	return SSFlags.db.profile[info[#(info) - 1]][info[(#info)]]
end

local function createFlagOptions(text, bg)
	return {
		order = 1,
		type = "group",
		name = text,
		get = get,
		set = set,
		args = {
			enabled = {
				order = 1,
				type = "toggle",
				name = L["Show flag carrier"],
				width = "full",
			},
			respawn = {
				order = 2,
				type = "toggle",
				name = L["Show flag respawn time on overlay"],
				width = "full",
			},
			capture = {
				order = 3,
				type = "toggle",
				name = L["Show flag capture times on overlay"],
				width = "full",
			},
			color = {
				order = 4,
				type = "toggle",
				name = L["Color carrier name by class"],
				width = "full",
			},
			health = {
				order = 5,
				type = "toggle",
				name = L["Show carrier health when available"],
				width = "full",
			},
			macro = {
				order = 6,
				type = "input",
				multiline = true,
				name = L["Text to execute when clicking the carrier button"],
				width = "full",
			},
		},
	}
end

function Config:LoadOptions()
	-- If options weren't loaded yet, then do so now
	if( not SSPVP3.options ) then
		SSPVP3.options = {
			type = "group",
			name = "SSPVP3",
			
			args = {}
		}

		config:RegisterOptionsTable("SSPVP3", SSPVP3.options)
		dialog:SetDefaultSize("SSPVP3", 625, 575)

		-- Load other SSPVP3 modules configurations
		for field, data in pairs(SSPVP3) do
			if( type(data) == "table" and data.Config and data.Config ~= Config ) then
				data.Config:LoadOptions()
			end
		end
	end
	
	-- Load overlay configuration
	if( not SSPVP3.options.args.overlay ) then
		SSPVP3.options.args.overlay = LibStub("SSOverlay-1.0"):LoadOptions()
	end
	
	-- Already loaded
	if( SSPVP3.options.args.flags ) then
		return
	end
	
	SSPVP3.options.args.flags = {
		type = "group",
		order = 1,
		name = L["Flags"],
		get = get,
		set = set,
		args = {
			wsg = createFlagOptions(L["Warsong Gulch"], "wsg"),
			eots = createFlagOptions(L["Eye of the Storm"], "eots"),
		},
	}
end

function Config:Open()
	if( not config and not dialog ) then
		config = LibStub("AceConfig-3.0")
		dialog = LibStub("AceConfigDialog-3.0")

		Config:LoadOptions()
	end

	dialog:Open("SSPVP3")
end

SLASH_SSFLAGS1 = "/ssflags"
SlashCmdList["SSFLAGS"] = function()
	Config:Open()
end

-- SSPVP3 Slash command
if( not SLASH_SSPVP1 ) then
	SLASH_SSPVP1 = "/sspvp3"
	
	-- Mostly this is here while I develop this, I'll remove it eventually so it always registers it
	if( not SLASH_ACECONSOLE_SSPVP1 ) then
		SLASH_SSPVP2 = "/sspvp"
	end
	
	SlashCmdList["SSPVP"] = function()
		DEFAULT_CHAT_FRAME:AddMessage(L["SSPVP3 module slash commands"])
		
		for _, help in pairs(SSPVP3.Slash) do
			DEFAULT_CHAT_FRAME:AddMessage(help)
		end
	end
end

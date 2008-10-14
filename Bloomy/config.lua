if( not Bloomy or Bloomy.disabled ) then return end

local Config = Bloomy:NewModule("Config")
local L = BloomyLocals

local SML, registered, options, config, dialog

function Config:OnInitialize()
	config = LibStub("AceConfig-3.0")
	dialog = LibStub("AceConfigDialog-3.0")
end

-- GUI
local function set(info, value)
	local arg1, arg2, arg3 = string.split(".", info.arg)
	if( tonumber(arg2) ) then arg2 = tonumber(arg2) end
	
	if( arg2 and arg3 ) then
		Bloomy.db.profile[arg1][arg2][arg3] = value
	elseif( arg2 ) then
		Bloomy.db.profile[arg1][arg2] = value
	else
		Bloomy.db.profile[arg1] = value
	end
	
	Bloomy:Reload()
end

local function get(info)
	local arg1, arg2, arg3 = string.split(".", info.arg)
	if( tonumber(arg2) ) then arg2 = tonumber(arg2) end
	
	if( arg2 and arg3 ) then
		return Bloomy.db.profile[arg1][arg2][arg3]
	elseif( arg2 ) then
		return Bloomy.db.profile[arg1][arg2]
	else
		return Bloomy.db.profile[arg1]
	end
end

local function setNumber(info, value)
	set(info, tonumber(value))
end

local function setMulti(info, value, state)
	local arg1, arg2, arg3 = string.split(".", info.arg)
	if( tonumber(arg2) ) then arg2 = tonumber(arg2) end

	if( arg2 and arg3 ) then
		Bloomy.db.profile[arg1][arg2][arg3][value] = state
	elseif( arg2 ) then
		Bloomy.db.profile[arg1][arg2][value] = state
	else
		Bloomy.db.profile[arg1][value] = state
	end

	Bloomy:Reload()
end

local function getMulti(info, value)
	local arg1, arg2, arg3 = string.split(".", info.arg)
	if( tonumber(arg2) ) then arg2 = tonumber(arg2) end
	
	if( arg2 and arg3 ) then
		return Bloomy.db.profile[arg1][arg2][arg3][value]
	elseif( arg2 ) then
		return Bloomy.db.profile[arg1][arg2][value]
	else
		return Bloomy.db.profile[arg1][value]
	end
end

-- General options
local enabledIn = {["none"] = L["Everywhere else"], ["pvp"] = L["Battlegrounds"], ["arena"] = L["Arenas"], ["raid"] = L["Raid instances"], ["party"] = L["Party instances"]}

local function loadOptions()
	options = {}
	options.type = "group"
	options.name = "Bloomy"
	
	options.args = {}
	options.args.general = {
		type = "group",
		order = 1,
		name = L["General"],
		get = get,
		set = set,
		handler = Config,
		args = {
			name = {
				order = 1,
				type = "toggle",
				name = L["Show target names in macros"],
				desc = L["Edits the macros name to reflect the current target that hots will be casted on."],
				width = "full",
				arg = "showName"
			},
			--[[
			unitid = {
				order = 1,
				type = "toggle",
				name = L["Use unitids to cast on instead of player names"],
				desc = L["Sometimes you can run into issues with casting by player name instead of unitid, like Hunter pets with the same name. If you're noticing problems enable this."],
				width = "full",
				arg = "useUnits"
			},
			]]
			scale = {
				order = 2,
				type = "range",
				name = L["Display scale"],
				desc = L["How big the hot timer frame should be."],
				min = 0, max = 2, step = 0.1,
				set = setNumber,
				arg = "scale",
			},
			enabledIn = {
				order = 3,
				type = "multiselect",
				name = L["Enable Bloomy inside"],
				desc = L["Allows you to set what scenario's Bloomy should be enabled inside."],
				values = enabledIn,
				set = setMulti,
				get = getMulti,
				width = "full",
				arg = "inside"
			},
		},
	}
	
	-- DB Profiles
	options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(Bloomy.db)
	options.args.profile.order = 2
end

-- Slash commands
SLASH_BLOOMY1 = "/bloomy"
SlashCmdList["BLOOMY"] = function(msg)
	local cmd, id, name = string.split(" ", msg or "")
	cmd = string.lower(cmd or "")
	
	local self = Bloomy
	if( cmd == "add" and id and name ) then
		if( not self.db.profile.macros[id] ) then
			self.db.profile.macros[id] = {}
		end
		
		for _, playerName in pairs(self.db.profile.macros[id]) do
			if( string.lower(playerName) == string.lower(name) ) then
				self:Print(string.format(L["The player \"%s\" is already added to id \"%s\"."], name, id))
				return
			end
		end
		
		table.insert(self.db.profile.macros[id], name)
		
		self:UpdateMacros()
		self:UpdateFrame()
		self:Print(string.format(L["Added \"%s\" to Bloomy ID \"%s\" order #%d."], name, id, #(self.db.profile.macros[id])))
	
	elseif( cmd == "remove" and id and name ) then
		if( not self.db.profile.macros[id] ) then
			Bloomy:Print(string.format(L["No Bloomy macro for id \"%s\" found."], id))
			return
		end
		
		for i=#(self.db.profile.macros[id]), 1, -1 do
			if( string.lower(self.db.profile.macros[id][i]) == string.lower(name) ) then
				table.remove(self.db.profile.macros[id], i)
			end
		end
		
		self:UpdateMacros()
		self:UpdateFrame()
		self:Print(string.format(L["Removed \"%s\" from Bloomy ID \"%s\""], name, id))
	
	elseif( cmd == "list" and id ) then
		if( not self.db.profile.macros[id] ) then
			Bloomy:Print(string.format(L["No Bloomy macro for id \"%s\" found."], id))
			return
		end
		
		self:Print(string.format("[%s] %s", id, table.concat(self.db.profile.macros[id], " -> ")))
	
	elseif( cmd == "reset" ) then
		for _, info in pairs(self.db.profile.macros) do
			for k in pairs(info) do
				info[k] = nil
			end
		end
		
		self:UpdateMacros()
		self:UpdateFrame()
		self:Print(L["Reset all Bloomy macros."])
		
	elseif( cmd == "toggle" ) then
		self:UpdateMacros()
		self:CreateFrame()
		self:UpdateFrame()
		
		if( self.frame:IsVisible() ) then
			self.frame:Hide()
		elseif( self.frame.rows[1].target ) then
			self.frame:Show()
		end
	
	elseif( cmd == "ui" ) then
		if( not registered ) then
			if( not options ) then
				loadOptions()
			end
			
			config:RegisterOptionsTable("Bloomy", options)
			dialog:SetDefaultSize("Bloomy", 625, 500)
			registered = true
		end

		dialog:Open("Bloomy")
	
	elseif( cmd == "help" ) then
		DEFAULT_CHAT_FRAME:AddMessage(L["In order for a macro to be recognized by Bloomy, it has to have an identifier in it."])
		DEFAULT_CHAT_FRAME:AddMessage(L["Add #bloomy <id> <spell name> to the macro and it'll automatically be edited with the person to cast the passed spell on."])
	else
		self:Print(L["Slash commands"])
		DEFAULT_CHAT_FRAME:AddMessage(L["/bloomy toggle - Toggles the Bloomy timer frame"])
		DEFAULT_CHAT_FRAME:AddMessage(L["/bloomy ui - Toggles the configuration"])
		DEFAULT_CHAT_FRAME:AddMessage(L["/bloomy add <id> <name> - Adds a group member to the passed id which will have the duration of the HoT left shown in the action button."])
		DEFAULT_CHAT_FRAME:AddMessage(L["/bloomy remove <id> <name> - Removes the given group member from the passed id and hots will no longer be shown for them in the action button."])
		DEFAULT_CHAT_FRAME:AddMessage(L["/bloomy list <id> - Lists the people who are added to this id including the order."])
		DEFAULT_CHAT_FRAME:AddMessage(L["/bloomy reset - Removed all assigned group members from Bloomy macros."])
		DEFAULT_CHAT_FRAME:AddMessage(L["/bloomy help - Shows information on how to create a Bloomy macro."])
	end
end

-- Add the general options + profile, we don't add spells/anchors because it doesn't support sub cats
local register = CreateFrame("Frame", nil, InterfaceOptionsFrame)
register:SetScript("OnShow", function(self)
	--[[
	self:SetScript("OnShow", nil)
	loadOptions()

	config:RegisterOptionsTable("Bloomy-Bliz", {
		name = "Bloomy",
		type = "group",
		args = {
			help = {
				type = "description",
				name = string.format("Bloomy r%d is a HoT tracking and rolling mod for Druids.", Bloomy.revision or 0),
			},
		},
	})
	
	dialog:SetDefaultSize("Bloomy-Bliz", 600, 400)
	dialog:AddToBlizOptions("Bloomy-Bliz", "Bloomy")

	config:RegisterOptionsTable("Bloomy-Profile", options.args.profile)
	dialog:AddToBlizOptions("Bloomy-Profile", options.args.profile.name, "Bloomy")

	config:RegisterOptionsTable("Bloomy-General", options.args.general)
	dialog:AddToBlizOptions("Bloomy-General", options.args.general.name, "Bloomy")
	]]
end)
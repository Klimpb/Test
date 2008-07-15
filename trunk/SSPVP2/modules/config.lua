if( not SSPVP ) then return end

local L = SSPVPLocals

local function get(info)
	local cat = info[#(info) - 1]
	local DBVar
	
	if( SSPVP.modules[cat] ) then
		DBVar = SSPVP.modules[cat].db.profile	
	else
		DBVar = SSPVP.db.profile[cat]
	end
	
	local value = DBVar[info[#(info)]]
	if( type(value) == "number" ) then
		return tostring(value)
	end
	
	return value
end

local function set(info, value)
	ChatFrame1:AddMessage(string.format("set [%d] [%s] [%s] [%s]", #(info), tostring(info[#(info)]), tostring(info[#(info) - 1]), tostring(info[#(info) - 2])))

	local cat = info[#(info) - 1]
	local DBVar = SSPVP.modules[cat] or SSPVP

	--DBVar.db.profile.config[cat][info[#(info)]]
end

local function disabled(info)
	
end

local function loadOptions()
	options = {
		name = "SSPVP",
		type = "group",
		get = get,
		set = set,
		args = {
--[[
		{ order = 1, group = L["General"], text = L["Show team summary after rated arena ends"], help = L["Shows team names, points change and the new ratings after the arena ends."], type = "check", var = {"Arena", "score"}},
		{ order = 2, group = L["General"], text = L["Show personal rating change after arena ends"], help = L["Shows how much personal rating you gain/lost, will only show up if it's no the same amount of points as your actual team got."], type = "check", var = {"Arena", "personal"}},
		{ order = 3, group = L["General"], text = L["Timer channel"], help = L["Channel to output to when you send timers out from the overlay."], type = "dropdown", list = {{"BATTLEGROUND", L["Battleground"]}, {"RAID", L["Raid"]}, {"PARTY", L["Party"]}},  var = {"general", "channel"}},
		{ order = 4, group = L["General"], text = L["Sound file"], help = L["Sound file to play when a queue is ready, file must be inside Interface/AddOns/SSPVP before you started the game."], type = "input", width = 150, var = {"general", "sound"}}, 
		{ order = 5, group = L["General"], text = L["Play"], type = "button",  onSet = "PlaySound"},
]]

			general = {
				order = 2,
				type = "group",
				name = "Data retention",
				desc = "Allows you to set how long data should be saved before being removed.",
				args = {
					enableMax = {
						order = 1,
						type = "toggle",
						name = "Enable maximum records",
						desc = "Stores what enemies cast during an arena match, then attempts to guess their talents based on the spells used, not 100% accurate but it gives a rough idea.",
						width = "full",
					},
					maxRecords = {
						order = 2,
						type = "range",
						name = "Maximum saved records",
						desc = "How many records to save per a bracket, for example if you set it to 10 then you'll only keep the last 10 matches for each bracket, older records are overwritten by newer ones.",
						min = 1, max = 1000, step = 1,
						set = setNumber,
						disabled = disabled,
						width = "full",
					},
					enableWeek = {
						order = 3,
						type = "toggle",
						name = "Enable week records",
						width = "full",
					},
					maxWeeks = {
						order = 4,
						type = "range",
						name = "How many weeks to save records",
						desc = string.format("Weeks that data should be saved before it's deleted, this is weeks from the day the record was saved.\nTime: %s", date("%c")),
						min = 1, max = 52, step = 1,
						set = setNumber,
						disabled = disabled,
						width = "full",
					},
				},
			},
		},
	}
end

-- Register the actual options and fun stuff
local config = LibStub("AceConfig-3.0")
local dialog = LibStub("AceConfigDialog-3.0")

-- Slash command
SLASH_SSPVP1 = "/sspvp"
SlashCmdList["SSPVP"] = function(msg)
	msg = string.lower(msg or "")

	local self = SSPVP
	if( msg == "suspend" ) then
		if( self.suspended ) then
			self:DisableSuspense()
			self:CancelTimer("DisableSuspense", true)
		else
			self.suspended = true
			self:Print(L["Auto join and leave has been suspended for the next 5 minutes, or until you log off."])
			self:ScheduleTimer("DisableSuspense", 300)
		end

		-- Update queue overlay if required
		self:UPDATE_BATTLEFIELD_STATUS()
	elseif( msg == "ui" ) then
		if( not registered ) then
			if( not options ) then
				loadOptions()
			end

			config:RegisterOptionsTable("SSPVP", options)
			dialog:SetDefaultSize("SSPVP", 625, 500)
			registered = true
		end

		dialog:Open("SSPVP")
	else
		DEFAULT_CHAT_FRAME:AddMessage(L["SSPVP slash commands"])
		DEFAULT_CHAT_FRAME:AddMessage(L[" - suspend - Suspends auto join and leave for 5 minutes, or until you log off."])
		DEFAULT_CHAT_FRAME:AddMessage(L[" - ui - Opens the OptionHouse configuration for SSPVP."])
		DEFAULT_CHAT_FRAME:AddMessage(L[" - Other slash commands"])
		DEFAULT_CHAT_FRAME:AddMessage(L[" - /arena - Easy Arena calculations and conversions"])
	end
end

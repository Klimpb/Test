local Window = SSPVP:NewModule("Window", "AceEvent-3.0")
local L = SSPVPLocals

local entryDialog
local lastStatus = {}

function Window:OnInitialize()
	self.defaults = {
		profile = {
			enabled = false,
			remind = false,
		},
	}
	
	self.db = SSPVP.db:RegisterNamespace("window", self.defaults)
	

	if( self.db.profile.enabled ) then
		-- We nil this out because it's the cleanest way to prevent it from ever showing
		-- over hooking Blizzard functions or calling StaticPopup_Hide when it's shown
		entryDialog = StaticPopupDialogs["CONFIRM_BATTLEFIELD_ENTRY"]
		StaticPopupDialogs["CONFIRM_BATTLEFIELD_ENTRY"] = nil
	end
end

function Window:OnEnable()
	if( self.db.profile.enabled ) then
		self:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
	end
end

function Window:Reload()
	self:UnregisterAllEvents()
	self:OnEnable()
	
	-- Restore the original entry
	if( self.db.profile.enabled ) then
		if( StaticPopupDialogs["CONFIRM_BATTLEFIELD_ENTRY"] and not entryDialog ) then
			entryDialog = StaticPopupDialogs["CONFIRM_BATTLEFIELD_ENTRY"]
			StaticPopupDialogs["CONFIRM_BATTLEFIELD_ENTRY"] = nil
		end
	else
		if( not StaticPopupDialogs["CONFIRM_BATTLEFIELD_ENTRY"] and entryDialog ) then
			StaticPopupDialogs["CONFIRM_BATTLEFIELD_ENTRY"] = entryDialog
			entryDialog = nil
		end
	end
end

function Window:UPDATE_BATTLEFIELD_STATUS()
	for i=1, MAX_BATTLEFIELD_QUEUES do
		local status, map, instanceID, _, _, teamSize, isRegistered = GetBattlefieldStatus(i)
		
		if( status ~= lastStatus[i] ) then
			if( status == "confirm" ) then
				--StaticPopup_Show("
			end
		end
		
		lastStatus[i] = status	
	end
end

StaticPopupDialogs["CONFIRM_NEW_BFENTRY"] = {
	text = L["You can now enter %s and have %s left."],
	button1 = ENTER_BATTLE,
	button2 = HIDE,
	OnAccept = function(data)
		AcceptBattlefieldPort(data, 1)
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
	multiple = 1
};
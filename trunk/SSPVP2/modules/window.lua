local Window = SSPVP:NewModule("Window", "AceEvent-3.0")
local L = SSPVPLocals
local entryDialog

function Window:OnInitialize()
	self.defaults = {
		profile = {
			enabled = false
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
local Module = PerfectRaid:NewModule("PerfectRaid-Visibility")
local instanceType

function Module:Initialize()
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("UPDATE_BATTLEFIELD_STATUS", "ZONE_CHANGED_NEW_AREA")
end

function Module:ZONE_CHANGED_NEW_AREA()
	local type = select(2, IsInInstance())
	local updateRF
	if( ( type == "arena" or type == "pvp" ) and type ~= instanceType ) then
		for idx, entry in pairs(PerfectRaid.db.profile.headers) do
			if( not entry.disabled ) then
				entry.wasDisabled = entry.disabled
				entry.disabled = true
				
				updateRF = true
			end
		end
	elseif( type ~= "arena" and type ~= "pvp" ) then
		for idx, entry in pairs(PerfectRaid.db.profile.headers) do
			if( entry.disabled and entry.wasDisabled ~= nil ) then
				entry.disabled = entry.wasDisabled
				entry.wasDisabled = nil
				
				updateRF = true
			end
		end
	end
		
	if( updateRF ) then
		PerfectRaid:UpdateRaidFrames()
	end
	
	instanceType = type
end
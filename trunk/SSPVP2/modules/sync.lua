PVPSync = SSPVP:NewModule("Sync", "AceEvent-3.0")

function PVPSync:OnEnable()
	self:RegisterEvent("CHAT_MSG_ADDON")
end

function PVPSync:OnDisable()
	self:UnregisterAllEvents()
end

function PVPSync:SendMessage(msg, type)
	SendAddonMessage("SSPVP", msg, type or "BATTLEGROUND")
end

function PVPSync:CHAT_MSG_ADDON(event, prefix, msg, type, author)
	if( prefix == "SSPVP" ) then
		local dataType, data = string.match(msg, "([^:]+)%:(.+)")
		if( not dataType ) then
			dataType = msg
		end
		
		if( dataType and not data ) then
			self:SendMessage(dataType .. "_REQ")
		else
			self:SendMessage(dataType .. "_DATA", string.split(",", data))
		end
	end
end
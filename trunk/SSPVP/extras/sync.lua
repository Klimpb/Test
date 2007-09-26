PVPSync = SSPVP:NewModule("SSPVP-Sync")

local version

function PVPSync:Enable()
	self:RegisterEvent("CHAT_MSG_ADDON")
	version = tonumber(string.match(GetAddOnMetadata("SSPVP", "Version"), "(%d+)") or 1)
end

function PVPSync:SendMessage(msg, type)
	SendAddonMessage("SSPVP", msg, type or "BATTLEGROUND")
end

function PVPSync:CHAT_MSG_ADDON(event, prefix, msg, type, author)
	if( prefix == "SSPVP" or prefix == "SSAV" ) then
		local dataType, data = string.match(msg, "([^:]+)%:(.+)")
		if( not dataType ) then
			dataType = msg
		end
		
		if( dataType == "PING" ) then
			self:SendMessage("PONG:" .. version, type)
		elseif( dataType and not data ) then
			self:TriggerMessage("SS_" .. dataType .. "_REQ")
		else
			self:TriggerMessage("SS_" .. dataType .. "_DATA", string.split(",", data))
		end
	end
end
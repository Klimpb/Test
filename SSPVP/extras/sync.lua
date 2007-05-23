PVPSync = SSPVP:NewModule( "SSPVP-Sync" );

local version = "1.2";

function PVPSync:Enable()
	self:RegisterEvent( "CHAT_MSG_ADDON" );
end

function PVPSync:SendMessage( msg, type )
	SendAddonMessage( "SSPVP", msg, type or "BATTLEGROUND" );
end

function PVPSync:TestPing( type )
	SendAddonMessage( "SSPVP", "PING", type or "BATTLEGROUND" );
	
	self:UnregisterMessage( "SS_SYNC_PONG" );
	self:RegisterMessage( "SS_SYNC_PONG", function( event, version )
		Debug( "VERSION [" .. arg4 .. "] [" .. version .. "]" );
	end );
end

function PVPSync:CHAT_MSG_ADDON( event, prefix, msg, type, author )
	if( prefix == "SSPVP" or prefix == "SSAV" ) then
		--SSPVP:DebugF( 3, "[%s/%s] %s", author, type, msg );
		
		local _, _, dataType, data = string.find( msg, "([^:]+)%:(.+)" );
		if( not dataType ) then
			dataType = msg;
		end
		
		if( dataType == "PING" ) then
			self:SendMessage( "PONG:" .. version, type );
		elseif( dataType == "PONG" ) then
			self:TriggerMessage( "SS_SYNC_PONG", data );
		elseif( dataType and not data ) then
			self:TriggerMessage( "SS_" .. dataType .. "_REQ" );
		else
			self:TriggerMessage( "SS_" .. dataType .. "_DATA", string.split( ",", data ) );
		end
	end
end
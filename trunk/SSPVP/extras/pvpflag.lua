local PVPFlag = SSPVP:NewModule( "SSPVP-Flag" );

local L = SSPVPLocals;

function PVPFlag:EnableModule()
	self:RegisterEvent( "UNIT_FACTION" );
	self:RegisterEvent( "ZONE_CHANGED_NEW_AREA" );
end

function PVPFlag:DisableModule()
	self:UnregisterAllEvents();
end
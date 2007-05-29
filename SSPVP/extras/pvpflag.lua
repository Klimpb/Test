--[[
local PVPFlag = SSPVP:NewModule( "SSPVP-Flag" );

local L = SSPVPLocals;

local oldZone = "";
local zoneType;

function PVPFlag:Initialize()
	hooksecurefunc( "TogglePVP", self.TogglePVP );
	hooksecurefunc( "SetPVP", self.SetPVP );
end

function PVPFlag:EnableModule()
	self:RegisterEvent( "UNIT_FACTION" );
	self:RegisterEvent( "ZONE_CHANGED_NEW_AREA" );
	
	self:ZONE_CHANGED_NEW_AREA();
end

function PVPFlag:DisableModule()
	self:UnregisterAllEvents();
end

function PVPFlag:UpdateTimer()
	local timeLeft = SSPVP.db.profile.flaggedOn - time();
	
	if( timeLeft > 0 ) then
		SSOverlay:UpdateTimer( "general", L["PVP Flag: %s"], timeLeft );		
	else
		SSOverlay:RemoveRow( "timer", "general", L["PVP Flag: %s"] );	
	end
end

-- flag: 1 now flagged, nil unflagging
-- desired: 0 flagging, 1 unflagging
function PVPFlag.SetPVP( flag )
	-- Flagged perm
	if( flag == 1 and GetPVPDesired() == 0 ) then
		SSPVP.db.profile.flaggedOn = 0;
	
	-- Unflagging 5m
	elseif( ( not flag or flag == 0 ) and GetPVPDesired() == 1 ) then
		SSPVP.db.profile.flaggedOn = time() + 300;
	end
	
	PVPFlag:UpdateTimer();
end

-- 0 now flagged perm
-- 1 unflagging in 5m
function PVPFlag:TogglePVP()
	if( GetPVPDesired() == 0 ) then
		SSPVP.db.profile.flaggedOn = 0;
	elseif( GetPVPDesired() == 1 ) then
		SSPVP.db.profile.flaggedOn = time() + 300;
	end
	
	PVPFlag:UpdateTimer();
end

function PVPFlag:UNIT_FACTION( event, unit )
	if( unit == "player" and zoneType ~= "hostile" and zoneType ~= "contested" ) then
		if( not UnitIsPVPFreeForAll( "player" ) and UnitIsPVP( "player" ) and GetPVPDesired() == 0 ) then
			SSPVP.db.profile.flaggedOn = time() + 300;
		end
		
		self:UpdateTimer();
	end
end

function PVPFlag:ZONE_CHANGED_NEW_AREA()
	local oldZone = zoneType;
	zoneType = GetZonePVPInfo() or "";
		
	-- Show the timer if we aren't being forced to PvP flag
	if( zoneType ~= "hostile" and zoneType ~= "contested" and not UnitIsPVPFreeForAll( "player" ) and UnitIsPVP( "player" ) and GetPVPDesired() == 0 ) then
		-- We came from a zone that forces us to be flagged to one that doesn't
		if( oldZone == "contested" or oldZone == "hostile" ) then
			SSPVP.db.profile.flaggedOn = time() + 300;
		end
	else
		SSPVP.db.profile.flaggedOn = 0;
	end
	
	self:UpdateTimer();
end
]]
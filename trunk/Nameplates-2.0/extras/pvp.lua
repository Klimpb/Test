NPClass = Nameplates:NewModule( "Nameplates-Class" );

local BattlefieldID = -1;

function NPClass:EnableModule()
	self:RegisterEvent( "PLAYER_TARGET_CHANGED" );
	self:RegisterEvent( "UPDATE_MOUSEOVER_UNIT" );
	self:RegisterEvent( "UPDATE_BATTLEFIELD_SCORE" );
	self:RegisterEvent( "UPDATE_BATTLEFIELD_STATUS" );
	
	if( not NPPlayers ) then
		NPPlayers = {};
	end
end

function NPClass:DisableModule()
	self:UnregisterAllEvents();
end

function NPClass:ScanUnit( unit )
	if( UnitIsPlayer( unit ) ) then
		local name, server = UnitName( unit );
		server = server or GetRealmName();
		
		NPPlayers[ name .. "-" .. server ] = select( 2, UnitClass( unit ) );
	end
end

-- We attempt to make an educated guess regarding classes
-- because we can't get server name
function NPClass:GetClassByName( name )
	if( BattlefieldID == -1 ) then
		return NPPlayers[ name .. "-" .. GetRealmName() ];
	else
		local searchName;
		for i=1, GetNumBattlefieldScores() do
			searchName = GetBattlefieldScore( i );
			if( string.find( searchName, "^" .. name ) ) then
				return NPPlayers[ searchName ];			
			end
		end
	end
	
	return nil;
end

function NPClass:UPDATE_BATTLEFIELD_SCORE()
	local name, class;
	for i=1, GetNumBattlefieldScores() do
		name, _, _, _, _, _, _, _, _, class = GetBattlefieldScore( i );
		if( not string.find( name, "-" ) ) then
			name = name .. "-" .. GetRealmName();
		end

		NPPlayers[ name ] = class;
	end
end

function NPClass:PLAYER_TARGET_CHANGED()
	self:ScanUnit( "target" );
end

function NPClass:UPDATE_MOUSEOVER_UNIT()
	self:ScanUnit( "mouseover" );
end

function NPClass:UPDATE_BATTLEFIELD_STATUS()
	local status;
	for i=1, MAX_BATTLEFIELD_QUEUES do
		status = GetBattlefieldStatus( i );
		
		if( status == "active" and BattlefieldID ~= i ) then
			BattlefieldID = i;
			RequestBattlefieldScoreData();
			
		elseif( status ~= "active" and BattlefieldID == i ) then
			BattlefieldID = -1;
		end
	end
end
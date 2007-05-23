local AB = SSPVP:NewModule( "SSPVP-AB" );
AB.activeIn = "ab";

local L = SSPVPLocals;
local baseInfo = { [0] = 0, [1] = 0.83, [2] = 1.0, [3] = 1.66, [4] = 3.3, [5] = 30.0 };

local Alliance = {};
local Horde = {};
local lowest;

local timers = {};
local dataSent = {};

function AB:EnableModule()
	self:RegisterEvent( "UPDATE_WORLD_STATES", "UpdateOverlay" );
	self:RegisterEvent( "CHAT_MSG_BG_SYSTEM_HORDE", "HordeMessage" );
	self:RegisterEvent( "CHAT_MSG_BG_SYSTEM_ALLIANCE", "AllianceMessage" );

	self:RegisterMessage( "SS_ABTIMERS_REQ", "ResponseDelay" );
	self:RegisterMessage( "SS_ABTIMERS_DATA", "ParseSync" );
	
	SSOverlay:AddCategory( "ab", L["Timers"], nil, AB, "PrintAllTimers" );
	SSOverlay:AddCategory( "abinfo", L["Battlefield Info"], nil, AB, "PrintMatchInfo" );

	PVPSync:SendMessage( "ABTIMERS" );
end


function AB:DisableModule()
	self:UnregisterAllMessages();
	self:UnregisterAllEvents();

	timers = {};
	dataSent = {};
	
	SSOverlay:RemoveCategory( "abinfo" );
	SSOverlay:RemoveCategory( "ab" );
end

function AB:Reload()
	if( not SSPVP.db.profile.timers ) then
		SSOverlay:RemoveCategory( "ab" );
	elseif( SSPVP:IsPlayerIn( "ab" ) ) then
		PVPSync:SendMessage( "ABTIMERS" );
	end
	
	if( not SSPVP.db.profile.overlay ) then
		SSOverlay:RemoveCategory( "abinfo" );
	end
end

function AB:PrintMatchInfo()
	SSPVP:ChannelMessage( string.format( L["Time Left: %s / Bases to win: %d (A:%d/H:%d)"], SSOverlay:FormatTime( lowest, "minsec" ), Alliance.basesWin, Alliance.baseScore, Horde.baseScore ) );
	SSPVP:ChannelMessage( string.format( L["Final Score (Alliance): %d / Final Score (Horde): %d"], Alliance.final, Horde.final ) );
end

function AB:PrintAllTimers()
	for name, timer in pairs( timers ) do
		SSPVP:PrintTimer( name, timer.endTime, timer.faction );
	end
end

function AB:SendTimers()
	local send = {};
	local currentTime = GetTime();
	local faction, seconds;

	for name, timer in pairs( timers ) do
		-- We've already seen the data sent, ignore it.
		if( not dataSent[ name ] ) then
			seconds = math.floor( timer.endTime - currentTime );
			if( seconds > 0 ) then
				table.insert( send, name .. ":" .. timer.faction .. ":" .. seconds );
			end
		end
	end
	
	timers = {};
	
	if( #( send ) > 0 ) then
		PVPSync:SendMessage( "ABTIMERS:TIME:T:" .. GetTime() .. "," .. table.concat( send, "," ), "GUILD" );
	end
end

function AB:ResponseDelay()
	if( not SSPVP.db.profile.ab.timers ) then
		return;
	end

	dataSent = {};
	SSPVP:RegisterTimer( self, "SendTimers", math.random( 5 ) );
end

function AB:ParseSync( event, ... )
	if( not SSPVP.db.profile.ab.timers ) then
		return;
	end

	local name, faction, seconds;
	
	for i=1, select( "#", ... ) do
		name, faction, seconds = string.split( ":", ( select( i, ... ) ) );
		seconds = tonumber( seconds );
		
		if( i > 1 ) then
			dataSent[ name ] = true;

			-- Not an active timer, fine to remove it.
			if( not timers[ name ] ) then
				timers[ name ] = { faction = faction, endTime = GetTime() + seconds }
			
				if( GetLocale() == "enUS" ) then
					name = string.upper( string.sub( name, 0, 1 ) ) .. string.sub( name, 2 );
				end
				
				SSOverlay:UpdateTimer( "ab", name .. ": %s", seconds, SSOverlay:GetFactionColor( faction ) );
				SSOverlay:AddOnClick( "timer", "ab", name .. ": %s", SSPVP, "PrintTimer", name, GetTime() + seconds, faction );
			end
		end
	end
end

function AB:HordeMessage( event, msg )
	self:ParseMessage( msg, "Horde" );
end

function AB:AllianceMessage( event, msg )
	self:ParseMessage( msg, "Alliance" );
end

function AB:ParseMessage( msg, faction )
	if( not SSPVP.db.profile.ab.timers ) then
		return;
	end
	
	if( string.find( msg, L["has assaulted the ([^!]+)"] ) ) then
		local _, _, name = string.find( msg, L["has assaulted the ([^!]+)"] );

		timers[ name ] = { faction = faction, endTime = GetTime() + 62 }
		if( GetLocale() == "enUS" ) then
			name = string.upper( string.sub( name, 0, 1 ) ) .. string.sub( name, 2 );
		end
		
		SSOverlay:UpdateTimer( "ab", name .. ": %s", 62, SSOverlay:GetFactionColor( faction ) );
		SSOverlay:AddOnClick( "timer", "ab", name .. ": %s", SSPVP, "PrintTimer", name, GetTime() + 62, faction );
		
	elseif( string.find( msg, L["(.+) claims the ([^!]+)"] ) ) then
		local _, _, _, name = string.find( msg, L["(.+) claims the ([^!]+)"] );

		timers[ name ] = { faction = faction, endTime = GetTime() + 62 }
		if( GetLocale() == "enUS" ) then
			name = string.upper( string.sub( name, 0, 1 ) ) .. string.sub( name, 2 );
		end
		
		SSOverlay:UpdateTimer( "ab", name .. ": %s", 62, SSOverlay:GetFactionColor( faction ) );
		SSOverlay:AddOnClick( "timer", "ab", name .. ": %s", SSPVP, "PrintTimer", name, GetTime() + 62, faction );
		
	elseif( string.find( msg, L["has taken the ([^!]+)"] ) ) then
		local _, _, name = string.find( msg, L["has taken the ([^!]+)"] );
	
		SSOverlay:RemoveRow( "timer", "ab", name .. ": %s" );
		timers[ name ] = nil;
		
	elseif( string.find( msg, L["has defended the ([^!]+)"] ) ) then
		local _, _, name = string.find( msg, L["has defended the ([^!]+)"] );
		
		SSOverlay:RemoveRow( "timer", "ab", name .. ": %s" );
		timers[ name ] = nil;
	end
end

function AB:UpdateOverlay()
	if( not SSPVP.db.profile.ab.overlay ) then
		SSOverlay:RemoveCategory( "abinfo" );
		return;
	end
	
	SSOverlay:RemoveCategory( "abinfo" );
	
	local bases, points, enemy, friendly;
	local _, _, allianceText = GetWorldStateUIInfo( 1 );
	local _, _, hordeText = GetWorldStateUIInfo( 2 );
	
	_, _, bases, points = string.find( allianceText, L["Bases: ([0-9]+)  Resources: ([0-9]+)/2000"] );
	Alliance.bases = tonumber( bases );
	Alliance.points = tonumber( points );
	Alliance.left = 2000 - points;

	Alliance.time = Alliance.left / baseInfo[ Alliance.bases ];
	Alliance.basesWin = 0;
	
	_, _, bases, points = string.find( hordeText, L["Bases: ([0-9]+)  Resources: ([0-9]+)/2000"] );
	Horde.bases = tonumber( bases );
	Horde.points = tonumber( points );
	Horde.left = 2000 - points;
	Horde.time = Horde.left / baseInfo[ Horde.bases ];
	Horde.basesWin = 0;
	
	if( Horde.points == 0 and Alliance.points == 0 ) then
		return;
	end
	
	if( Alliance.time < Horde.time ) then
		lowest = Alliance.time;
	else
		lowest = Horde.time;
	end
	
	if( SSPVP.db.profile.ab.timeLeft ) then
		SSOverlay:UpdateTimer( "abinfo", L["Time Left: %s"], lowest, SSOverlay:GetFactionColor() );
	end
	
	Alliance.final = floor( ( Alliance.points + ( lowest * baseInfo[ Alliance.bases ] + 0.5 ) ) / 10 ) * 10;
	Horde.final = floor( ( Horde.points + ( lowest * baseInfo[ Horde.bases ] + 0.5 ) ) / 10 ) * 10;

	if( SSPVP.db.profile.ab.finalScore ) then
		SSOverlay:UpdateText( "abinfo", L["Final Score: %d"], SSOverlay:GetFactionColor( "Alliance" ), Alliance.final );
		SSOverlay:UpdateText( "abinfo", L["Final Score: %d"], SSOverlay:GetFactionColor( "Horde" ), Horde.final );
	end
	
	if( UnitFactionGroup( "player" ) == "Alliance" ) then
		enemy = Horde;
		friendly = Alliance;
	else
		enemy = Alliance;
		friendly = Horde;
	end
	
	local baseLowest;
	
	for i=1, 5 do
		local enemyTime = enemy.left / baseInfo[ 5 - i ];
		local friendlyTime = friendly.left / baseInfo[ i ];
		if( friendlyTime < enemyTime ) then
			baseLowest = friendlyTime;
		else
			baseLowest = enemyTime;
		end
		
		local enemyFinal = floor( ( enemy.points + floor( baseLowest * baseInfo[ 5 - i ] + 0.5 ) ) / 10 ) * 10;
		local friendlyFinal = floor( ( friendly.points + floor( baseLowest * baseInfo[ i ] + 0.5 ) ) / 10 ) * 10;
		
		if( friendlyFinal >= 2000 and enemyFinal < 2000 ) then
			Alliance.basesWin = i;
			Horde.basesWin = i;
			
			if( SSPVP.db.profile.ab.basesWin ) then
				if( not SSPVP.db.profile.ab.basesScore ) then
					SSOverlay:UpdateText( "abinfo", L["Bases to win: %d"], SSOverlay:GetFactionColor(), i );
				else
					local allianceScore, hordeScore;
					if( UnitFactionGroup( "player" ) == "Alliance" ) then
						Alliance.baseScore = friendlyFinal;
						Horde.baseScore = enemyFinal;
					else
						Alliance.baseScore = enemyFinal;
						Horde.baseScore = friendlyFinal;
					end
					
					SSOverlay:UpdateText( "abinfo", L["Bases to win: %d (A:%d/H:%d)"], SSOverlay:GetFactionColor(), i, Alliance.baseScore, Horde.baseScore );
				end
			end
			break;
		end
	end
end

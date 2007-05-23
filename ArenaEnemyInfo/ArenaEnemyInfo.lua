AEI = DongleStub("Dongle-1.0"):New( "ArenaEnemyInfo" );

local L = AEILocals;

local enemies = {};

local BattlefieldID = -1;
local BFTeamSize = 0;

local PlayerTeams = {};
local PlayerFaction;
local FactionRaces = {};

local whisperQueue = {};

local chars = "ab8cd9e4fgh5ijk20lm7no6pq3rstuvw1xyz";
local charLength = string.len( chars );

function AEI:Initialize()
	-- No ID yet, so set it up
	if( not AEI_NoDataID ) then
		AEI_NoDataID = 0;
	end
	
	-- Either the table doesn't exist yet, or the data id's match up
	if( not AEI_NoData or AEI_NoDataID == AEI_DataID ) then
		AEI_NoData = {};
	end
	
	if( not AEI_Teams ) then
		AEI_Teams = {};
	end
	
	self.defaults = {
		profile = {
			output = true,
			scan = true,
			aggressive = true,
			cutoff = 0,
		},
	};
	
	self.db = self:InitializeDB( "AEIDB", self.defaults )
	self.db:SetProfile( self.db.keys.char );
	
	--local cmd = self:InitializeSlashCommand( L["Arena Enemy Info commands"], "ArenaEnemyInfo", "aei", "arenaenemyinfo", "arenainfo" );
	--cmd:RegisterSlashHandler( L["output - Toggles messages for enemy team scanning."], "output", "CmdOutput" );
	--cmd:RegisterSlashHandler( L["scan - Toggles scanning of enemy teams in arenas."], "scan", "CmdScan" );
	--cmd:RegisterSlashHandler( L["aggressive - Toggles aggressive scanning mode, will check everyone on a team instead of just healer classes."], "aggressive", "CmdAggressive" );
	--cmd:RegisterSlashHandler( L["cutoff <days> - Only scan teams that you've seen within the set period of days, 0 for no cut off."], "cutoff (%d+)", "CmdCutOff" );

	hooksecurefunc( "WorldStateScoreFrame_Update", self.WorldStateScoreFrame_Update );
	
	PlayerFaction = UnitFactionGroup( "player" );
	
	for _, race in pairs( L[ PlayerFaction ] ) do
		FactionRaces[ race ] = true;
	end
	
	self:RegisterEvent( "ADDON_LOADED" );
	self:RegisterEvent( "ARENA_TEAM_UPDATE" );
	self:RegisterEvent( "UPDATE_BATTLEFIELD_STATUS" );
end

function AEI:EnableModule()
	self:RegisterEvent( "UPDATE_MOUSEOVER_UNIT" );
	self:RegisterEvent( "CHAT_MSG_ADDON" );
end

function AEI:DisableModule()
	self:UnregisterEvent( "UPDATE_MOUSEOVER_UNIT" )
	self:UnregisterEvent( "CHAT_MSG_ADDON" )
end

function AEI:ADDON_LOADED( event, addon )
	if( addon == "AEI_Data" and AEI_NoDataID == AEI_DataID ) then
		AEI_NoData = {};
	end
end

function AEI:Message( msg )
	if( self.db.profile.output ) then
		self:Print( msg );
	end
end

function AEI:StartWhisperScan()
	
end

function AEI:SendWhisper( name )
	SendAddonMessage( AEI:GenerateRandomText(), AEI:GenerateRandomText(), "WHISPER", name );
end

function AEI:GenerateRandomText()
	local text = "";
	local pos, char;
	
	for i=1, math.random( 5 ) + 2 do
		pos = math.random( charLength );
		char = string.sub( chars, pos, pos );
		if( math.random( 10 ) <= 5 ) then
			char = string.upper( char );
		end
		
		text = text .. char;
	end
	
	return text;
end

-- Slash commands
function AEI:CmdOutput()
	self.db.profile.output = not self.db.profile.output;
	local status = L["off"];
	if( self.db.profile.output ) then
		status = L["on"];
	end
	
	self:Print( string.format( L["Output during scanning is now %s."], status ) );
end

function AEI:CmdScan()
	self.db.profile.scan = not self.db.profile.scan;
	local status = L["off"];
	if( self.db.profile.scan ) then
		status = L["on"];
	end
	
	self:Print( string.format( L["Team scanning is now %s."], status ) );
end

function AEI:CmdAggressive()
	self.db.profile.aggressive = not self.db.profile.aggressive;
	local status = L["off"];
	if( self.db.profile.aggressive ) then
		status = L["on"];
	end
	
	self:Print( string.format( L["Aggressive scanning is now %s."], status ) );
end

function AEI:CmdCutOff( days )
	days = tonumber( days );
	
	self.db.profile.cutoff = days;
	self:Print( string.format( L["Cut off set to %d days."], days ) );
end

local function SortTime( a, b )
	if( not b ) then
		return false;
	end
	
	return ( a.lastSeen > b.lastSeen );	
end

function AEI:WorldStateScoreFrame_Update()
	local isArena, isRegistered = IsActiveBattlefieldArena();
	if( not isArena or not isRegistered ) then
		return;
	end
	
	-- Make sure it's not an invalid game and figure out
	-- which team the enemy is
	local EnemyTeam, teamName, teamRating;
	for i=0, 1 do
		teamName, teamRating = GetBattlefieldTeamInfo( i );
		
		-- Invalid game
		if( teamRating == 0 ) then
			return;
		end
		
		if( not PlayerTeams[ teamName ] ) then
			EnemyTeam = i;
			break;
		end
	end
	
	-- No team # found, kill
	if( not EnemyTeam ) then
		return;
	end
	
	-- Check for an entry
	local AEITeam_ID;
	for id, team in pairs( AEI_Teams ) do
		if( team.bracket == BFTeamSize and team.name == teamName ) then
			AEITeam_ID = id;
			AEI_Teams[ id ].bracket = BFTeamSize;
			AEI_Teams[ id ].name = teamName;
			AEI_Teams[ id ].lastSeen = time();
			break;
		end
	end
	
	-- No entry exists, add
	if( not AEITeam_ID ) then
		table.insert( AEI_Teams, { bracket = BFTeamSize, name = teamName, players = {}, lastSeen = time() } );
		AEITeam_ID = #( AEI_Teams );
	end
	
	-- Load all the enemies into the list
	local name, faction, race, classToken, foundPlayer;
	for i=1, GetNumBattlefieldScores() do
		name, _, _, _, _, faction, _, race, _, classToken = GetBattlefieldScore( i );
		
		if( string.find( name, "-" ) ) then
			foundPlayer = true;
			AEI_Teams[ AEITeam_ID ].players[ name ] = { race = race, classToken = classToken };
		end
	end
	
	if( foundPlayer ) then
		-- Resort the list by time
		table.sort( AEI_Teams, SortTime );
	else
		table.remove( AEI_Teams, AEITeam_ID );
	end
end

function AEI:BGMessage( msg )
	if( GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0 ) then
		SendChatMessage( msg, "BATTLEGROUND" );
	end
end

function AEI:ARENA_TEAM_UPDATE()
	local teamName;
	
	for i=1, MAX_ARENA_TEAMS do
		teamName = GetArenaTeam( i );
		
		if( teamName ) then
			PlayerTeams[ teamName ] = true;	
		end
	end
end

function AEI:CHAT_MSG_ADDON( event, prefix, msg, type, author )
	if( prefix == "SSPVP" and not IsAddOnLoaded( "SSPVP" ) ) then
		local _, _, dataType, data = string.find( msg, "([^:]+)%:(.+)" );
		
		if( dataType and data and dataType == "ENEMY" ) then
			local name, server, race, classToken, guild = string.split( ",", data );
			
			for _, enemy in pairs( enemies ) do
				if( enemy.name == name ) then
					return;
				end
			end

			table.insert( enemies, { name = name, server = server, race = race, classToken = classToken, guild = guild } );
		end
	end
end

function AEI:StartWhisperScan()

end

function AEI:UPDATE_BATTLEFIELD_STATUS()
	local status, teamSize;
	
	for i=1, MAX_BATTLEFIELD_QUEUES do
		status, _, _, _, _, teamSize = GetBattlefieldStatus( i );
		
		if( status == "active" and i ~= BattlefieldID ) then
			BattlefieldID = i;
			BFTeamSize = teamSize;
			
			if( teamSize > 0 ) then
				LoadAddOn( "AEI_Data" );
				
				self:EnableModule();
				
				--[[
				self:Message( string.format( L["Starting team scan for %dvs%d."], teamSize, teamSize ) );
				
				whisperQueue = {};
				
				-- Create our queue to whisper
				whisperQueue = {};
				for id, team in pairs( AEI_Teams ) do
					if( team.bracket == teamSize and ( self.db.profile.cutoff == 0 or team.lastSeen >= cutOff ) ) then
						for playerName, player in pairs( team.players ) do
							if( FactionRaces[ player.race ] ) then
								-- Only scan the healer classes, i'll add
								if( player.classToken == "PRIEST" or player.classToken == "DRUID" or player.classToken == "PALADIN" or player.classToken == "SHAMAN" ) then
									table.insert( whisperQueue, { team = id, name = playerName } );
								end
							end
						end
					end
				end

				self:Message( string.format( L["Whisper queue compiled, %d players."], #( whisperQueue ) ) );
				self:StartWhisperScan();
				]]
			end
			
		elseif( status ~= "active" and i == BattlefieldID ) then
			BattlefieldID = -1;
			enemies = {};
			
			self:DisableModule();
		end
	end	
end

function AEI:UPDATE_MOUSEOVER_UNIT()
	if( UnitIsPlayer( "mouseover" ) and UnitIsEnemy( "mouseover", "player" ) and UnitIsPVP( "mouseover" ) ) then
		local name, server = UnitName( "mouseover" );
		server = ( server or GetRealmName() );
		
		if( not AEI_Data[ name .. "-" .. server ] ) then
			for _, noSpec in pairs( AEI_NoData ) do
				if( noSpec == name .. "-" .. server ) then
					return;
				end
			end
			
			AEI_NoDataID = floor( GetTime() );
			table.insert( AEI_NoData, name .. "-" .. server );
		end
		
		-- SSPVP 3 has built in support for this so don't send duplicate messages
		if( IsAddOnLoaded( "SSPVP" ) ) then
			return;
		end
		
		for _, enemy in pairs( enemies ) do
			if( enemy.name == name ) then
				return;
			end
		end
		
		local race = UnitRace( "mouseover" );
		local class, classToken = UnitClass( "mouseover" );
		local guild = GetGuildInfo( "mouseover" );
		local spec = "";

		table.insert( enemies, { name = name, server = server, race = race, classToken = classToken, guild = guild } );
		
		if( AEI_Data[ name .. "-" .. server ] ) then
			spec = " /" .. AEI:GetSpec( name, server );
		end
		
		-- Print out info message
		if( guild ) then
			AEI:BGMessage( string.format( "%s / %s / %s / %s / %s", name, class, race, guild, server ) .. spec );
			AEI:CommMessage( "ENEMY:" .. name .. "," .. server .. "," .. race .. "," .. classToken .. "," .. guild );
		else
			AEI:BGMessage( string.format( "%s / %s / %s / %s", name, class, race, server ) .. spec );				
			AEI:CommMessage( "ENEMY:" .. name .. "," .. server .. "," .. race .. "," .. classToken );
		end
	end
end

-- Why identify as SSPVP? 
-- Because i'm lazy and rather use the format I already have for syncing
function AEI:CommMessage( msg )
	SendAddonMessage( "SSPVP", msg, "BATTLEGROUND" );
end


-- Get the formatted spec as " [##/##/##]" if found
function AEI:GetSpec( name, server )
	name = name .. "-" .. server;
	
	
	if( AEI_Data[ name ] ) then
		local point1, point2, point3 = string.split( ":", AEI_Data[ name ] );
		return " [" .. point1 .. "/" .. point2 .. "/" .. point3 .. "]";
	end
	
	return "";
end

-- Gets the actual spec numbers if you want to use your own formatting
function AEI:GetTalents( name, server )
	name = name .. "-" .. server;
	
	if( AEI_Data[ name ] ) then
		return string.split( ":", AEI_Data[ name ]);
	end
	
	return 0, 0, 0;
end
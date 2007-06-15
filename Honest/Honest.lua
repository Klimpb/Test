Honest = DongleStub("Dongle-1.0"):New( "Honest" );

local L = HonestLocals;

local LastWin = 0;
local StartTime = 0;
local HonorGained = 0;

local RegisteredFrames = {};
local OH = DongleStub("OptionHouse-Alpha0.1")

function Honest:Enable()
	self.defaults = {
		profile = {
			arena = {
				lastWeek = 0,
			},
			today = {
				totals = {
					total = 0,
					bonus = 0,
					kill = 0,
					win = 0,
					lose = 0,
				},
				record = {},
				bonus = {},
				kill = {},
				killed = {},
			},
			yesterday = {
				totals = {
					total = 0,
					bonus = 0,
					kill = 0,
					win = 0,
					lose = 0,
					honor = 0,
				},
				timeOut = 0,
				record = {},
				bonus = {},
				kill = {},
				killed = {},
			},
			showKilled = true,
			showActual = true,
			showEstimated = true,
		}
	}
	
	self.db = self:InitializeDB( "HonestDB", self.defaults )
	self.db:SetProfile( self.db.keys.char );

	self.cmd = self:InitializeSlashCommand( L["Honest slash commands"], "Honest", "honest" );
	--self.cmd:InjectDBCommands( self.db, "delete", "copy", "list", "set" );
	self.cmd:RegisterSlashHandler( L["ui - Opens the OptionHoues UI"], "ui", OH.Open )
	self.cmd:RegisterSlashHandler( L["actual - Toggles showing actual honor gained for kills"], "actual", "ToggleActual" );	
	self.cmd:RegisterSlashHandler( L["estimated - Toggles showing estimated honor gained for kills"], "estimated", "ToggleEstimated" );	
	self.cmd:RegisterSlashHandler( L["killed - Toggles showing how many times you've killed a person"], "killed", "ToggleKilled" );	
	
	self:RegisterEvent( "CHAT_MSG_COMBAT_HONOR_GAIN" );
	
	self:RegisterEvent( "PLAYER_ENTERING_WORLD", "CheckDay" );
	self:RegisterEvent( "PLAYER_PVP_KILLS_CHANGED", "CheckDay" );
	self:RegisterEvent( "PLAYER_PVP_RANK_CHANGED", "CheckDay" );
	self:RegisterEvent( "HONOR_CURRENCY_UPDATE", "CheckDay" );

	L["BonusString"] = string.gsub( COMBATLOG_HONORAWARD, "%%d", "([0-9]+)" );
	L["HKString"] = string.gsub( string.gsub( string.gsub( string.gsub( COMBATLOG_HONORGAIN , "%)", "%%)" ), "%(", "%%(" ), "%%s", "(.+)" ), "%%d", "([0-9]+)" );
	
	hooksecurefunc( "WorldStateScoreFrame_Update", self.WSSF_Update );
	hooksecurefunc( "PVPFrame_Update", self.PVPFrame_Update );
	hooksecurefunc( "PVPTeamDetails_OnShow", self.HideHonest );
	hooksecurefunc( "PVPTeamDetails_OnHide", self.ShowHonest );
		
	PVPHonorTodayHonor:SetWidth( 75 );
	PVPHonorTodayHonor:ClearAllPoints();
	PVPHonorTodayHonor:SetPoint( "CENTER", "PVPHonorTodayKills", "BOTTOM", 0, -12 );

	getglobal( "PVPHonorToday~" ):Hide();
	
	self:PVPFrame_Update();
	self:CheckDay();
	
	-- Register with OH
	local ui = OH:RegisterAddOn( L["Honest"], L["Honest"], "Amarand", "r" .. tonumber( string.match( "$Revision$", "(%d+)" ) or 1 ) )
	ui:RegisterCategory( L["General"], self, CreateUI )
	
	-- For upgrading format to the new one with split arena thing,
	-- I could make it transfer it to the new one too, but i'm lazy.
	for location, record in pairs( self.db.profile.today.record ) do
		if( not record.teamSize and string.match( location, L["%([0-9]+vs[0-9]+%)"] ) ) then
			self.db.profile.today.record[ location ] = nil;
		end
	end
end

function Honest:CreateUI()
	local frame = CreateFrame("Frame")
	frame:SetScript("OnShow", function()
		Honest.actualCheck:SetChecked( Honest.db.profile.showActual )	
		Honest.estimateCheck:SetChecked( Honest.db.profile.showEstimated )	
		Honest.killedCheck:SetChecked( Honest.db.profile.showKilled )	
	end )
	
	self.actualCheck = CreateFrame( "Checkbox", nil, frame, "OptionsCheckButtonTemplate" )
	self.actualCheck:SetPoint( "TOPLEFT", 5, -5 )
	self.actualCheck:SetHeight( 16 )
	self.actualCheck:SetWidth( 16 )
	self.actualCheck:SetText( L["Show actual honor gains"] )
	self.actualCheck:SetScript( "OnClick", function()
		if( this:GetChecked() ) then
			Honest.db.profile.showActual = true
		else
			Honest.db.profile.showActual = false		
		end
	end )
	
	self.estimateCheck = CreateFrame( "Checkbox", nil, frame, "OptionsCheckButtonTemplate" )
	self.estimateCheck:SetPoint( "TOPLEFT", 5, -25 )
	self.estimateCheck:SetHeight( 16 )
	self.estimateCheck:SetWidth( 16 )
	self.estimateCheck:SetText( L["Show estimated honor gains"] )
	self.estimateCheck:SetScript( "OnClick", function()
		if( this:GetChecked() ) then
			Honest.db.profile.showEstimated = true
		else
			Honest.db.profile.showEstimated = false		
		end
	end )
	
	self.killedCheck = CreateFrame( "Checkbox", nil, frame, "OptionsCheckButtonTemplate" )
	self.killedCheck:SetPoint( "TOPLEFT", 5, -50 )
	self.killedCheck:SetHeight( 16 )
	self.killedCheck:SetWidth( 16 )
	self.killedCheck:SetText( L["Show how many times an enemy has died"] )
	self.killedCheck:SetScript( "OnClick", function()
		if( this:GetChecked() ) then
			Honest.db.profile.showKilled = true
		else
			Honest.db.profile.showKilled = false		
		end
	end )
	
	return frame
end

function Honest:HideHonest()
	if( Honest.frame ) then
		Honest.frame:Hide();
	end
end

function Honest:ShowHonest()
	if( PVPFrame:IsShown() and Honest.frame ) then
		Honest.frame:Show();
	end
end

function Honest:ToggleActual()
	self.db.profile.showActual = not self.db.profile.showActual;
	
	if( self.db.profile.showActual ) then
		self:Print( string.format( L["Actual honor gains is now %s"], L["on"] ) );
	else
		self:Print( string.format( L["Actual honor gains is now %s"], L["off"] ) );	
	end
end

function Honest:ToggleEstimated()
	self.db.profile.showEstimated = not self.db.profile.showEstimated;
	
	if( self.db.profile.showEstimated ) then
		self:Print( string.format( L["Estimated honor gains is now %s"], L["on"] ) );
	else
		self:Print( string.format( L["Estimated honor gains is now %s"], L["off"] ) );	
	end
end

function Honest:ToggleKilled()
	self.db.profile.showKilled = not self.db.profile.showKilled;
	
	if( self.db.profile.showKilled ) then
		self:Print( string.format( L["Total times killed is now %s"], L["on"] ) );
	else
		self:Print( string.format( L["Total times killed is now %s"], L["off"] ) );	
	end
end

function Honest:Disable()
	self:UnregisterAllEvents();
end

function Honest:WSSF_Update()
	if( not GetBattlefieldWinner() or ( LastWin > 0 and LastWin > GetTime() ) ) then
		return;
	end
	
	-- Shhh, nobodies allowed to win in 2 minutes again
	LastWin = GetTime() + 120;
	
	local  playerTeam;
	
	for i=1, GetNumBattlefieldScores() do
		local name, _, _, _, _, faction = GetBattlefieldScore( i );
		
		if( name == UnitName( "player" ) ) then
			playerTeam = faction;
			break;
		end
	end
	
	local location, unparsedMap, teamSize, isRegistered = Honest:GetLocation();

	if( not Honest.db.profile.today.record[ location ] ) then
		Honest.db.profile.today.record[ location ] = { win = 0, lose = 0, rated = isRegistered, teamSize = teamSize, map = unparsedMap };
	end
	
	if( playerTeam == GetBattlefieldWinner() ) then
		Honest.db.profile.today.totals.win = Honest.db.profile.today.totals.win + 1;
		Honest.db.profile.today.record[ location ].win = Honest.db.profile.today.record[ location ].win + 1;
	else
		Honest.db.profile.today.totals.lose = Honest.db.profile.today.totals.lose + 1;
		Honest.db.profile.today.record[ location ].lose = Honest.db.profile.today.record[ location ].lose + 1;
	end
end

local Orig_ChatFrame_MessageEventHandler = ChatFrame_MessageEventHandler;
function ChatFrame_MessageEventHandler( event )
	if( event == "CHAT_MSG_COMBAT_HONOR_GAIN" ) then
		RegisteredFrames[ this ] = true;
		return false;
	end
	
	return Orig_ChatFrame_MessageEventHandler( event );
end

function Honest:CheckDay()
	-- Check arena
	if( GetArenaCurrency() ~= self.db.profile.arena.lastWeek ) then
		-- Only show the message if we gained points, HOPEFULLY
		-- this will mean it only shows on reset and not when we spend points
		if( GetArenaCurrency() >= self.db.profile.arena.lastWeek ) then
			local pointsTeam, pointsBracket, teamName, teamSize, teamRating;
			local teamPoints = 0;
			local highestPoints = 0;
			
			for i=1, MAX_ARENA_TEAMS do
				teamName, teamSize, teamRating = GetArenaTeam( i );
				
				if( teamName ) then
					if( teamRating > 1500 ) then
						teamPoints = 1426.79 / ( 1 + 918.836 * math.pow( 2.71828, -0.00386405 * teamRating ) );
					else
						teamPoints = ( 0.38 * teamRating ) - 194;
					end
					
					if( teamPoints < 0 ) then
						teamPoints = 0;
					end

					if( teamSize == 3 ) then
						teamPoints = teamPoints * 0.80
					elseif( teamSize == 2 ) then
						teamPoints = teamPoints * 0.70	
					end

					if( teamPoints > highestPoints ) then
						pointsTeam = teamName;
						pointsBracket = teamSize;
						highestPoints = floor( teamPoints );
					end
				end
			end
			
			-- Depending on when honor resets, we don't always have access to team info
			if( not pointsTeam ) then
				self:Print( string.format( L["Arena has reset! You gained %d points, for a total of %d."], ( GetArenaCurrency() - self.db.profile.arena.lastWeek ), GetArenaCurrency() ) );
			else
				self:Print( string.format( L["Arena has reset! You gained %d points from %s (%dvs%d), for a total of %d."], highestPoints, pointsTeam, pointsBracket, pointsBracket, GetArenaCurrency() ) );
			end
		end
		
		self.db.profile.arena.lastWeek = GetArenaCurrency();
	end
	
	-- Check honor
	local _, yesterdayHonor = GetPVPYesterdayStats();

	if( yesterdayHonor ~= self.db.profile.yesterday.totals.honor or ( self.db.profile.yesterday.timeOut > 0 and self.db.profile.yesterday.timeOut <= time() ) ) then
		local todayHonor = self.db.profile.today.totals.total;
		local diff = math.abs( yesterdayHonor - todayHonor );
		local diffPerc;
		
		if( yesterdayHonor < todayHonor ) then
			diffPerc = yesterdayHonor / todayHonor;
		else
			diffPerc = todayHonor / yesterdayHonor;
		end
		
		if( todayHonor > 0 and yesterdayHonor > 0 ) then
			self:Print( string.format( L["Honor has reset! Estimated %d, Actual %d, Difference %d (%.2f%% off)"], todayHonor, yesterdayHonor, diff, ( 100 - diffPerc * 100 ) ) );
		end
		
		HonorGained = 0;
		StartTime = 0;
		
		-- Why 26 instead of 24? Because Honor doesn't reset at the
		-- same time every day
		self.db.profile.yesterday = self.db.profile.today;
		self.db.profile.yesterday.totals.honor = yesterdayHonor;
		self.db.profile.yesterday.timeOut = time() + ( 60 * 60 * 26 );
		
		-- Now reset the database
		self.db.profile.today = {
			totals = {
				total = 0,
				bonus = 0,
				kill = 0,
				win = 0,
				lose = 0,
			},
			record = {},
			bonus = {},
			kill = {},
			killed = {},
		};
		                
		
		self:PVPFrame_Update();
	end
end

function Honest:GetLocation()
	local status, map, teamSize;
	for i=1, MAX_BATTLEFIELD_QUEUES do
		status, map, _, _, _, teamSize, isRated = GetBattlefieldStatus( i );
		
		if( status == "active" and teamSize > 0 ) then
			if( isRated ) then
				return string.format( L["%s (%s) (%dvs%d)"], map, L["R"], teamSize, teamSize ), map, teamSize, isRated;			
			else
				return string.format( L["%s (%s) (%dvs%d)"], map, L["S"], teamSize, teamSize ), map, teamSize, isRated
			end
		end
	end
	
	return GetRealZoneText() or L["Unknown"];
end

function Honest:AddHonor( amount, type )
	self.db.profile.today.totals[ type ] = ( self.db.profile.today.totals[ type ] or 0 ) + amount;
	self.db.profile.today[ type ][ self:GetLocation() ] = ( self.db.profile.today[ type ][ self:GetLocation() ] or 0 ) + amount;
	self.db.profile.today.totals.total = self.db.profile.today.totals.total + amount;
	
	if( IsAddOnLoaded( "sct" ) and SCT.db.profile.SHOWHONOR ) then
		SCT:DisplayText( "+" .. floor( amount ) .. " " .. HONOR, SCT.db.profile[ SCT.COLORS_TABLE ].SHOWHONOR, nil, "event", 1 );

	elseif( IsAddOnLoaded( "Blizzard_CombatText" ) ) then
		CombatText_AddMessage( string.format( COMBAT_TEXT_HONOR_GAINED, honor ), COMBAT_TEXT_SCROLL_FUNCTION, COMBAT_TEXT_TYPE_INFO["HONOR_GAINED"].r, COMBAT_TEXT_TYPE_INFO["HONOR_GAINED"].g, COMBAT_TEXT_TYPE_INFO["HONOR_GAINED"].b, COMBAT_TEXT_TYPE_INFO["HONOR_GAINED"].var, COMBAT_TEXT_TYPE_INFO["HONOR_GAINED"].isStaggered  );
	end
end

function Honest:CHAT_MSG_COMBAT_HONOR_GAIN( event, msg )
	self:CheckDay();
	
	if( string.match( msg, L["HKString"] ) ) then
		local name, rank, honor = string.match( msg, L["HKString"] );
		local actualHonor = 0;
		
		if( self.db.profile.today.killed[ name ] ) then
			if( self.db.profile.today.killed[ name ] < 10 ) then
				actualHonor = math.floor( honor * ( 1.0 - ( ( self.db.profile.today.killed[ name ] - 1 ) / 10 ) ) );
			end
						
			self.db.profile.today.killed[ name ] = self.db.profile.today.killed[ name ] + 1;
		else
			actualHonor = honor;
			self.db.profile.today.killed[ name ] = 1;
		end
		
		local optionsEnabled = 0;
		if( self.db.profile.showKilled ) then optionsEnabled = optionsEnabled + 1; end;
		if( self.db.profile.showEstimated ) then optionsEnabled = optionsEnabled + 1; end;
		if( self.db.profile.showActual ) then optionsEnabled = optionsEnabled + 1; end;
		
				
		local options = {};
		if( self.db.profile.showEstimated ) then
			if( optionsEnabled > 2 ) then
				table.insert( options, string.format( L["Estimated: %d"], honor ) );
			else
				table.insert( options, string.format( L["Estimated Honor Points: %d"], honor ) );
			end
		end

		if( self.db.profile.showActual ) then
			if( optionsEnabled > 2 ) then
				table.insert( options, string.format( L["Actual: %d"], honor ) );
			else
				table.insert( options, string.format( L["Actual Honor Points: %d"], actualHonor ) );
			end
		end
		
		if( self.db.profile.showKilled ) then
			table.insert( options, string.format( L["Killed: %d"],  self.db.profile.today.killed[ name ] ) );
		end
				
		if( optionsEnabled > 0 ) then
			msg = string.format( L["%s dies, honorable kill (%s)"], name, table.concat( options, ", " ) );
		else
			msg = string.format( L["%s dies, honorable kill"], name );
		end
		
		for frame, _ in pairs( RegisteredFrames ) do
			frame:AddMessage( msg, ChatTypeInfo["COMBAT_HONOR_GAIN"].r, ChatTypeInfo["COMBAT_HONOR_GAIN"].g, ChatTypeInfo["COMBAT_HONOR_GAIN"].b );
		end
		
		self:AddHonor( actualHonor, "kill" );
	
	elseif( string.match( msg, L["BonusString"] ) ) then
		local honor = string.match( msg, L["BonusString"] );
		
		self:AddHonor( honor, "bonus" );
	end
end

local function SortHonor( a, b )
	if( not b ) then
		return false;
	end
	
	return ( a[2] > b[2] );
end

local function SortBattlefields( a, b )
	if( not b ) then
		return false;
	end
	
	if( a.perct == 0 and b.perct == 0 ) then
		return ( a.avg > b.avg );
	end
	
	return ( a.perct > b.perct );
end

local function SortArenas( a, b )
	if( not b ) then
		return false;
	end
	
	return ( a.teamSize > b.teamSize );
end

function Honest:UpdateHonorUI( day )
	if( not self.frame or not PVPFrame:IsShown() ) then
		return;
	end
	
	local self = Honest;
	
	-- HONOR ESTIMATIONS
	if( day == "today" ) then
		self.estimateText:SetText( string.format( L["Honest Estimated: |cFFFFFFFF%d|r / Blizzard Estimated: |cFFFFFFFF%d|r"], self.db.profile[ day ].totals.total, select( 2, GetPVPSessionStats() ) ) );
	elseif( day == "yesterday" ) then
		self.estimateText:SetText( string.format( L["Honest Estimated: |cFFFFFFFF%d|r / Actual Honor: |cFFFFFFFF%d|r"], self.db.profile[ day ].totals.total, select( 2, GetPVPYesterdayStats() ) ) );
	end

	-- KILL HONOR
	if( self.totalKill ) then
		for i=1, self.totalKill do
			getglobal( self.frame:GetName() .. "KillText" .. i ):Hide();
		end
	end
	
	local lastCategory = self.killText;
	local killPercent = 0;
	if( self.db.profile[ day ].totals.kill > 0 and self.db.profile[ day ].totals.total > 0 ) then
		killPercent = ( self.db.profile[ day ].totals.kill / self.db.profile[ day ].totals.total ) * 100;
	end
	
	self.killText:SetText( string.format( L["Kill Honor: |cFFFFFFFF%d|r (|cFFFFFFFF%.2f%%|r)"], self.db.profile[ day ].totals.kill, killPercent ) );
	
	local killList = {};
	for location, amount in pairs( self.db.profile[ day ].kill ) do
		table.insert( killList, { location, amount } );
	end
	
	table.sort( killList, SortHonor );
	self.totalKill = #( killList );
	
	for i, info in pairs( killList ) do
		local text;
		if( getglobal( self.frame:GetName() .. "KillText" .. i ) ) then
			text = getglobal( self.frame:GetName() .. "KillText" .. i );
		else
			text = self.frame:CreateFontString( self.frame:GetName() .. "KillText" .. i, "BACKGROUND" );
			text:SetFontObject( GameFontNormalSmall );
			text:SetTextColor( 1, 1, 1, 1 );
			
			if( i > 1 ) then
				text:SetPoint( "TOPLEFT", self.frame:GetName() .. "KillText" .. ( i - 1 ), "TOPLEFT", 0, -12 );
			else
				text:SetPoint( "TOPLEFT", self.killText, "TOPLEFT", 0, -18 );
			end
		end
		
		text:SetText( string.format( L["%s: %d"], info[1], info[2] ) );
		text:Show();
		
		lastCategory = text;
	end
	
	-- Hide all the bonus stuff
	if( self.totalBonus ) then
		for i=1, self.totalBonus do
			getglobal( self.frame:GetName() .. "BonusText" .. i ):Hide();
		end
	end
	
	-- BONUS HONOR
	local bonusPercent = 0;
	if( self.db.profile[ day ].totals.bonus > 0 and self.db.profile[ day ].totals.total > 0 ) then
		bonusPercent = ( self.db.profile[ day ].totals.bonus / self.db.profile[ day ].totals.total ) * 100;
	end

	self.bonusText:SetText( string.format( L["Bonus Honor: |cFFFFFFFF%d|r (|cFFFFFFFF%.2f%%|r)"], self.db.profile[ day ].totals.bonus, bonusPercent ) );
	
	local bonusList = {};
	for location, amount in pairs( self.db.profile[ day ].bonus ) do
		table.insert( bonusList, { location, amount } );
	end
	
	table.sort( bonusList, SortHonor );
	self.totalBonus = #( bonusList );
	
	for i, info in pairs( bonusList ) do
		local text;
		
		if( getglobal( self.frame:GetName() .. "BonusText" .. i ) ) then
			text = getglobal( self.frame:GetName() .. "BonusText" .. i );
		else
			text = self.frame:CreateFontString( self.frame:GetName() .. "BonusText" .. i, "BACKGROUND" );
			text:SetFontObject( GameFontNormalSmall );
			text:SetTextColor( 1, 1, 1, 1 );
			
			if( i > 1 ) then
				text:SetPoint( "TOPLEFT", self.frame:GetName() .. "BonusText" .. ( i - 1 ), "TOPLEFT", 0, -12 );
			else
				text:SetPoint( "TOPLEFT", self.bonusText, "TOPLEFT", 0, -18 );
			end
		end
		
		text:SetText( string.format( L["%s: %d"], info[1], info[2] ) );
		text:Show();
	end
	
	
	-- BATTLEFIELD RECORDS
	if( self.totalWins ) then
		for i=1, self.totalWins do
			getglobal( self.frame:GetName() .. "Records" .. i  ):Hide();
		end
	end

	local recordList = {};
	for location, record in pairs( self.db.profile[ day ].record ) do
		if( not record.teamSize ) then
			record.perct = record.win / ( record.win + record.lose );

			if( self.db.profile[ day ].bonus[ location ] or self.db.profile[ day ].kill[ location ] ) then
				record.avg = ( self.db.profile[ day ].bonus[ location ] or 0 + self.db.profile[ day ].kill[ location ] or 0 ) / ( record.win + record.lose )
			else
				record.avg = 0;
			end

			table.insert( recordList, { location = location, wins = record.win, loses = record.lose, perct = record.perct, avg = record.avg } );
		end
	end
	
	if( #( recordList ) > 0 ) then
		self.battlefieldText:Show();
		self.perctText:Show();
		self.winText:Show();
		self.loseText:Show();
		self.avgText:Show();
		
		self.battlefieldText:SetPoint( "TOPLEFT", lastCategory, "TOPLEFT", 0, -30 );	
	
		self.totalWins = #( recordList );
		table.sort( recordList, SortBattlefields );
		
		for i, info in pairs( recordList ) do
			local frame, battlefield, wins, loses, perct;
			local recordName = self.frame:GetName() .. "Records" .. i;
			
			if( getglobal( recordName ) ) then
				frame = getglobal( recordName );
				battlefield = getglobal( frame:GetName() .. "Battlefield" );
				wins = getglobal( frame:GetName() .. "Wins" );
				loses = getglobal( frame:GetName() .. "Loses" );
				perct = getglobal( frame:GetName() .. "Perct" );
				avg = getglobal( frame:GetName() .. "Average" );
			else
				frame = CreateFrame( "Frame", recordName, self.frame );

				battlefield = frame:CreateFontString( frame:GetName() .. "Battlefield", "BACKGROUND" );
				battlefield:SetFontObject( GameFontNormalSmall );
				battlefield:SetTextColor( 1, 1, 1, 1 );

				wins = frame:CreateFontString( frame:GetName() .. "Wins", "BACKGROUND" );
				wins:SetFontObject( GameFontNormalSmall );
				wins:SetTextColor( 0, 1, 0, 1 );

				loses = frame:CreateFontString( frame:GetName() .. "Loses", "BACKGROUND" );
				loses:SetFontObject( GameFontNormalSmall );
				loses:SetTextColor( 1, 0, 0, 1 );

				perct = frame:CreateFontString( frame:GetName() .. "Perct", "BACKGROUND" );
				perct:SetFontObject( GameFontNormalSmall );
				perct:SetTextColor( 1, 1, 1, 1 );

				avg = frame:CreateFontString( frame:GetName() .. "Average", "BACKGROUND" );
				avg:SetFontObject( GameFontNormalSmall );
				avg:SetTextColor( 1, 1, 1, 1 );

				if( i > 1 ) then
					battlefield:SetPoint( "TOPLEFT", self.frame:GetName() .. "Records" .. ( i - 1 ) .. "Battlefield", "TOPLEFT", 0, -12 ); 			
					wins:SetPoint( "CENTER", self.frame:GetName() .. "Records" .. ( i - 1 ) .. "Wins", "CENTER", 0, -12 ); 			
					loses:SetPoint( "CENTER", self.frame:GetName() .. "Records" .. ( i - 1 ) .. "Loses", "CENTER", 0, -12 ); 			
					perct:SetPoint( "CENTER", self.frame:GetName() .. "Records" .. ( i - 1 ) .. "Perct", "CENTER", 0, -12 ); 
					avg:SetPoint( "CENTER", self.frame:GetName() .. "Records" .. ( i - 1 ) .. "Average", "CENTER", 0, -12 ); 
				else
					battlefield:SetPoint( "TOPLEFT", self.battlefieldText, "TOPLEFT", 0, -18 ); 			
					wins:SetPoint( "CENTER", self.winText, "CENTER", 0, -18 ); 			
					loses:SetPoint( "CENTER", self.loseText, "CENTER", 0, -18 ); 			
					perct:SetPoint( "CENTER", self.perctText, "CENTER", 0, -18 ); 			
					avg:SetPoint( "CENTER", self.avgText, "CENTER", 0, -18 ); 
				end
			end
			
			lastCategory = battlefield;

			frame:Show();

			battlefield:SetText( info.location );
			wins:SetText( info.wins );
			loses:SetText( info.loses );
			
			if( info.perct > 0 ) then
				perct:SetText( string.format( "%.1f%%", info.perct * 100 ) );
			else
				perct:SetText( "--" );
			end
			
			if( info.avg > 0 ) then
				avg:SetText( string.format( "%.2f", info.avg ) );
			else
				avg:SetText( "--" );
			end
		end
	else
		self.battlefieldText:Hide();
		self.perctText:Hide();
		self.winText:Hide();
		self.loseText:Hide();
		self.avgText:Hide();
	end

	-- ARENA RECORDS
	if( self.arenaWins ) then
		for i=1, self.arenaWins do
			getglobal( self.frame:GetName() .. "ArenaRecords" .. i  ):Hide();
		end
	end

	local recordList = {};
	for location, record in pairs( self.db.profile[ day ].record ) do
		if( record.teamSize ) then
			record.perct = record.win / ( record.win + record.lose );
			
			table.insert( recordList, { location = record.map, wins = record.win, loses = record.lose, perct = record.perct, rated = record.rated, teamSize = record.teamSize } );
		end
	end
	
	if( #( recordList ) > 0 ) then
		self.arenaText:Show();
		self.arenaPerctText:Show();
		self.arenaWinText:Show();
		self.arenaLoseText:Show();
		self.ratedText:Show();
		self.bracketText:Show();
		
		self.arenaText:SetPoint( "TOPLEFT", lastCategory, "TOPLEFT", 0, -30 );	
	
		self.arenaWins = #( recordList );
		table.sort( recordList, SortArenas );
		
		for i, info in pairs( recordList ) do
			local frame, arenaName, wins, bracket, rated, loses, perct;
			local recordName = self.frame:GetName() .. "ArenaRecords" .. i;
			
			if( getglobal( recordName ) ) then
				frame = getglobal( recordName );
				arenaName = getglobal( frame:GetName() .. "Arena" );
				wins = getglobal( frame:GetName() .. "Wins" );
				bracket = getglobal( frame:GetName() .. "Bracket" );
				rated = getglobal( frame:GetName() .. "Rated" );
				loses = getglobal( frame:GetName() .. "Loses" );
				perct = getglobal( frame:GetName() .. "Perct" );
			else
				frame = CreateFrame( "Frame", recordName, self.frame );

				arenaName = frame:CreateFontString( frame:GetName() .. "Arena", "BACKGROUND" );
				arenaName:SetFontObject( GameFontNormalSmall );
				arenaName:SetTextColor( 1, 1, 1, 1 );

				wins = frame:CreateFontString( frame:GetName() .. "Wins", "BACKGROUND" );
				wins:SetFontObject( GameFontNormalSmall );
				wins:SetTextColor( 0, 1, 0, 1 );

				loses = frame:CreateFontString( frame:GetName() .. "Loses", "BACKGROUND" );
				loses:SetFontObject( GameFontNormalSmall );
				loses:SetTextColor( 1, 0, 0, 1 );

				perct = frame:CreateFontString( frame:GetName() .. "Perct", "BACKGROUND" );
				perct:SetFontObject( GameFontNormalSmall );
				perct:SetTextColor( 1, 1, 1, 1 );

				rated = frame:CreateFontString( frame:GetName() .. "Rated", "BACKGROUND" );
				rated:SetFontObject( GameFontNormalSmall );
				rated:SetTextColor( 1, 1, 1, 1 );

				bracket = frame:CreateFontString( frame:GetName() .. "Bracket", "BACKGROUND" );
				bracket:SetFontObject( GameFontNormalSmall );
				bracket:SetTextColor( 1, 1, 1, 1 );

				if( i > 1 ) then
					arenaName:SetPoint( "TOPLEFT", self.frame:GetName() .. "ArenaRecords" .. ( i - 1 ) .. "Arena", "TOPLEFT", 0, -12 ); 			
					bracket:SetPoint( "CENTER", self.frame:GetName() .. "ArenaRecords" .. ( i - 1 ) .. "Bracket", "CENTER", 0, -12 ); 
					rated:SetPoint( "CENTER", self.frame:GetName() .. "ArenaRecords" .. ( i - 1 ) .. "Rated", "CENTER", 0, -12 ); 
					wins:SetPoint( "CENTER", self.frame:GetName() .. "ArenaRecords" .. ( i - 1 ) .. "Wins", "CENTER", 0, -12 ); 			
					loses:SetPoint( "CENTER", self.frame:GetName() .. "ArenaRecords" .. ( i - 1 ) .. "Loses", "CENTER", 0, -12 ); 			
					perct:SetPoint( "CENTER", self.frame:GetName() .. "ArenaRecords" .. ( i - 1 ) .. "Perct", "CENTER", 0, -12 ); 
				else
					arenaName:SetPoint( "TOPLEFT", self.arenaText, "TOPLEFT", 0, -18 ); 			
					wins:SetPoint( "CENTER", self.arenaWinText, "CENTER", 0, -18 ); 			
					loses:SetPoint( "CENTER", self.arenaLoseText, "CENTER", 0, -18 ); 			
					perct:SetPoint( "CENTER", self.arenaPerctText, "CENTER", 0, -18 ); 			
					rated:SetPoint( "CENTER", self.ratedText, "CENTER", 0, -18 ); 
					bracket:SetPoint( "CENTER", self.bracketText, "CENTER", 0, -18 ); 
				end
			end
			
			lastCategory = arenaName;

			frame:Show();
			
			arenaName:SetText( info.location );
			wins:SetText( info.wins );
			loses:SetText( info.loses );
			
			if( info.perct > 0 ) then
				perct:SetText( string.format( "%.1f%%", info.perct * 100 ) );
			else
				perct:SetText( "--" );
			end
			
			bracket:SetText( info.teamSize );
			
			if( info.rated ) then
				rated:SetText( L["R"] );
			else
				rated:SetText( L["S"] );
			end
		end
	else
		self.arenaText:Hide();
		self.arenaPerctText:Hide();
		self.arenaWinText:Hide();
		self.arenaLoseText:Hide();
		self.ratedText:Hide();
		self.bracketText:Hide();
	end
end

function Honest:PVPFrame_Update()
	PVPHonorTodayHonor:SetText( Honest.db.profile.today.totals.total );
	
	if( not PVPFrame:IsShown() ) then
		return;
	end
	
	local self = Honest;
	if( not self.frame ) then
		self.frame = CreateFrame( "Frame", "HonestDetails", PVPFrame );
		self.frame:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
					edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
					tile = true,
					tileSize = 9,
					edgeSize = 9,
					insets = { left = 2, right = 2, top = 2, bottom = 2 } });	

		self.frame:SetBackdropColor( 0, 0, 0, 0.90 );
		self.frame:SetBackdropBorderColor( 0.75, 0.75, 0.75, 0.90 );
		self.frame:SetFrameStrata( "LOW" );
		
		self.frame:SetClampedToScreen( true );
		self.frame:SetPoint( "TOPLEFT", PVPFrame, "TOPRIGHT", -10, -12 );
		--self.frame:SetPoint( "CENTER", UIParent, "CENTER", 0, 80 );		
		
		self.frame:SetHeight( 400 );
		self.frame:SetWidth( 340 );
		self.frame:Show();

		-- For viewing today/yesterday honor
		self.todayView = CreateFrame( "Button", self.frame:GetName() .. "ViewToday", self.frame, "UIPanelButtonGrayTemplate" );
		self.todayView:SetPoint( "BOTTOMLEFT", self.frame, "BOTTOMLEFT", 1, 2 );
		self.todayView:SetText( L["View Today"] );
		self.todayView:SetHeight( 16 );
		self.todayView:SetWidth( 110 );
		self.todayView:SetFont( ( self.todayView:GetFont() ), 11 );
		self.todayView:SetScript( "OnClick", function() Honest:UpdateHonorUI( "today" ); end );

		self.yesterdayView = CreateFrame( "Button", self.frame:GetName() .. "ViewYesterday", self.frame, "UIPanelButtonGrayTemplate" );
		self.yesterdayView:SetPoint( "BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -1, 2 );
		self.yesterdayView:SetText( L["View Yesterday"] );
		self.yesterdayView:SetHeight( 16 );
		self.yesterdayView:SetWidth( 110 );
		self.yesterdayView:SetFont( ( self.yesterdayView:GetFont() ), 11 );
		self.yesterdayView:SetScript( "OnClick", function() Honest:UpdateHonorUI( "yesterday" ); end );

		-- Estimated text
		self.estimateText = self.frame:CreateFontString( self.frame:GetName() .. "Estimate", "BACKGROUND" );
		self.estimateText:SetFontObject( GameFontNormalSmall );
		self.estimateText:SetPoint( "TOPLEFT", self.frame, "TOPLEFT", 5, -8 );
		self.estimateText:Show();
		
		-- Kill honor
		self.killText = self.frame:CreateFontString( self.frame:GetName() .. "KillTotal", "BACKGROUND" );
		self.killText:SetFontObject( GameFontNormalSmall );
		self.killText:ClearAllPoints();
		self.killText:SetPoint( "TOPLEFT", self.frame, "TOPLEFT", 5, -30 );
		self.killText:Show();

		-- BATTLEGROUND STATS
		-- Bonus honor
		self.bonusText = self.frame:CreateFontString( self.frame:GetName() .. "BonusTotal", "BACKGROUND" );
		self.bonusText:SetFontObject( GameFontNormalSmall );
		self.bonusText:ClearAllPoints();
		self.bonusText:SetPoint( "TOPRIGHT", self.frame, "TOPRIGHT", -5, -30 );
		self.bonusText:Show();
		
		
		-- Battlefield name
		self.battlefieldText = self.frame:CreateFontString( self.frame:GetName() .. "BattlefieldName", "BACKGROUND" );
		self.battlefieldText:SetFontObject( GameFontNormalSmall );
		self.battlefieldText:SetText( L["Battlefield"] );
		self.battlefieldText:Show();

		-- Average
		self.avgText = self.frame:CreateFontString( self.frame:GetName() .. "AverageText", "BACKGROUND" );
		self.avgText:SetFontObject( GameFontNormalSmall );
		self.avgText:SetText( L["Avg Honor"] );
		self.avgText:SetPoint( "TOPLEFT", self.battlefieldText, "TOPRIGHT", 85, 0 );
		self.avgText:Show();

		-- Perct
		self.perctText = self.frame:CreateFontString( self.frame:GetName() .. "PerctText", "BACKGROUND" );
		self.perctText:SetFontObject( GameFontNormalSmall );
		self.perctText:SetText( L["Perct"] );
		self.perctText:SetPoint( "TOPLEFT", self.avgText, "TOPRIGHT", 15, 0 );
		self.perctText:Show();
		
		-- Wins
		self.winText = self.frame:CreateFontString( self.frame:GetName() .. "WinText", "BACKGROUND" );
		self.winText:SetFontObject( GameFontNormalSmall );
		self.winText:SetText( L["Wins"] );
		self.winText:SetPoint( "TOPLEFT", self.perctText, "TOPRIGHT", 15, 0 );
		self.winText:Show();

		-- Loses
		self.loseText = self.frame:CreateFontString( self.frame:GetName() .. "LoseText", "BACKGROUND" );
		self.loseText:SetFontObject( GameFontNormalSmall );
		self.loseText:SetText( L["Loses"] );
		self.loseText:SetPoint( "TOPLEFT", self.winText, "TOPRIGHT", 15, 0 );
		self.loseText:Show();
		
		-- ARENA STATS
		-- Arena name
		self.arenaText = self.frame:CreateFontString( self.frame:GetName() .. "ArenaName", "BACKGROUND" );
		self.arenaText:SetFontObject( GameFontNormalSmall );
		self.arenaText:SetText( L["Arena"] );
		self.arenaText:Show();

		-- Bracket
		self.bracketText = self.frame:CreateFontString( self.frame:GetName() .. "BracketText", "BACKGROUND" );
		self.bracketText:SetFontObject( GameFontNormalSmall );
		self.bracketText:SetText( L["Bracket"] );
		self.bracketText:SetPoint( "TOPLEFT", self.arenaText, "TOPRIGHT", 85, 0 );
		self.bracketText:Show();

		-- Rated
		self.ratedText = self.frame:CreateFontString( self.frame:GetName() .. "RatedText", "BACKGROUND" );
		self.ratedText:SetFontObject( GameFontNormalSmall );
		self.ratedText:SetText( L["Type"] );
		self.ratedText:SetPoint( "TOPLEFT", self.bracketText, "TOPRIGHT", 15, 0 );
		self.ratedText:Show();

		-- Perct
		self.arenaPerctText = self.frame:CreateFontString( self.frame:GetName() .. "ArenaPerctText", "BACKGROUND" );
		self.arenaPerctText:SetFontObject( GameFontNormalSmall );
		self.arenaPerctText:SetText( L["Perct"] );
		self.arenaPerctText:SetPoint( "TOPLEFT", self.ratedText, "TOPRIGHT", 15, 0 );
		self.arenaPerctText:Show();
		
		-- Wins
		self.arenaWinText = self.frame:CreateFontString( self.frame:GetName() .. "ArenaWinText", "BACKGROUND" );
		self.arenaWinText:SetFontObject( GameFontNormalSmall );
		self.arenaWinText:SetText( L["Wins"] );
		self.arenaWinText:SetPoint( "TOPLEFT", self.arenaPerctText, "TOPRIGHT", 15, 0 );
		self.arenaWinText:Show();

		-- Loses
		self.arenaLoseText = self.frame:CreateFontString( self.frame:GetName() .. "ArenaLoseText", "BACKGROUND" );
		self.arenaLoseText:SetFontObject( GameFontNormalSmall );
		self.arenaLoseText:SetText( L["Loses"] );
		self.arenaLoseText:SetPoint( "TOPLEFT", self.arenaWinText, "TOPRIGHT", 15, 0 );
		self.arenaLoseText:Show();
	end
	
	Honest:UpdateHonorUI( "today" );
end
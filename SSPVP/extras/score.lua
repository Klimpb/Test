local Score = SSPVP:NewModule( "SSPVP-Score" );
Score.activeIn = "bf";

local L = SSPVPLocals;
local enemies = {};
local friendlies = {};

local Orig_WSSF_OnShow;

function Score:Initialize()
	hooksecurefunc( "WorldStateScoreFrame_Update", self.WorldStateScoreFrame_Update );

	WorldStateScoreFrame:HookScript( "OnShow", self.CreateInfoButtons );
	WorldStateScoreFrame:HookScript( "OnHide", self.ResetScoreFaction );
	
	SSOverlay:AddCategory( "fact", L["Faction Balance"], 0 );
end

function Score:EnableModule()
	self:RegisterEvent( "PLAYER_TARGET_CHANGED" );
	self:RegisterEvent( "UPDATE_MOUSEOVER_UNIT" );
	self:RegisterEvent( "RAID_ROSTER_UPDATE" );
	self:RegisterEvent( "UPDATE_BATTLEFIELD_SCORE" );
end

function Score:DisableModule()
	self:UnregisterAllEvents();
	SSOverlay:RemoveCategory( "fact" );
end

function Score:Reload()
	if( not SSPVP.db.profile.general.factBalance ) then
		SSOverlay:RemoveCategory( "fact" );
	end
	
	Score:RAID_ROSTER_UPDATE();
	Score:UPDATE_BATTLEFIELD_SCORE();
end

function Score:ResetScoreFaction()
	SetBattlefieldScoreFaction( nil );
end

function Score:RAID_ROSTER_UPDATE()
	if( not SSPVP.db.profile.score.level ) then
		return;
	end
	
	for i=1, GetNumRaidMembers() do
		local name, server = UnitName( "raid" .. i );
		
		if( server ) then
			friendlies[ name .. "-" .. server ] = UnitLevel( "raid" .. i );
		else
			friendlies[ name ] = UnitLevel( "raid" .. i );
		end
	end
end

function Score:UPDATE_BATTLEFIELD_SCORE()
	if( not SSPVP.db.profile.general.factBalance ) then
		return;
	end
	
	local faction;
	local alliance = 0;
	local horde = 0;
	
	for i=1, GetNumBattlefieldScores() do
		_, _, _, _, _, faction, _, _, _, classToken = GetBattlefieldScore( i );
		
		if( faction == 0 ) then
			horde = horde + 1;
		elseif( faction == 1 ) then
			alliance = alliance + 1;
		end
	end
	
	if( ( alliance == SSPVP:MaxBattlefieldPlayers() and horde == SSPVP:MaxBattlefieldPlayers() ) or ( alliance == 0 and horde == 0 ) ) then
		SSOverlay:RemoveCategory( "fact" );
		return;
	end
	
	SSOverlay:UpdateText( "fact", L["Alliance: %d"], SSOverlay:GetFactionColor( "Alliance" ), alliance );
	SSOverlay:UpdateText( "fact", L["Horde: %d"], SSOverlay:GetFactionColor( "Horde" ), horde );
end

function Score:UPDATE_MOUSEOVER_UNIT()
	if( SSPVP.db.profile.score.level ) then
		self:CheckUnit( "mouseover" );
	end
end

function Score:PLAYER_TARGET_CHANGED()
	if( SSPVP.db.profile.score.level ) then
		self:CheckUnit( "target" );
	end
end

function Score:CheckUnit( unit )
	if( UnitIsEnemy( unit, "player" ) and UnitIsPVP( unit ) and UnitIsPlayer( unit ) ) then	
		local name, server = UnitName( unit );
		if( server ) then
			enemies[ name .. "-" .. server ] = UnitLevel( unit );
		else
			enemies[ name ] = UnitLevel( unit );
		end
	end	
end

function Score:CreateFactionInfo( faction )
	local factionColor, factionID;
	if( faction == "Alliance" ) then
		factionColor = "|cff0070dd";
		factionID = 1;

	elseif( faction == "Horde" ) then
		factionColor = RED_FONT_COLOR_CODE;
		factionID = 0;
	end
	
	local serverCount = {};
	local classCount = {};
	local totalPlayers = 0;
	
	local name, playerFaction, class, found;
	
	for i=1, GetNumBattlefieldScores() do
		name, _, _, _, _, playerFaction, _, _, class = GetBattlefieldScore( i );
		if( name and playerFaction == factionID ) then
			local server = GetRealmName();
			if( string.find( name, "%-" ) ) then
				_, _, _, server = string.find( name, "(.+)%-(.+)" );
			end

			found = nil;
			
			for id, row in pairs( serverCount ) do
				if( row.server == server ) then
					serverCount[ id ].total = row.total + 1;
					found = true;
					break;
				end
			end
			
			if( not found ) then
				table.insert( serverCount, { total = 1, server = server } );
			end
			
			found = nil;
			
			for id, row in pairs( classCount ) do
				if( row.class == class ) then
					classCount[ id ].total = row.total + 1;
					found = true;
					break;
				end
			end
			
			if( not found ) then
				table.insert( classCount, { total = 1, class = class } );
			end
			
			totalPlayers = totalPlayers + 1;
		end
	end
	
	table.sort( serverCount, function( a, b ) return a.total > b.total; end );
	table.sort( classCount, function( a, b ) return a.total > b.total; end );
	
	return serverCount, classCount, L[ faction ], factionColor, totalPlayers;
end

function Score:PrintFactionInfo( faction )
	local servers, classes, faction, _, players = self:CreateFactionInfo( faction );
	
	local minCount = 2;
	if( SSPVP:IsPlayerIn( "av" ) ) then
		minCount = 4;
	end
	
	for i=#( servers ), 1, -1 do
		if( servers[ i ].total < minCount ) then
			table.remove( servers, i );
		end
	end
	
	SSPVP:ChannelMessage( string.format( L["%s (%d players)"], faction, players ) );

	local parsedServers = {};
	for _, row in pairs( servers ) do
		table.insert( parsedServers, row.server .. ": " .. row.total );
	end
	
	SSPVP:ChannelMessage( table.concat( parsedServers, ", " ) );
	
	local parsedClasses = {};
	for _, row in pairs( classes ) do
		table.insert( parsedClasses, row.class .. ": " .. row.total );
	end
	
	SSPVP:ChannelMessage( table.concat( parsedClasses, ", " ) );
end

function Score:TooltipFactionInfo( faction )
	local servers, classes, faction, color, players = self:CreateFactionInfo( faction );
	if( players == 0 ) then
		return L["No data found"];
	end
	
	local tooltip = string.format( L["%s (%d players)"], color .. faction .. FONT_COLOR_CODE_CLOSE, players ) .. "\n\n";
	
	tooltip = tooltip .. color .. L["Server Balance"] .. FONT_COLOR_CODE_CLOSE .. "\n";
	for _, row in pairs( servers ) do
		tooltip = tooltip .. row.server .. ": " .. row.total .. "\n";
	end
	
	tooltip = tooltip .. "\n" .. color .. L["Class Balance"] .. FONT_COLOR_CODE_CLOSE .. "\n";
	for _, row in pairs( classes ) do
		tooltip = tooltip .. row.class .. ": " .. row.total .. "\n";
	end
	
	return tooltip;
end

function Score:CreateInfoButtons()
	local button;
	
	if( not PVPScoreAllianceInfo ) then
		button = CreateFrame( "Button", "PVPScoreAllianceInfo", WorldStateScoreFrame, "GameMenuButtonTemplate" );
		button:SetWidth( 50 );
		button:SetHeight( 19 );

		button:SetFont( GameFontHighlightSmall:GetFont() );

		button:SetText( L["Alliance"] );
		button:SetPoint( "TOPRIGHT", WorldStateScoreFrame, "TOPRIGHT", -190, -18 );

		button:SetScript( "OnLeave", function()
			GameTooltip:Hide();
		end );

		button:SetScript( "OnMouseUp", function()
			if( arg1 == "RightButton" ) then
				Score:PrintFactionInfo( "Alliance" );
			end
		end );

		button:SetScript( "OnEnter", function()
			GameTooltip:SetOwner( this, "ANCHOR_BOTTOMLEFT" );
			GameTooltip:SetText( Score:TooltipFactionInfo( "Alliance" ) );
			GameTooltip:Show();
		end );
	end
	
	if( not PVPScoreHordeInfo ) then
		button = CreateFrame( "Button", "PVPScoreHordeInfo", WorldStateScoreFrame, "GameMenuButtonTemplate" );
		button:SetWidth( 40 );
		button:SetHeight( 19 );

		button:SetFont( GameFontHighlightSmall:GetFont() );

		button:SetText( L["Horde"] );
		button:SetPoint( "TOPRIGHT", WorldStateScoreFrame, "TOPRIGHT", -140, -18 );

		button:SetScript( "OnLeave", function()
			GameTooltip:Hide();
		end );

		button:SetScript( "OnMouseUp", function()
			if( arg1 == "RightButton" ) then
				Score:PrintFactionInfo( "Horde" );
			end
		end );

		button:SetScript( "OnEnter", function()
			GameTooltip:SetOwner( this, "ANCHOR_BOTTOMLEFT" );
			GameTooltip:SetText( Score:TooltipFactionInfo( "Horde" ) );
			GameTooltip:Show();
		end );
	end
	
	if( Orig_WSSF_OnShow ) then
		Orig_WSSF_OnShow();
	end
end

function Score:WorldStateScoreFrame_Update()
	local index, name, classToken, nameButton, teamName, oldRating, newRating, dataFailure, isArena;

	if( select( 2, IsActiveBattlefieldArena() ) ) then
		isArena = true;
		
		for i=0, 1 do
			_, oldRating, newRating = GetBattlefieldTeamInfo( i );
			if( oldRating <= 0 or newRating <= 0 ) then
				dataFailure = true;
			end
		end
	end
	
	for i=1, MAX_WORLDSTATE_SCORE_BUTTONS do
		nameButton = getglobal( "WorldStateScoreButton" .. i .. "Name" );
		
		if( nameButton ) then
			index = FauxScrollFrame_GetOffset( WorldStateScoreScrollFrame ) + i;
			
			name, _, _, _, _, faction, _, _, _, classToken = GetBattlefieldScore( index );
		
			if( name ) then
				local nameText = getglobal( "WorldStateScoreButton" .. i .. "Name" );

				if( SSPVP.db.profile.score.icon ) then
					getglobal( "WorldStateScoreButton" .. i .. "ClassButtonIcon" ):Hide();
				end

				if( SSPVP.db.profile.score.color and RAID_CLASS_COLORS[ classToken ] and name ~= UnitName( "player" ) ) then
					nameText:SetVertexColor( RAID_CLASS_COLORS[ classToken ].r, RAID_CLASS_COLORS[ classToken ].g, RAID_CLASS_COLORS[ classToken ].b );
				end
				
				if( string.match( name, "-" ) ) then
					name, server = string.match( name, "(.+)%-(.+)" );
				else
					server = GetRealmName();				
				end

				nameButton:SetText( name .. " |cffffffff- " .. server .. "|r" );

				if( SSPVP.db.profile.score.level ) then
					if( enemies[ name ] ) then
						nameText:SetText( "[" .. enemies[ name ] .. "] " .. nameText:GetText() );
					elseif( friendlies[ name ] ) then
						nameText:SetText( "[" .. friendlies[ name ] .. "] " .. nameText:GetText() );
					end
				end

				if( isArena ) then
					teamName, oldRating, newRating = GetBattlefieldTeamInfo( faction );
					if( not dataFailure ) then
						getglobal( "WorldStateScoreButton" .. i .. "HonorGained" ):SetText( newRating - oldRating .. " (" .. newRating .. ")" );
					else
						getglobal( "WorldStateScoreButton" .. i .. "HonorGained" ):SetText( "----" );
					end
				end
			end
		end
	end
end
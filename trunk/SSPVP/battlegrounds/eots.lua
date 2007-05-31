local EoTS = SSPVP:NewModule( "SSPVP-EoTS" );
EoTS.activeIn = "eots";

local L = SSPVPLocals;
local towerInfo = { [0] = 0, [1] = 0.5, [2] = 1, [3] = 2.5, [4] = 5 };

local Alliance = {};
local Horde = {};
local lowest;

local carrierName;
local carrierFaction;

local PlayerFaction;

function EoTS:Initialize()
	hooksecurefunc( "WorldStateAlwaysUpFrame_Update", self.WorldStateAlwaysUpFrame_Update );
	PlayerFaction = UnitFactionGroup( "player" );
	SSOverlay:AddCategory( "eots", L["Battlefield Info"] );
end

function EoTS:EnableModule()
	self:RegisterEvent( "UPDATE_BATTLEFIELD_SCORE", "UpdateCarrier" );
	self:RegisterEvent( "UPDATE_WORLD_STATES", "UpdateOverlay" );
	self:RegisterEvent( "CHAT_MSG_BG_SYSTEM_HORDE", "HordeFlag" );
	self:RegisterEvent( "CHAT_MSG_BG_SYSTEM_ALLIANCE", "AllianceFlag" );
	
	self:CreateCarrierButtons();
end

function EoTS:DisableModule()
	
	Alliance = {};
	Horde = {};
	
	carrierName = nil;
	carrierFaction = nil;

	self:UnregisterAllMessages();
	self:UnregisterAllEvents();
	self:UpdateCarrierAttributes();

	SSOverlay:RemoveCategory( "eots" );
end

function EoTS:Reload()
	if( not self.allianceButton or not self.hordeButton ) then
		return;
	end
	
	if( not SSPVP.db.profile.eots.carriers ) then
		carrierName = nil;
		carrierFaction = nil;
		
		if( self.allianceButton and self.hordeButton ) then
			self:UpdateCarrierAttributes();
		end
	end

	self:SetCarrierBorders();

	SSOverlay:RemoveCategory( "eots" );
	self:UpdateOverlay();
end

function EoTS:HordeFlag( event, msg )
	self:ParseFlag( msg, "Horde" );
end

function EoTS:AllianceFlag( event, msg )
	self:ParseFlag( msg, "Alliance" );
end

function EoTS:ParseFlag( msg, faction )
	if( string.find( msg, L["(.+) has taken the flag!"] ) ) then
		_, _, carrierName = string.find( msg, L["(.+) has taken the flag!"] );
		carrierFaction = faction;
		
		self:UpdateCarrier();

	elseif( string.find( msg, L["The (.+) have captured the flag!"] ) ) then
		if( faction == "Alliance" ) then
			Alliance.captures = ( Alliance.captures or 0 ) + 1;
			
			if( SSPVP.db.profile.eots.totalCaptures ) then
				SSOverlay:UpdateText( "eots", L["Flag Captures: %d"], SSOverlay:GetFactionColor( "Alliance" ), Alliance.captures );
			end
		elseif( faction == "Horde" ) then
			Horde.captures = ( Horde.captures or 0 ) + 1;

			if( SSPVP.db.profile.eots.totalCaptures ) then
				SSOverlay:UpdateText( "eots", L["Flag Captures: %d"], SSOverlay:GetFactionColor( "Horde" ), Horde.captures );
			end
		end
		
		if( SSPVP.db.profile.eots.respawn ) then
			SSOverlay:UpdateTimer( "eots", L["Flag Respawn: %s"], 10, SSOverlay:GetFactionColor( "Neutral" ) );
		end

		carrierName = nil;
		carrierFaction = nil;
		
		self:UpdateCarrier();
	elseif( string.find( msg, L["The flag has been dropped"] ) ) then
		carrierName = nil;
		carrierFaction = nil;
		
		self:UpdateCarrier();
	end
end

function EoTS:UpdateCarrierAttributes()
	if( InCombatLockdown() ) then
		self.hordeText:SetAlpha( 0.75 );
		self.allianceText:SetAlpha( 0.75 );
				
		SSPVP:RegisterOOCUpdate( EoTS, "UpdateCarrierAttributes" );
		return;
	end
	
	if( carrierFaction == "Alliance" ) then
		self.allianceButton:SetAttribute( "type", "macro" );
		self.allianceButton:SetAttribute( "macrotext", "/target " .. carrierName );
		self.allianceButton:Show();

		self.hordeText:SetAlpha( 1 );
		self.hordeText.colorSet = nil;
		self.hordeButton:Hide();

	elseif( carrierFaction == "Horde" ) then
		self.hordeButton:SetAttribute( "type", "macro" );
		self.hordeButton:SetAttribute( "macrotext", "/target " .. carrierName );
		self.hordeButton:Show();

		self.allianceText:SetAlpha( 1 );
		self.allianceText.colorSet = nil;
		self.allianceButton:Hide();
	else
		self.allianceText.colorSet = nil;
		self.hordeText.colorSet = nil;
		
		self.allianceButton.positionSet = nil;
		self.hordeButton.positionSet = nil;

		self.allianceButton:Hide();
		self.hordeButton:Hide();
	end
end

function EoTS:UpdateCarrier()
	if( not carrierName or not SSPVP.db.profile.eots.carriers ) then
		self:UpdateCarrierAttributes();
		return;
	end

	self:UpdateCarrierAttributes();
	
	local button, text;
	if( carrierFaction == "Alliance" ) then
		button = self.allianceButton;
		text = self.allianceText;
		
		if( not button.positionSet ) then
			button.positionSet = true;

			button:ClearAllPoints();
			button:SetPoint( "LEFT", UIParent, "BOTTOMLEFT", AlwaysUpFrame1Text:GetRight() + 5, AlwaysUpFrame1Text:GetTop() - 5 );

			text:ClearAllPoints();
			text:SetPoint( "LEFT", UIParent, "BOTTOMLEFT", AlwaysUpFrame1Text:GetRight() + 5, AlwaysUpFrame1Text:GetTop() - 5 );
		end
	elseif( carrierFaction == "Horde" ) then
		button = self.hordeButton;
		text = self.hordeText;
		
		if( not button.positionSet ) then
			button.positionSet = true;

			button:ClearAllPoints();
			button:SetPoint( "LEFT", UIParent, "BOTTOMLEFT", AlwaysUpFrame2Text:GetRight() + 5, AlwaysUpFrame2Text:GetTop() - 5 );

			text:ClearAllPoints();
			text:SetPoint( "LEFT", UIParent, "BOTTOMLEFT", AlwaysUpFrame2Text:GetRight() + 5, AlwaysUpFrame2Text:GetTop() - 5 );
		end
	end
	
	text:SetText( carrierName );
	
	if( not text.colorSet and SSPVP.db.profile.eots.color ) then
		local name, classToken;
		for i=1, GetNumBattlefieldScores() do
			name, _, _, _, _, _, _, _, _, classToken = GetBattlefieldScore( i );

			if( string.find( name, "^" .. carrierName ) ) then
				text:SetTextColor( RAID_CLASS_COLORS[ classToken ].r, RAID_CLASS_COLORS[ classToken ].g, RAID_CLASS_COLORS[ classToken ].b );	
				text.colorSet = true;
				break;
			end
		end
	end
	
	if( not text.colorSet ) then
		text:SetTextColor( GameFontNormal:GetTextColor() );
	end
end	

function EoTS:UpdateOverlay()
	if( not SSPVP.db.profile.eots.overlay ) then
		SSOverlay:RemoveCategory( "eots" );
		return;
	end
	
	local towers, points, enemy, friendly;
	local _, _, allianceText = GetWorldStateUIInfo( 2 );
	local _, _, hordeText = GetWorldStateUIInfo( 3 );
	
	_, _, towers, points = string.find( allianceText, L["Bases: ([0-9]+)  Victory Points: ([0-9]+)%/2000"] );
	Alliance.towers = tonumber( towers );
	Alliance.points = tonumber( points );
	Alliance.left = 2000 - points;

	Alliance.time = Alliance.left / towerInfo[ Alliance.towers ];
	Alliance.towersWin = 0;
	
	_, _, towers, points = string.find( hordeText, L["Bases: ([0-9]+)  Victory Points: ([0-9]+)%/2000"] );
	Horde.towers = tonumber( towers );
	Horde.points = tonumber( points );
	Horde.left = 2000 - points;
	Horde.time = Horde.left / towerInfo[ Horde.towers ];
	Horde.towersWin = 0;
	
	if( Horde.points == 0 and Alliance.points == 0 ) then
		return;
	end

	if( Alliance.time < Horde.time ) then
		lowest = Alliance.time;
	else
		lowest = Horde.time;
	end
	
	if( SSPVP.db.profile.eots.timeLeft ) then
		SSOverlay:UpdateTimer( "eots", L["Time Left: %s"], lowest, SSOverlay:GetFactionColor() );
	end
	
	Alliance.final = Alliance.points + floor( lowest * towerInfo[ Alliance.towers ] + 0.5 );
	Horde.final = Horde.points + floor( lowest * towerInfo[ Horde.towers ] + 0.5 );
	
	if( SSPVP.db.profile.eots.finalScore ) then
		SSOverlay:UpdateText( "eots", L["Final Score: %d"], SSOverlay:GetFactionColor( "Alliance" ), Alliance.final );
		SSOverlay:UpdateText( "eots", L["Final Score: %d"], SSOverlay:GetFactionColor( "Horde" ), Horde.final );
	end
	
	if( UnitFactionGroup( "player" ) == "Alliance" ) then
		enemy = Horde;
		friendly = Alliance;
	else
		enemy = Alliance;
		friendly = Horde;
	end
	
	if( SSPVP.db.profile.eots.captureWin ) then
		SSOverlay:UpdateText( "eots", L["Captures to win: %d"], SSOverlay:GetFactionColor(), ceil( friendly.left / 75 ) );
	end
	
	local enemytime, friendlyTime, enemyFinal, friendlyFinal, allianceScore, hordeScore;
	
	for i=1, 4 do
		enemyTime = enemy.left / towerInfo[ 4 - i ];
		friendlyTime = friendly.left / towerInfo[ i ];
		if( enemyTime < friendlyTime ) then
			lowest = enemyTime;
		else
			lowest = friendlyTime;
		end
		
		enemyFinal = enemy.points + floor( lowest * towerInfo[ 4 - i ] + 0.5 );
		friendlyFinal = friendly.points + floor( lowest * towerInfo[ i ] + 0.5 );
		
		if( friendlyFinal >= 2000 and enemyFinal < 2000 ) then
			Alliance.towersWin = i;
			Horde.towersWin = i;
			
			if( SSPVP.db.profile.eots.towersWin ) then
				if( not SSPVP.db.profile.eots.towersScore ) then
					SSOverlay:UpdateText( "eots", L["Towers to win: %d"], SSOverlay:GetFactionColor(), i );
				else
					if( PlayerFaction == "Alliance" ) then
						allianceScore = friendlyFinal;
						hordeScore = enemyFinal;
					else
						allianceScore = enemyFinal;
						hordeScore = friendlyFinal;
					end
					
					SSOverlay:UpdateText( "eots", L["Towers to win: %d (A:%d/H:%d)"], SSOverlay:GetFactionColor(), i, allianceScore, hordeScore );
				end
			end
			break;
		end
	end
end

function EoTS:WorldStateAlwaysUpFrame_Update()
	local bases, points;
	
	if( AlwaysUpFrame1 ) then
		local alliance = getglobal( "AlwaysUpFrame1Text" );
		_, _, bases, points = string.find( alliance:GetText(), L["Bases: ([0-9]+)  Victory Points: ([0-9]+)%/2000"] );
		
		if( bases and points ) then
			alliance:SetText( string.format( L["Bases %d  Points %d/2000"], bases, points ) );
		end
	end
	
	if( AlwaysUpFrame2 ) then
		local horde = getglobal( "AlwaysUpFrame2Text" );
		_, _, bases, points = string.find( horde:GetText(), L["Bases: ([0-9]+)  Victory Points: ([0-9]+)%/2000"] );

		if( bases and points ) then
			horde:SetText( string.format( L["Bases %d  Points %d/2000"], bases, points ) );
		end
	end
end

function EoTS:SetCarrierBorders()
	if( SSPVP.db.profile.eots.border ) then
		self.allianceText:SetFont( GameFontNormal:GetFont(), 11, "OUTLINE" );
		self.hordeText:SetFont( GameFontNormal:GetFont(), 11, "OUTLINE" );
	else
		self.allianceText:SetFont( GameFontNormal:GetFont(), 11, nil );
		self.hordeText:SetFont( GameFontNormal:GetFont(), 11, nil );
	end
end

function EoTS:CreateCarrierButtons()
	-- Create flag carrier buttons if required
	if( not self.allianceButton ) then
		self.allianceButton = CreateFrame( "Button", "EoTSFlagAlliance", UIParent, "SecureActionButtonTemplate" );
		self.allianceButton:SetHeight( 25 );
		self.allianceButton:SetWidth( 150 );
		self.allianceButton:SetScript( "PostClick", function()
			if( IsAltKeyDown() and carrierName ) then
				SSPVP:ChannelMessage( string.format( L["Alliance flag carrier %s"], carrierName ) );
			end
		end );

		self.allianceText = self.allianceButton:CreateFontString( self.allianceButton:GetName() .. "Text", "BACKGROUND" );
		self.allianceText:SetJustifyH( "LEFT" );
		self.allianceText:SetHeight( 25 );
		self.allianceText:SetWidth( 150 );
	end
	
	if( not self.hordeButton ) then
		self.hordeButton = CreateFrame( "Button", "EoTSFlagHorde", UIParent, "SecureActionButtonTemplate" );
		self.hordeButton:SetHeight( 25 );
		self.hordeButton:SetWidth( 150 );
		self.hordeButton:SetScript( "PostClick", function()
			if( IsAltKeyDown() and carrierName ) then
				SSPVP:ChannelMessage( string.format( L["Horde flag carrier %s"], carrierName ) );
			end
		end );

		self.hordeText = self.hordeButton:CreateFontString( self.hordeButton:GetName() .. "Text", "BACKGROUND" );
		self.hordeText:SetJustifyH( "LEFT" );
		self.hordeText:SetHeight( 25 );
		self.hordeText:SetWidth( 150 );
	end
	
	self:SetCarrierBorders();
end
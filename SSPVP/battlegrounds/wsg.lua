local WSG = SSPVP:NewModule( "SSPVP-WSG" );
WSG.activeIn = "wsg";

local L = SSPVPLocals;

local carrierNames = {};
local carrierTimes = {};
local dataSent = {};
local friendlyUnit;

local EnemyFaction;
local FriendlyFaction;

function WSG:Initialize()
	SSOverlay:AddCategory( "wsg", L["Timers"] );

	if( UnitFactionGroup( "player" ) == "Alliance" ) then
		EnemyFaction = "Horde";
		FriendlyFaction = "Alliance";
	else
		EnemyFaction = "Alliance";
		FriendlyFaction = "Horde";
	end
end

function WSG:EnableModule()
	self:RegisterEvent( "UPDATE_BATTLEFIELD_SCORE", "UpdateCarriers" );
	self:RegisterEvent( "CHAT_MSG_BG_SYSTEM_HORDE", "ParseMessage" );
	self:RegisterEvent( "CHAT_MSG_BG_SYSTEM_ALLIANCE", "ParseMessage" );
	self:RegisterEvent( "UNIT_HEALTH" );
	self:RegisterEvent( "UPDATE_BINDINGS", "UpdateCarrierBindings" );
	
	self:RegisterMessage( "SS_CARRIERS_REQ", "SendCarriers" );
	self:RegisterMessage( "SS_CARRIERS_DATA", "CarrierData" );
	
	self:CreateCarrierButtons();
	self:UpdateCarrierBindings();
	
	PVPSync:SendMessage( "CARRIERS" );
end

function WSG:DisableModule()
	SSOverlay:RemoveCategory( "wsg" );

	carrierNames = {};
	carrierTimes = {};
	
	self:UnregisterAllMessages();
	self:UnregisterAllEvents();
	self:UpdateCarriersAttributes();
end

function WSG:Reload()
	WSG:SetCarrierBorders();
	if( self.allianceText and self.hordeText ) then
		WSG:UpdateCarriers();
	end
	
	if( SSPVP.db.profile.wsg.carriers and SSPVP:IsPlayerIn( "wsg" ) ) then
		PVPSync:SendMessage( "CARRIERS" );
	end
	
	if( SSPVP.db.profile.wsg.flagElapsed ) then
		for faction, time in pairs( carrierTimes ) do
			SSOverlay:UpdateElapsed( "wsg", L["Time Elapsed: %s"], GetTime() - time, SSOverlay:GetFactionColor( faction ) );
		end
	else
		SSOverlay:RemoveRow( "text", "wsg", L["Time Elapsed: %s"] );
	end
	
	if( not SSPVP.db.profile.wsg.flagCapTime ) then
		SSOverlay:RemoveRow( "text", "wsg", L["Capture Time: %s"] );
	end
end

local Orig_SendChatMessage = SendChatMessage
function SendChatMessage( text, type, language, targetPlayer )
	if( text and SSPVP:IsPlayerIn( "wsg" ) ) then
		if( carrierNames[ EnemyFaction ] ) then
			text = string.gsub( text, "$ffc", carrierNames[ EnemyFaction ] );
			text = string.gsub( text, "$ftc", SSOverlay:FormatTime( GetTime() - carrierTimes[ EnemyFaction ], "minsec" ) );
		end

		if( carrierNames[ FriendlyFaction ] ) then
			text = string.gsub( text, "$efc", carrierNames[ FriendlyFaction ] );
			text = string.gsub( text, "$etc", SSOverlay:FormatTime( GetTime() - carrierTimes[ FriendlyFaction ], "minsec" ) );
		end
	end
	
	return Orig_SendChatMessage( text, type, language, targetPlayer );
end

function WSG:SendCarriers()
	if( not SSPVP.db.profile.wsg.carriers ) then
		return;
	end

	PVPSync:SendMessage( "CARRIERS:A:" .. ( carrierNames["Alliance"] or "" ) .. ",H:" .. ( carrierNames["Horde"] or "" ), "GUILD" );	
end

function WSG:CarrierData( event, ... )
	if( not SSPVP.db.profile.wsg.carriers ) then
		return;
	end

	local factionAbbrev, name;
	
	for i=1, select( "#", ... ) do
		factionAbbrev, name = string.split( ":", ( select( i, ... ) ) );
		
		if( name ~= "" ) then
			if( factionAbbrev == "A" ) then
				carrierNames["Alliance"] = name;
			elseif( factionAbbrev == "H" ) then
				carrierNames["Horde"] = name;
			end
		end
	end
end

function WSG:ParseMessage( event, msg )
	if( not SSPVP.db.profile.wsg.carriers ) then
		return;
	end
	
	local faction;
	if( string.find( msg, L["Alliance"] ) ) then
		faction = "Alliance";
	elseif( string.find( msg, L["Horde"] ) ) then
		faction = "Horde";
	end
	
	if( string.find( msg, L["was picked up by (.+)!"] ) ) then
		local name = string.match( msg, L["was picked up by (.+)!"] );
		
		carrierNames[ faction ] = name;
		self:UpdateCarrier( faction );
		
		if( not carrierTimes[ faction ] ) then
			carrierTimes[ faction ] = GetTime();

			if( SSPVP.db.profile.wsg.flagElapsed ) then
				SSOverlay:UpdateElapsed( "wsg", L["Time Elapsed: %s"], 1, SSOverlay:GetFactionColor( faction ) );
			end
		end

	elseif( string.find( msg, L["(.+) captured the"] ) ) then
		if( SSPVP.db.profile.wsg.flagCapTime and carrierTimes[ faction ] ) then
			SSOverlay:UpdateText( "wsg", L["Capture Time: %s"], SSOverlay:GetFactionColor( faction ), SSOverlay:FormatTime( GetTime() - carrierTimes[ faction ], "minsec" ) );
		end

		carrierNames[ faction ] = nil;
		carrierTimes[ faction ] = nil;
		
		self:UpdateCarrier( faction );
		
		SSOverlay:RemoveRow( "elapsed", "wsg", L["Time Elapsed: %s"], SSOverlay:GetFactionColor( faction ) );
		
		if( SSPVP.db.profile.wsg.respawn ) then
			SSOverlay:UpdateTimer( "wsg", L["Flag Respawn: %s"], 23, SSOverlay:GetFactionColor( faction ) );
		end

	elseif( string.find( msg, L["was dropped by (.+)!"] ) ) then
		carrierNames[ faction ] = nil;
		self:UpdateCarrier( faction );

	elseif( string.find( msg, L["was returned to its base"] ) ) then
		SSOverlay:RemoveRow( "elapsed", "wsg", L["Time Elapsed: %s"], SSOverlay:GetFactionColor( faction ) );

		if( SSPVP.db.profile.wsg.flagCapTime and carrierTimes[ faction ] ) then
			SSOverlay:UpdateText( "wsg", L["Capture Time: %s"], SSOverlay:GetFactionColor( faction ), SSOverlay:FormatTime( GetTime() - carrierTimes[ faction ], "minsec" ) );
		end
		
		carrierTimes[ faction ] = nil;
	end
end

function WSG:UpdateCarriersAttributes()
	WSG:UpdateCarrierAttributes( "Alliance" );
	WSG:UpdateCarrierAttributes( "Horde" );
end

function WSG:UpdateCarrierAttributes( faction )
	if( InCombatLockdown() ) then
		if( faction == "Alliance" ) then
			if( self.allianceButton.carrierName ~= carrierNames[ faction ] ) then
				self.allianceText:SetAlpha( 0.75 );
				self.allianceText.colorSet = nil;
			end
		else
			if( self.hordeButton.carrierName ~= carrierNames[ faction ] ) then
				self.hordeText:SetAlpha( 0.75 );
				self.hordeText.colorSet = nil;
			end
		end
		
		SSPVP:RegisterOOCUpdate( WSG, "UpdateCarriersAttributes" );
		return;
	end
	
	if( faction == "Alliance" ) then
		if( carrierNames[ faction ] ) then
			self.allianceButton:SetAttribute( "type", "macro" );
			self.allianceButton:SetAttribute( "macrotext", "/target " .. carrierNames[ faction ] );
			self.allianceButton.carrierName = carrierNames[ faction ]
			self.allianceButton:Show();

			self.allianceButton:ClearAllPoints();
			self.allianceButton:SetPoint( "LEFT", UIParent, "BOTTOMLEFT", AlwaysUpFrame2DynamicIconButton:GetRight() + 5, AlwaysUpFrame2DynamicIconButton:GetTop() - 14 );

			self.allianceText:ClearAllPoints();
			self.allianceText:SetPoint( "LEFT", UIParent, "BOTTOMLEFT", AlwaysUpFrame2DynamicIconButton:GetRight() + 5, AlwaysUpFrame2DynamicIconButton:GetTop() - 14 );
			
			self.allianceText:SetAlpha( 1.0 );
		else
			self.allianceText.colorSet = nil;
			self.allianceButton.carrierName = nil
			self.allianceButton:Hide();
		end
		
	else
		if( carrierNames[ faction ] ) then
			self.hordeButton:SetAttribute( "type", "macro" );
			self.hordeButton:SetAttribute( "macrotext", "/target " .. carrierNames[ faction ] );
			self.hordeButton.carrierName = carrierNames[ faction ]
			self.hordeButton:Show();

			self.hordeButton:ClearAllPoints();
			self.hordeButton:SetPoint( "LEFT", UIParent, "BOTTOMLEFT", AlwaysUpFrame1DynamicIconButton:GetRight() + 5, AlwaysUpFrame1DynamicIconButton:GetTop() - 14 );

			self.hordeText:ClearAllPoints();
			self.hordeText:SetPoint( "LEFT", UIParent, "BOTTOMLEFT", AlwaysUpFrame1DynamicIconButton:GetRight() + 5, AlwaysUpFrame1DynamicIconButton:GetTop() - 14 );
			
			self.hordeText:SetAlpha( 1.0 );
		else
			self.hordeText.colorSet = nil;
			self.hordeButton.carrierName = nil
			self.hordeButton:Hide();
		end
	end
end

function WSG:UpdateCarriers()
	self:UpdateCarrier( "Alliance" );
	self:UpdateCarrier( "Horde" );
end

function WSG:UpdateCarrier( faction )
	if( not carrierNames[ faction ] or not SSPVP.db.profile.wsg.carriers ) then
		self:UpdateCarrierAttributes( faction );
		return;
	end

	self:UpdateCarrierAttributes( faction );
	
	local button, text;
	if( faction == "Alliance" ) then
		button = self.allianceButton;
		text = self.allianceText;
	elseif( faction == "Horde" ) then
		button = self.hordeButton;
		text = self.hordeText;
	end
	
	if( EnemyFaction == faction and friendlyUnit and UnitName( friendlyUnit ) == carrierNames[ faction ] ) then
		text:SetText( carrierNames[ faction ] .. " [" .. floor( ( UnitHealth( friendlyUnit ) / UnitHealthMax( friendlyUnit ) * 100 ) + 0.5 ) .. "%]" );
	else
		text:SetText( carrierNames[ faction ] );
	end
	
	if( not text.colorSet and SSPVP.db.profile.wsg.color ) then
		local name, classToken;
		for i=1, GetNumBattlefieldScores() do
			name, _, _, _, _, _, _, _, _, classToken = GetBattlefieldScore( i );
			
			if( string.match( name, "-" ) ) then
				if( carrierNames[ faction ] == ( string.split( "-", name ) ) ) then
					text:SetTextColor( RAID_CLASS_COLORS[ classToken ].r, RAID_CLASS_COLORS[ classToken ].g, RAID_CLASS_COLORS[ classToken ].b );
					text.colorSet = true;
					break
				end
			elseif( name == carrierNames[ faction ] ) then
				text:SetTextColor( RAID_CLASS_COLORS[ classToken ].r, RAID_CLASS_COLORS[ classToken ].g, RAID_CLASS_COLORS[ classToken ].b );
				text.colorSet = true;
				break;
			end
		end
	end

	if( not text.colorSet ) then
		text:SetTextColor( GameFontHighlightSmall:GetTextColor() );
	end
end

function WSG:UpdateCarrierBindings()
	local bindKey = GetBindingKey( "ETARFLAG" );
	if( bindKey ) then
		SetOverrideBindingClick( getglobal( "WSGFlag" .. FriendlyFaction ), false, bindKey, "WSGFlag" .. FriendlyFaction );
	else
		ClearOverrideBindings( getglobal( "WSGFlag" .. FriendlyFaction ) );
	end
	
	bindKey = GetBindingKey( "FTARFLAG" );
	if( bindKey ) then
		SetOverrideBindingClick( getglobal( "WSGFlag" .. EnemyFaction ), false, bindKey, "WSGFlag" .. EnemyFaction );
	else
		ClearOverrideBindings( getglobal( "WSGFlag" .. EnemyFaction ) );
	end
end

function WSG:UNIT_HEALTH( event, unitid )
	if( SSPVP.db.profile.wsg.health and UnitName( unitid ) == carrierNames[ EnemyFaction ] ) then
		friendlyUnit = unitid;
		self[ strlower( EnemyFaction ) .. "Text" ]:SetText( carrierNames[ EnemyFaction ] .. " [" .. floor( ( UnitHealth( unitid ) / UnitHealthMax( unitid ) * 100 ) + 0.5 ) .. "%]" );
	end
end

function WSG:SetCarrierBorders()
	if( self.allianceText and self.hordeText ) then
		if( SSPVP.db.profile.wsg.border ) then
			self.allianceText:SetFont( GameFontNormal:GetFont(), 12, "OUTLINE" );
			self.hordeText:SetFont( GameFontNormal:GetFont(), 12, "OUTLINE" );
		else
			self.allianceText:SetFont( GameFontNormal:GetFont(), 12, nil );
			self.hordeText:SetFont( GameFontNormal:GetFont(), 12, nil );
		end
	end
end

function WSG:CreateCarrierButtons()
	-- Create flag carrier buttons if required
	if( not self.allianceButton ) then
		self.allianceButton = CreateFrame( "Button", "WSGFlagAlliance", UIParent, "SecureActionButtonTemplate" );
		self.allianceButton:SetHeight( 25 );
		self.allianceButton:SetWidth( 150 );
		self.allianceButton:SetScript( "PostClick", function()
			if( IsAltKeyDown() and carrierNames["Alliance" ] ) then
				SSPVP:ChannelMessage( string.format( L["Alliance flag carrier %s, flag held for %s."], carrierNames["Alliance"], SSOverlay:FormatTime( GetTime() - carrierTimes["Alliance"], "minsec" ) ) );
			end
		end );

		self.allianceText = self.allianceButton:CreateFontString( self.allianceButton:GetName() .. "Text", "BACKGROUND" );
		self.allianceText:SetJustifyH( "LEFT" );
		self.allianceText:SetHeight( 25 );
		self.allianceText:SetWidth( 150 );
	end
	
	if( not self.hordeButton ) then
		self.hordeButton = CreateFrame( "Button", "WSGFlagHorde", UIParent, "SecureActionButtonTemplate" );
		self.hordeButton:SetHeight( 25 );
		self.hordeButton:SetWidth( 150 );
		self.hordeButton:SetScript( "PostClick", function()
			if( IsAltKeyDown() and carrierNames["Horde"] ) then
				SSPVP:ChannelMessage( string.format( L["Horde flag carrier %s, flag held for %s."], carrierNames["Horde"], SSOverlay:FormatTime( GetTime() - carrierTimes["Horde"], "minsec" ) ) );
			end
		end );

		self.hordeText = self.hordeButton:CreateFontString( self.hordeButton:GetName() .. "Text", "BACKGROUND" );
		self.hordeText:SetJustifyH( "LEFT" );
		self.hordeText:SetHeight( 25 );
		self.hordeText:SetWidth( 150 );
	end
	
	self:SetCarrierBorders();
end
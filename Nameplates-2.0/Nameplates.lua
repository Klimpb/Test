Nameplates = DongleStub("Dongle-1.0"):New( "Nameplates" );

local L = NameplatesLocals;
local CREATED_ROWS = 0;

local regionList = { "healthBorder", "castBorder", "spellIcon", "glowTexture", "nameFrame", "levelFrame", "skullIcon", "raidIcon" };
local frames = {};

local groupMap = {};
local petMap = {};

--[[
Config format for the regions
All of the options are optional, except if you include
point you must include relativePoint, x and y.

configName = {
	point = "LEFT"
	relativePoint = "CENTER",
	x = 0,
	y = 0,
	hide = false,
	texture = "Path to texture",
	width = 128,
	height = 32,
	alpha = 1.0,
	font = { path = "Path Font", size = 15, border = "OUTLINE" }
}
]]


function Nameplates:Enable()
	self.defaults = {
		profile = {
			text = {
				scale = 0.80,
				color = { r = 1, g = 1, b = 1 },
				mouseover = { r = 1, g = 1, b = 0 },

				overlayColor = { r = 0, g = 0, b = 0 },
				overlayOpacity = 0,

				align = "CENTER",
				padX = 0,
				padY = 5,
				
				font = { path = "Fonts\\FRIZQT__.TTF", size = 10, border = "OUTLINE" },

				healthEnabled = true,
				healthMob = false,
				healthType = "percent",
				
				castEnabled = true,
				castType = "crttl",
				roundTo = "2",
			},
			healthBar = {
				opacity = 1.0,
				friendly = false,
				enemy = false,
			},
			castBar = {
				opacity = 1.0,
			},
			colors = {
				hostile = { r = 1, g = 0, b = 0 },
				hostileUnknown = { r = 1, g = 0, b = 0 },
				hostileTotem = { r = 1, g = 0, b = 0 },

				raid = { r = 0, g = 0, b = 1 },
				party = { r = 0, g = 0, b = 1 },
				groupedPet = { r = 0, g = 1, b = 0 },

				friendlyPlayer = { r = 0, g = 0, b = 1 },
				friendlyNPC = { r = 0, g = 1, b = 0 },
				friendlyTotem = { r = 0, g = 1, b = 0 },

				neutralNPC = { r = 1, g = 1, b =  0 },
				critter = { r = 1, g = 1, b = 0 },
			},
			nameplates = {
				overlap = false,
			},
			dropdowns = {
			
			},
			enemies = {},
			friendlies = {},
			castBorder = {},
			hideTypes = {},
			modules = {},
		},
	};
	
	for classToken, color in pairs( RAID_CLASS_COLORS ) do
		self.defaults.profile.friendlies[ classToken ] = color;
		self.defaults.profile.enemies[ classToken ] = color;
	end
	
	self.db = self:InitializeDB( "NameplatesDB", self.defaults )
	
	if( not self.frame ) then
		self.frame = CreateFrame( "Frame" );
	end

	self.frame:SetScript( "OnUpdate", self.OnUpdate );
	
	self:RegisterEvent( "RAID_ROSTER_UPDATE", "UpdateUnitMap" );
	self:RegisterEvent( "PARTY_MEMBERS_CHANGED", "UpdateUnitMap" );
	
	if( GetNumPartyMembers() > 0 or GetNumRaidMembers() > 0 ) then
		self:UpdateUnitMap();
	end

	for name, module in self:IterateModules() do
		if( not module.moduleEnabled and not self.db.profile.modules[ name ] and module.EnableModule ) then
			module:EnableModule();
			module.moduleEnabled = true;
		end
	end
end

function Nameplates:Disable()
	self.frame:SetScript( "OnUpdate", nil );

	for name, module in self:IterateModules() do
		if( module.moduleEnabled ) then
			module:DisableModule();
			module.moduleEnabled = nil;
		end
	end
end

function Nameplates:UpdateUnitMap()
	groupMap = {};
	petMap = {};
	
	for i=1, GetNumRaidMembers() do
		if( UnitExists( "raidpet" .. i ) ) then
			petMap[ UnitName( "raidpet" .. i ) ] = "pet";
		end
		groupMap[ UnitName( "raid" .. i ) ] = { type = "raid", class = select( 2, UnitClass( "raid" .. i ) ) };
	end
	
	for i=1, GetNumPartyMembers() do
		if( UnitExists( "partypet" .. i ) ) then
			petMap[ UnitName( "partypet" .. i ) ] = "pet";
		end
		groupMap[ UnitName( "party" .. i ) ] = { type = "party", class = select( 2, UnitClass( "party" .. i ) ) };
	end
end

-- This is a rather hack way of doing it, I need to look into improving what can be done without
-- taking a performance hit
local function SetupFrame( config, frame )
	if( not Nameplates.db.profile[ config ] ) then
		return;
	end
	
	if( Nameplates.db.profile[ config ].alpha ) then
		frame:SetAlpha( Nameplates.db.profile[ config ].alpha );
	end
	
	if( Nameplates.db.profile[ config ].height ) then
		frame:SetHeight( Nameplates.db.profile[ config ].height );
	end
	
	if( Nameplates.db.profile[ config ].width ) then
		frame:SetWidth( Nameplates.db.profile[ config ].width );
	end
	
	if( Nameplates.db.profile[ config ].hide ) then
		frame:Hide();
		return;
	end

	if( Nameplates.db.profile[ config ].point ) then
		local _, relative = frame:GetPoint();
		if( config == "glowTexture" ) then
			frame:ClearAllPoints();
		end

		frame:SetPoint( Nameplates.db.profile[ config ].point, relative, Nameplates.db.profile[ config ].relativePoint, Nameplates.db.profile[ config ].x, Nameplates.db.profile[ config ].y );
	end

	if( not frame.NPFontSet and Nameplates.db.profile[ config ].font ) then
		frame:SetFont( Nameplates.db.profile[ config ].font.path, Nameplates.db.profile[ config ].font.size, Nameplates.db.profile[ config ].font.border );
		frame.NPFontSet = true;
	end

	if( not frame.NPTextureSet and Nameplates.db.profile[ config ].texture ) then
		frame:SetTexture( Nameplates.db.profile[ config ].texture );
		frame.NPTextureSet = true;
	end
end

-- Health management
local function GetColor( r, g, b, a )
	return floor( r + 0.001 ), floor( g + 0.001 ), floor( b + 0.001 ), floor( a + 0.001 );
end

local function HealthOnShow( frame )
	frame = frame or this;

	local parent = frame:GetParent();
	local _, _, _, _, nameFrame, levelFrame = parent:GetRegions();
	
	frame.NPData.name = nameFrame:GetText();
	frame.NPData.level = tonumber( levelFrame:GetText() ) or -1;

	if( frame.NPOnShow ) then
		frame.NPOnShow();
	end
	
	-- Detect bar type
	local r, g, b = GetColor( frame:GetStatusBarColor() );						
	if( r == 1 and g == 0 and b == 0 ) then
		if( frame.NPData.level == -1 ) then
			frame.NPData.type = "hostileUnknown";
		else
			frame.NPData.type = "hostile";
		end
	elseif( r == 0 and g == 0 and b == 1 ) then
		frame.NPData.type = "friendlyPlayer";
	elseif( r == 0 and g == 1 and b == 0 ) then
		frame.NPData.type = "friendlyNPC";
	elseif( r == 1 and g == 1 and b == 0 ) then
		if( frame.NPData.level <= 5 ) then
			frame.NPData.type = "critter";
		else
			frame.NPData.type = "neutralNPC";
		end
	else
		frame.NPData.type = "none";
	end
	
	-- Hidden type, don't do anything more parsing.
	if( Nameplates.db.profile.hideTypes[ frame.NPData.type ] ) then
		parent:SetHeight( 0.1 );
		parent:SetWidth( 0.1 );
		parent:Hide();
		return;

	-- Overlapping means we have to set parent/height to 0
	elseif( Nameplates.db.profile.nameplates.overlap ) then
		parent:SetHeight( 0.1 );
		parent:SetWidth( 0.1 );
	end
	
	-- Colorize
	local color;
	local class = NPClass:GetClassByName( frame.NPData.name );
	
	-- Friendly grouped player
	if( frame.NPData.type == "friendlyPlayer" and groupMap[ frame.NPData.name ] ) then
		color = Nameplates.db.profile.colors[ groupMap[ frame.NPData.name ].type ];
	
	-- Friendly grouped pet
	elseif( frame.NPData.type == "friendlyNPC" and petMap[ frame.NPData.name ] ) then
		color = Nameplates.db.profile.colors.groupedPet;
	
	-- Friendly player with class data
	elseif( Nameplates.db.profile.healthBar.friendly and frame.NPData.type == "friendlyPlayer" and class ) then
		color = Nameplates.db.profile.friendlies[ class ];

	-- Hostile player with class data
	elseif( Nameplates.db.profile.healthBar.enemy and ( frame.NPData.type == "hostile" or frame.NPData.type == "unknownHostile" ) and class ) then
		color = Nameplates.db.profile.enemies[ class ];
	
	-- Everything else
	elseif( Nameplates.db.profile.colors[ frame.NPData.type ] ) then
		color = Nameplates.db.profile.colors[ frame.NPData.type ];	
	end
	
	frame:SetStatusBarColor( color.r, color.g, color.b, Nameplates.db.profile.healthBar.opacity );
	nameFrame:SetTextColor( Nameplates.db.profile.text.color.r, Nameplates.db.profile.text.color.g, Nameplates.db.profile.text.color.b );

	-- Reposition everything
	for i, key in pairs( regionList ) do
		if( Nameplates.db.profile[ key ] ) then
			SetupFrame( key, ( select( i, parent:GetRegions() ) ) );
		end
	end
end

local function HealthOnHide( frame )
	frame = frame or this;

	if( frame.NPOnHide ) then
		frame.NPOnHide();
	end

	-- It was mouseovered, but it was hidden before we mouse out
	if( frame.NPData.mouseOver ) then
		local _, _, _, glowTexture, nameFrame = frame:GetParent():GetRegions();

		nameFrame:SetTextColor( Nameplates.db.profile.text.color.r, Nameplates.db.profile.text.color.g, Nameplates.db.profile.text.color.b );
		glowTexture:Hide();
	end
	
	-- Reset data
	frame.NPData = { barColor = {} };
end

local function HealthOnChange( frame )
	frame = frame or this;
	if( frame.NPOnChange ) then
		frame.NPOnChange();
	end

	if( not Nameplates.db.profile.text.healthEnabled ) then
		return;
	end
	
	local minValue, maxValue = frame:GetMinMaxValues();
	local currentValue = frame:GetValue();
	
	-- Check for one of the mob health type of mods
	if( Nameplates.db.profile.text.healthMob and maxValue == 100 ) then
		if( MobHealth3 ) then
			currentValue, maxValue = MobHealth3:GetUnitHealth( "player", currentValue, maxValue, frame.NPData.name, frame.NPData.level );
		elseif( MobHealth_PPP and frame.NPData.name and frame.NPData.level ) then
			local ppp = MobHealth_PPP( frame.NPData.name .. ":" .. frame.NPData.level );

			if( ppp > 0 ) then
				currentValue = floor( currentValue * ppp + 0.5 );
				maxValue = floor( 100 * ppp + 0.5 );
			end
		end
	end
	
	if( maxValue == 100 or Nameplates.db.profile.text.healthType == "percent" ) then
		frame.NPText:SetText( floor( currentValue / maxValue * 100 + 0.5 ) .. "%" );					
		
	elseif( Nameplates.db.profile.text.healthType == "deff" ) then
		local deff = maxValue - currentValue;
		if( deff > 0 ) then
			frame.NPText:SetText( "-" .. deff );					
		else
			frame.NPRow:Hide();
			return;
		end

	elseif( Nameplates.db.profile.text.healthType == "crtmax" ) then
		frame.NPText:SetText( currentValue .. "/" .. maxValue );				

	elseif( Nameplates.db.profile.text.healthType == "crt" ) then
		frame.NPText:SetText( currentValue );				
	end
	
	frame.NPRow:SetWidth( frame.NPText:GetWidth() + 10 );
	frame.NPRow:Show();
end

-- Casting management
local function CastOnShow( frame )
	frame = frame or this;

	if( frame.NPOnShow ) then
		frame.NPOnShow();
	end
end

local function CastOnHide( frame )
	frame = frame or this;

	if( frame.NPOnHide ) then
		frame.NPOnHide();
	end
end

local function CastOnChange( frame )
	frame = frame or this;

	if( frame.NPOnChange ) then
		frame.NPOnChange();
	end
	
	-- Got to reshow the casting border sadly
	if( Nameplates.db.profile.castBorder.hide ) then
		( select( 2, frame:GetParent():GetRegions() ) ):Hide();
	end

	if( not Nameplates.db.profile.text.castEnabled ) then
		return;
	end

	local minValue, maxValue = frame:GetMinMaxValues();
	local currentValue = frame:GetValue();

	if( currentValue >= maxValue or currentValue == 0 ) then
		frame.NPRow:Hide();
		return;
	end
	
	maxValue = maxValue - currentValue + ( currentValue - minValue );
	currentValue = math.floor( ( ( currentValue - minValue ) * 100 ) + 0.5 ) / 100;
	
	if( Nameplates.db.profile.text.castType == "timeleft" ) then
		frame.NPText:SetText( string.format( "%." .. Nameplates.db.profile.text.roundTo .. "f", maxValue - currentValue ) );
	elseif( Nameplates.db.profile.text.castType == "percent" ) then
		frame.NPText:SetText( string.format( "%d%%", currentValue / maxValue * 100 + 0.05 ) );
	elseif( Nameplates.db.profile.text.castType == "crttl" ) then
		frame.NPText:SetText( string.format( "%." .. Nameplates.db.profile.text.roundTo .. "f / %." .. Nameplates.db.profile.text.roundTo .. "f", currentValue, maxValue ) );		
	else
		frame.NPRow:Hide();
		return;
	end

	frame.NPRow:SetWidth( frame.NPText:GetWidth() + 10 );
	frame.NPRow:Show();
end

-- Text creation
local backdrop = {	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\Tooltips\UI-Tooltip-Border",
			tile = true,
			edgeSize = 5,
			tileSize = 5,
			insets = { left = 3, right = 3, top = 0, bottom = 0 } };

local function CreateText( frame )
	if( frame.NPRow ) then
		return;
	end
	
	CREATED_ROWS = CREATED_ROWS + 1;
	
	frame.NPRow = CreateFrame( "Frame", "NPText" .. CREATED_ROWS, frame );
	frame.NPText = frame.NPRow:CreateFontString( frame.NPRow:GetName() .. "Text", "ARTWORK" );
	
	frame.NPText:SetFont( Nameplates.db.profile.text.font.path, Nameplates.db.profile.text.font.size, Nameplates.db.profile.text.font.border );

	frame.NPRow:SetScale( Nameplates.db.profile.text.scale );
	frame.NPRow:SetHeight( Nameplates.db.profile.text.font.size );
	
	frame.NPRow:SetPoint( "TOP", frame, Nameplates.db.profile.text.align, Nameplates.db.profile.text.padX, Nameplates.db.profile.text.padY );
	frame.NPText:SetPoint( "TOP", 0, 0 );

	frame.NPRow:SetBackdrop( backdrop );
	frame.NPRow:SetBackdropColor( Nameplates.db.profile.text.overlayColor.r, Nameplates.db.profile.text.overlayColor.g, Nameplates.db.profile.text.overlayColor.b, Nameplates.db.profile.text.overlayOpacity );
end

local function FindUnhookedFrames( ... )
	for i=1, select( "#", ... ) do
		local bar = select( i, ... );
		if( bar and not bar.NPHooked and not bar:GetName() and bar:IsVisible() and bar.GetFrameType and bar:GetFrameType() == "StatusBar" ) then
			return bar;
		end
	end
end

local function SetStatusBarColor( self, r, g, b, a )
	self.NPData.barColor.r = r;
	self.NPData.barColor.g = g;
	self.NPData.barColor.b = b;
	self.NPData.barColor.a = a;

	self:NPSetStatusBarColor( r, g, b, a );
end

-- REGIONS
-- 1 = Health bar/level border
-- 2 = Border for the casting bar
-- 3 = Spell icon for the casting bar
-- 4 = Glow around the health bar when hovering over
-- 5 = Name text
-- 6 = Level text
-- 7 = Skull icon if the mob/player is 10 or more levels higher then you
-- 8 = Raid icon when you're close enough to the mob/player to see the name plate
local function HookFrames( ... )
	for i=1, select( "#", ... ) do
		local bar = FindUnhookedFrames( select( i, ... ):GetChildren() );
		if( bar ) then
			bar.NPHooked = true;

			local parent = bar:GetParent();
			
			local healthBorder, castBorder, spellIcon, glowTexture, nameFrame, levelFrame, skullIcon, raidIcon = parent:GetRegions();
			local health, cast = parent:GetChildren();
			
			-- Create text
			CreateText( health );
			CreateText( cast );
			
			-- Hook/setup health bar
			health.NPData = { barColor = {} };
			health.NPOnShow = health:GetScript( "OnShow" );
			health.NPOnHide = health:GetScript( "OnHide" );
			health.NPValueChange = health:GetScript( "OnValueChanged" );
			health.NPSetStatusBarColor = health.SetStatusBarColor;
			
			health:SetScript( "OnShow", HealthOnShow );
			health:SetScript( "OnHide", HealthOnHide );
			health:SetScript( "OnValueChanged", HealthOnChange );
			health.SetStatusBarColor = SetStatusBarColor;
			
			-- Now hook/setup casting bar
			cast.NPOnShow = cast:GetScript( "OnShow" );
			cast.NPOnHide = cast:GetScript( "OnHide" );
			cast.NPValueChange = cast:GetScript( "OnValueChanged" );
			
			cast:SetScript( "OnShow", CastOnShow );
			cast:SetScript( "OnHide", CastOnHide );
			cast:SetScript( "OnValueChanged", CastOnChange );
			
			-- Annd now setup everything
			SetupFrame( "healthBar", health );
			SetupFrame( "glowTexture", glowTexture );
			SetupFrame( "castBar", cast );
			
			if( health:IsVisible() ) then
				HealthOnShow( health );
				HealthOnChange( health );
			end
			
			if( cast:IsVisible() ) then
				CastOnShow( cast );
				CastOnChange( cast );
			end
			
			frames[ parent ] = true;
		end
	end
end

local numChildren = -1;
function Nameplates:OnUpdate()
	if( WorldFrame:GetNumChildren() ~= numChildren ) then
		numChildren = WorldFrame:GetNumChildren();
		HookFrames( WorldFrame:GetChildren() );
	end
			
	-- Not happy about having to do this, but we have no choice.
	local bar, glowTexture, nameFrame, r, g, b, a;
	for parent, _ in pairs( frames ) do
		bar = parent:GetChildren();
		if( bar:IsVisible() ) then
			-- Check color
			r, g, b, a = bar:GetStatusBarColor();
			if( bar.NPData.barColor.r ~= r or bar.NPData.barColor.g ~= g or bar.NPData.barColor.b ~= b or bar.NPData.barColor.a ~= a ) then
				bar:SetStatusBarColor( bar.NPData.barColor.r, bar.NPData.barColor.g, bar.NPData.barColor.b, bar.NPData.barColor.a );
			end
			
			-- Check mouseover status
			_, _, _, glowTexture, nameFrame = parent:GetRegions();
			if( glowTexture:IsVisible() and not bar.NPData.mouseOver ) then
				nameFrame:SetTextColor( Nameplates.db.profile.text.mouseover.r, Nameplates.db.profile.text.mouseover.g, Nameplates.db.profile.text.mouseover.b );
				glowTexture:Show();
				
				bar.NPData.mouseOver = true;
				
			elseif( not glowTexture:IsVisible() and bar.NPData.mouseOver ) then
				nameFrame:SetTextColor( Nameplates.db.profile.text.color.r, Nameplates.db.profile.text.color.g, Nameplates.db.profile.text.color.b );
				glowTexture:Hide();
				
				bar.NPData.mouseOver = nil;
			end
		end
	end
end
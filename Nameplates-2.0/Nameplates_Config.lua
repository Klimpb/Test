local UI = Nameplates:NewModule( "Nameplates-UI" );
local L = NameplatesLocals;
local tabs = {	["modules"] = L["Modules"],
		["healthBar"] = L["Health Bars"],
		["castBar"] = L["Cast Bars"],
		["healthBorder"] = L["Health Border"],
		["castBorder"] = L["Cast Border"],
		["spellIcon"] = L["Spell Icon"],
		["glowTexture"] = L["Mouseover Texture"],
		["nameFrame"] = L["Name Frame"],
		["levelFrame"] = L["Level Frame"],
		["skullIcon"] = L["Skull Icon"],
		["raidIcon"] = L["Raid Icon"] };
		
local dropDownList = {
	["texture"] = {
		{ L["Default"], "Interface\\TargetingFrame\\UI-TargetingFrame-BarFill" },
		{ "BantoBar", "Interface\\AddOns\\Nameplates\\textures\\BantoBar.tga" },
		{ "Bars", "Interface\\AddOns\\Nameplates\\textures\\Bars.tga" },
		{ "Button", "Interface\\AddOns\\Nameplates\\textures\\Button.tga" },
		{ "Charcoal", "Interface\\AddOns\\Nameplates\\textures\\Charcoal.tga" },
		{ "Cloud", "Interface\\AddOns\\Nameplates\\textures\\Cloud.tga" },
		{ "Dabs", "Interface\\AddOns\\Nameplates\\textures\\Dabs.tga" },
		{ "DarkBottom", "Interface\\AddOns\\Nameplates\\textures\\DarkBottom.tga" },
		{ "Fifths", "Interface\\AddOns\\Nameplates\\textures\\Fifths.tga" },
		{ "Fourths", "Interface\\AddOns\\Nameplates\\textures\\Fourths.tga" },
		{ "Gloss", "Interface\\AddOns\\Nameplates\\textures\\Gloss.tga" },
		{ "Grid", "Interface\\AddOns\\Nameplates\\textures\\Grid.tga" },
		{ "LiteStep", "Interface\\AddOns\\Nameplates\\textures\\LiteStep.tga" },
		{ "Smooth", "Interface\\AddOns\\Nameplates\\textures\\Smooth.tga" },
		{ "Steel", "Interface\\AddOns\\Nameplates\\textures\\Steel.tga" },
		{ "Water", "Interface\\AddOns\\Nameplates\\textures\\Water.tga" },
		{ "Wisps", "Interface\\AddOns\\Nameplates\\textures\\Wisps.tga" },
	},
	["font"] = {
		{ "FRIZQT__.TTF", "Fonts\\FRIZQT__.TTF" },
	},
	["border"] = {
		{ L["None"], "" },
		{ L["Outline"], "OUTLINE" },
		{ L["Thick outline"], "THICKOUTLINE" },
		{ L["Monochrome"], "MONOCHROME" },
	},
	["size"] = {
		{ 7, 7 },
		{ 8, 8 },
		{ 9, 9 },
		{ 10, 10 },
		{ 11, 11 },
		{ 12, 12 },
		{ 13, 13 },
		{ 14, 14 },
		{ 15, 15 },
	},
};

function UI:GetValue( config )
	if( #( config ) == 2 and Nameplates.db.profile[ config[1] ] ) then
		return Nameplates.db.profile[ config[1] ][ config[2] ];
	elseif( #( config ) == 3 and Nameplates.db.profile[ config[1] ][ config[2] ] ) then
		return Nameplates.db.profile[ config[1] ][ config[2] ][ config[3] ];
	end
	
	return nil;
end

function UI:SetValue( config, val )
	if( #( config ) == 2 ) then
		-- Table doesn't exist yet
		if( not Nameplates.db.profile[ config[1] ] ) then
			Nameplates.db.profile[ config[1] ] = {};
		end

		Nameplates.db.profile[ config[1] ][ config[2] ] = val;
		
	elseif( #( config ) == 3 ) then
		-- Table doesn't exist yet
		if( not Nameplates.db.profile[ config[1] ][ config[2] ] ) then
			Nameplates.db.profile[ config[1] ][ config[2] ] = {};
		end
		
		Nameplates.db.profile[ config[1] ][ config[2] ][ config[3] ] = val;
	end
end

function UI:DropDownInitialize()
	if( this:GetName() ) then
		local dropdown = getglobal( this:GetParent():GetName() );
		
		if( dropdown.dropList ) then
			for id, row in pairs( dropdown.dropList ) do
				UIDropDownMenu_AddButton( { value = row[2], text = row[1], owner = dropdown, arg1 = row, arg2 = id, func = UI.DropDownOnClick } );
			end
		end
	end
end


function UI.DropDownOnClick( row, id )
	UIDropDownMenu_SetSelectedID( this.owner, id );
	UIDropDownMenu_SetText( row[1], this.owner );
	
	if( this.owner.setInput ) then
		this.owner.setInput:SetText( row[2] );
	end
	
	if( this.owner.config ) then
		UI:SetValue( this.owner.config, this.owner.dropList[ id ][2] );
	end
end

local function SetupDropdown( dropdown, config )
	UIDropDownMenu_Initialize( dropdown, UI.DropDownInitialize );

	local key;
	if( config[2] == "texture" ) then
		key = "texture";
	elseif( config[2] == "font" and config[3] == "border" ) then
		key = "border";
	elseif( config[2] == "font" and config[3] == "path" ) then
		key = "font";
	elseif( config[2] == "font" and config[3] == "size" ) then
		key = "size";
	end
	
	if( key ) then
		dropdown.dropList = dropDownList[ key ];
		dropdown.config = config;
		
		local selected = UI:GetValue( config );
		
		for id, row in pairs( dropDownList[ key ] ) do
			if( id == selected or row[2] == selected ) then
				UIDropDownMenu_SetSelectedID( dropdown, id );
				UIDropDownMenu_SetText( row[1], dropdown );
				
				return;
			end
		end

		UIDropDownMenu_SetSelectedID( dropdown, 1 );
		UIDropDownMenu_SetText( dropDownList[ key ][1][1], dropdown );
	end
end

function UI:InputOnChange()
	local val = this:GetText();
	if( this.forceType ) then
		val = tonumber( this:GetText() ) or 0;
	end
	
	UI:SetValue( this.config, val );
end

function UI:HighlightBorder()
	getglobal( this:GetName().."Border" ):SetVertexColor( NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b );
end

function UI:UnhighlightBorder()
	getglobal( this:GetName().."Border" ):SetVertexColor( HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b );
end

function UI:CreateFontInstance( catFrame )
	local frame = CreateFrame( "Frame", catFrame:GetName() .. "FI", catFrame );
	frame:SetPoint( "TOPLEFT", catFrame, "TOPLEFT", 0, 0 );
	frame:SetHeight( 150 );

	--SetFont( "path", height, [ "OUTLINE", "THICKOUTLINE", "MONOCHROME" ] )
	--SetShadowColor( r, g, b, a )
	--SetShadowOffset( x, y )
	--SetTextColor( r, g, b, a );

	-- Text
	local textFont = frame:CreateFontString( frame:GetName() .. "FontPath", "BACKGROUND" );
	textFont:SetFontObject( GameFontNormalSmall );
	textFont:SetText( L["Font"] );
	textFont:SetPoint( "TOPLEFT", frame, "TOPLEFT", -5, 0 );
	textFont:Show();
	
	-- Font input (custom)
	local input = CreateFrame( "EditBox", frame:GetName() .. "PathInput", frame, "InputBoxTemplate" ); 

	input.config = { catFrame.configKey, "font", "path" };
	input:SetScript( "OnTextChanged", self.InputOnChange );

	input:SetHeight( 20 );
	input:SetWidth( 125 );
	input:SetAutoFocus( false );

	input:SetPoint( "TOPLEFT", textFont, "TOPRIGHT", 10, 6 );
	input:Show();

	-- Text
	local textOr = frame:CreateFontString( frame:GetName() .. "FontOr", "BACKGROUND" );
	textOr:SetFontObject( GameFontNormalSmall );
	textOr:SetText( L["Or"] );
	textOr:SetPoint( "TOPLEFT", input, "TOPRIGHT", 5, -5 );
	textOr:Show();
	
	-- Default fonts
	local dropdown = CreateFrame( "Frame", frame:GetName() .. "Dropdown", frame, "UIDropDownMenuTemplate" );
	dropdown:SetPoint( "TOPLEFT", textOr, "TOPRIGHT", -12, 8 );
	dropdown.setInput = input;

	SetupDropdown( dropdown, { catFrame.configKey, "font", "path" } );

	-- Default fonts
	dropdown = CreateFrame( "Frame", frame:GetName() .. "Dropdown", frame, "UIDropDownMenuTemplate" );
	dropdown:SetPoint( "TOPLEFT", textOr, "TOPRIGHT", -12, 8 );
	dropdown.setInput = input;

	SetupDropdown( dropdown, { catFrame.configKey, "font", "path" } );
	
	-- Text
	local textOutline = frame:CreateFontString( frame:GetName() .. "FontOutline", "BACKGROUND" );
	textOutline:SetFontObject( GameFontNormalSmall );
	textOutline:SetText( L["Border"] );
	textOutline:SetPoint( "TOPLEFT", textFont, "TOPLEFT", 0, -30 );
	textOutline:Show();

	-- Border
	dropdown = CreateFrame( "Frame", frame:GetName() .. "OutlineDrop", frame, "UIDropDownMenuTemplate" );
	dropdown:SetPoint( "TOPLEFT", textOutline, "TOPRIGHT", -12, 8 );
	SetupDropdown( dropdown, { catFrame.configKey, "font", "border" } );
	
	-- Text
	local textSize = frame:CreateFontString( frame:GetName() .. "FontSize", "BACKGROUND" );
	textSize:SetFontObject( GameFontNormalSmall );
	textSize:SetText( L["Size"] );
	textSize:SetPoint( "TOPLEFT", dropdown, "TOPRIGHT", 120, -9 );
	textSize:Show();

	-- Font Size
	input = CreateFrame( "EditBox", frame:GetName() .. "SizeInput", frame, "InputBoxTemplate" ); 
	input.forceType = "int";
	input.config = { catFrame.configKey, "font", "size" };
	input:SetScript( "OnTextChanged", self.InputOnChange );
	
	input:SetHeight( 20 );
	input:SetWidth( 50 );
	input:SetAutoFocus( false );
	
	input:SetPoint( "TOPLEFT", textSize, "TOPRIGHT", 10, 8 );
	input:Show();

	-- Text
	local textColor = frame:CreateFontString( frame:GetName() .. "ColorText", "BACKGROUND" );
	textColor:SetFontObject( GameFontNormalSmall );
	textColor:SetText( L["Text color"] );
	textColor:SetPoint( "TOPLEFT", textOutline, "TOPLEFT", 0, -30 );
	textColor:Show();
	
	-- Font Color
	local color = CreateFrame( "Button", frame:GetName() .. "FontColor", frame );
	color.config = { catFrame.configKey, "font", "color" };
	color.setColor = UI:GetValue( color.config ) or { r = 0, g = 0, b = 0 };

	color:SetHeight( 18 );
	color:SetWidth( 18 );
	color:SetPoint( "TOPLEFT", textColor, "TOPRIGHT", 8, 4 );
	
	color:SetScript( "OnEnter", self.HighlightBorder );
	color:SetScript( "OnLeave", self.UnhighlightBorder );
	color:SetScript( "OnClick", self.OpenColorPicker );

	color:SetNormalTexture( "Interface\\ChatFrame\\ChatFrameColorSwatch" );
	color:GetNormalTexture():SetVertexColor( color.setColor.r, color.setColor.g, color.setColor.b );
	
	local border = color:CreateTexture( color:GetName() .. "Border", "BACKGROUND" );
	border:SetHeight( 16 );
	border:SetWidth( 16 );
	border:SetPoint( "CENTER", 0, 0 );
	border:SetTexture( 1, 1, 1 );
	border:Show();

	-- Text
	local textColor = frame:CreateFontString( frame:GetName() .. "ColorText", "BACKGROUND" );
	textColor:SetFontObject( GameFontNormalSmall );
	textColor:SetText( L["Text color"] );
	textColor:SetPoint( "TOPLEFT", textOutline, "TOPLEFT", 0, -30 );
	textColor:Show();
	
	-- Font Color
	local color = CreateFrame( "Button", frame:GetName() .. "FontColor", frame );
	color.config = { catFrame.configKey, "font", "color" };
	color.setColor = UI:GetValue( color.config ) or { r = 0, g = 0, b = 0 };

	color:SetHeight( 18 );
	color:SetWidth( 18 );
	color:SetPoint( "TOPLEFT", textColor, "TOPRIGHT", 8, 4 );
	
	color:SetScript( "OnEnter", self.HighlightBorder );
	color:SetScript( "OnLeave", self.UnhighlightBorder );
	color:SetScript( "OnClick", self.OpenColorPicker );

	color:SetNormalTexture( "Interface\\ChatFrame\\ChatFrameColorSwatch" );
	color:GetNormalTexture():SetVertexColor( color.setColor.r, color.setColor.g, color.setColor.b );
	
	local border = color:CreateTexture( color:GetName() .. "Border", "BACKGROUND" );
	border:SetHeight( 16 );
	border:SetWidth( 16 );
	border:SetPoint( "CENTER", 0, 0 );
	border:SetTexture( 1, 1, 1 );
	border:Show();
	
	return frame;
end

local openPicker;
function UI:OpenColorPicker()
	openPicker = this;

	ColorPickerFrame.func = UI.SetColor;
	ColorPickerFrame.cancelFunc = UI.CancelColor;
	
	ColorPickerFrame.previousValues = { r = this.setColor.r, g = this.setColor.g, b = this.setColor.b };
	ColorPickerFrame:SetColorRGB( this.setColor.r, this.setColor.g, this.setColor.b );
	ColorPickerFrame:Show();
end

function UI.SetColor()
	local r, g, b = ColorPickerFrame:GetColorRGB();
	
	UI:SetValue( openPicker.config, { r = r, g = g, b = b } );
	openPicker:GetNormalTexture():SetVertexColor( r, g, b );
end

function UI.CancelColor( color )
	UI:SetValue( openPicker.config, color );
	openPicker:GetNormalTexture():SetVertexColor( color.r, color.g, color.b );
end

function UI:CreateFrame( catFrame )
	local frame = CreateFrame( "Frame", catFrame:GetName() .. "FR", catFrame );
	
	-- SetBackdrop
	-- SetBackdropBorderColor
	-- SetBackdropColor
	

	return frame;
end

function UI:CreateUIObject( catFrame )
	local frame = CreateFrame( "Frame", catFrame:GetName() .. "UIO", catFrame );
	
	-- SetAlpha( a );

	return frame;
end

function UI:CreateRegion( catFrame )
	local frame = CreateFrame( "Frame", catFrame:GetName() .. "RG", catFrame );
	
	-- Show()
	-- Hide()
	
	-- SetHeight( height )
	-- SetWidth( width )
	-- SetPoint( point, parent, relativePoint, offX, offY );
	-- Points are: TOPLEFT, TOPRIGHT, BOTTOMLEFT, BOTTOMRIGHT, CENTER, TOP, BOTTOM, LEFT, RIGHT
	
	return frame;
end

function UI:CreateTexture( catFrame )
	local frame = CreateFrame( "Frame", catFrame:GetName() .. "TX", catFrame );
	
	local text = frame:CreateFontString( frame:GetName() .. "InputText", "BACKGROUND" );
	text:SetFontObject( GameFontNormalSmall );
	text:SetText( L["Texture"] );
	text:SetPoint( "TOPLEFT", frame, "TOPLEFT", -5, 0 );
	text:Show();
	
	local input = CreateFrame( "EditBox", frame:GetName() .. "Input", frame, "InputBoxTemplate" ); 
	input:SetHeight( 20 );
	input:SetWidth( 75 );
	input:SetAutoFocus( false );
	input:SetPoint( "TOPLEFT", text, "TOPRIGHT", 10, 6 );
	input:Show();

	text = frame:CreateFontString( frame:GetName() .. "InputTextOr", "BACKGROUND" );
	text:SetFontObject( GameFontNormalSmall );
	text:SetText( L["Or"] );
	text:SetPoint( "TOPLEFT", input, "TOPRIGHT", 10, -5 );
	text:Show();
	
	frame:SetPoint( "TOPLEFT", catFrame, "TOPLEFT", 0, 0 );
	frame:SetHeight( 150 );

	return frame;
end

function UI:CreateStatusBar( catFrame )
	local frame = CreateFrame( "Frame", catFrame:GetName() .. "SB", catFrame );
	
	-- SetStatusBarColor( r, g, b, a )
	-- SetStatusBarTexture( "file" )
	
	return frame;
end


local configBackdrop = {bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
			tile = false,
			edgeSize = 1,
			tileSize = 1,
			insets = { left = 1, right = 1, top = 1, bottom = 1 }};

function UI:CreateConfig( configKey, ... )
	local configFrame = CreateFrame( "Frame", UI.frame:GetName() .. configKey, UI.frame );

	configFrame:SetPoint( "TOPLEFT", UI.frame, "TOPLEFT", 5, -30 );
	configFrame:SetHeight( 365 );
	configFrame:SetWidth( 400 );
	configFrame:Show();
	
	local list = {};
	local obj, text;
	
	-- First we have to compile the list to get
	-- everything into the correct category.
	for i=1, select( "#", ... ) do
		obj = select( i, ... );
		text = L[ obj ];
		
		if( text ) then
			if( not list[ text ] ) then
				list[ text ] = {};
			end

			table.insert( list[ text ], obj );
		end
	end
	
	-- Now compile it into a UI
	local i = 0;
	local catFrame, catText;
	
	for text, objs in pairs( list ) do
		i = i + 1;

		catFrame = CreateFrame( "Frame", configFrame:GetName() .. i, configFrame );
		catFrame:SetHeight( 0 );
		catFrame:SetWidth( configFrame:GetWidth() );

		catFrame:SetBackdrop( backdrop );

		catFrame:SetBackdropColor( 0, 0, 0, 1 );
		catFrame:SetBackdropBorderColor( 1, 1, 1, 1 );

		catFrame.configKey = configKey;
		catFrame:Show();
		
		catText = catFrame:CreateFontString( catFrame:GetName() .. "Text", "BACKGROUND" );
		catText:SetFont( GameFontNormalSmall:GetFont(), 13 );
		catText:SetText( text );
		catText:SetPoint( "TOPLEFT", catFrame, "TOPLEFT", 5, 0 );
		
		local lastObj, objFrame;
		for id, obj in pairs( objs ) do
			if( obj == "FontInstance" ) then
				objFrame = UI:CreateFontInstance( catFrame );
			elseif( obj == "Texture" ) then
				objFrame = UI:CreateTexture( catFrame );
			elseif( obj == "Frame" ) then
				objFrame = UI:CreateFrame( catFrame );
			elseif( obj == "UIObject" ) then
				objFrame = UI:CreateUIObject( catFrame );
			elseif( obj == "Region" ) then
				objFrame = UI:CreateRegion( catFrame );
			end
			
			if( lastObj ) then
				objFrame:SetPoint( "TOPLEFT", lastObj, "TOPLEFT", 0, -25 );
			else
				objFrame:SetPoint( "TOPLEFT", configFrame, "TOPLEFT", 10, -25 );
			end
			
			objFrame:SetWidth( configFrame:GetWidth() );
			catFrame:SetHeight( catFrame:GetHeight() + objFrame:GetHeight() );
			lastObj = objFrame;
		end
		
		if( i > 1 ) then
			catFrame:SetPoint( "TOPLEFT",  configFrame:GetName() .. ( i - 1 ), "BOTTOMLEFT", 0, -10 );
		else
			catFrame:SetPoint( "TOPLEFT", configFrame, "TOPLEFT", 0, 0 );
		end
	end
end

function UI:Enable()
	if( true == true ) then
		return
	end
	
	local backdrop = {	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
				tile = false,
				edgeSize = 1,
				tileSize = 5,
				insets = { left = 1, right = 1, top = 1, bottom = 1 } };
				
	-- Create the main window
	self.frame = CreateFrame( "Frame", "NPUI", UIParent );
	
	self.frame:SetClampedToScreen( true );
	self.frame:SetMovable( true );
	self.frame:EnableKeyboard( false );
	
	self.frame:SetHeight( 400 );
	self.frame:SetWidth( 425 );
	
	self.frame:SetBackdrop( backdrop );

	self.frame:SetBackdropColor( 0, 0, 0, 1 );
	self.frame:SetBackdropBorderColor( 0.75, 0.75, 0.75, 1 );
	
	-- Now the title text
	self.frameTitle = self.frame:CreateFontString( self.frame:GetName() .. "Title", "ARTWORK" );

	self.frameTitle:SetFont( GameFontNormalSmall:GetFont(), 16 );
	self.frameTitle:SetPoint( "CENTER", self.frame, "TOP", 0, -12 );
	self.frameTitle:SetText( "Name Plates" );
	

	-- Create the tab frame
	self.tabFrame = CreateFrame( "Frame", self.frame:GetName() .. "Tabs", self.frame );
	self.tabFrame:SetHeight( 400 );
	self.tabFrame:SetWidth( 125 );
	
	self.tabFrame:SetBackdrop( backdrop );

	self.tabFrame:SetBackdropColor( 0, 0, 0, 1 );
	self.tabFrame:SetBackdropBorderColor( 0.75, 0.75, 0.75, 1 );
	
	-- Add all of the tabs
	self.tabs = {};
	local i = 0;
	for id, text in pairs( tabs ) do
		i = i + 1;

		local tab = CreateFrame( "Button", self.tabFrame:GetName() .. "Row" .. i, self.tabFrame, "UIPanelButtonGrayTemplate" );
		
		tab.clickID = id;
		
		tab:SetFont( GameFontNormalSmall:GetFont(), 10 );
		tab:SetWidth( 120 );
		tab:SetHeight( 15 );
		tab:SetText( text );
		tab:Show();
		
		if( i > 1 ) then
			tab:SetPoint( "CENTER", getglobal( self.tabFrame:GetName() .. "Row" .. ( i - 1 ) ), "TOP", 0, -27 );
		else
			tab:SetPoint( "CENTER", self.tabFrame, "TOP", 0, -15 ); 		
		end
	end
	
	-- Display
	self.tabFrame:SetPoint( "TOPRIGHT", self.frame, "TOPLEFT", -10, 0 );
	self.frame:SetPoint( "CENTER", "UIParent", "CENTER", 25, 0 );
	
	self.tabFrame:Show();
	self.frame:Show();
	
	self:CreateConfig( "test", "FontInstance", "Frame", "UIObject", "Region" );
end
local MAX_TABS = 20;

local LoadedAddons = {};
local RegisteredUI = {};

local L = SSUILocals;

SSUI = {};

local function SortPriorityList( frame )
	for id, row in pairs( frame.list ) do
		if( row[1] <= 1 ) then
			getglobal( frame:GetName() .. "Row" .. id .. "Up" ):Disable();
			getglobal( frame:GetName() .. "Row" .. id .. "Down" ):Enable();

		elseif( row[1] >= #( frame.list ) ) then
			getglobal( frame:GetName() .. "Row" .. id .. "Down" ):Disable();
			getglobal( frame:GetName() .. "Row" .. id .. "Up" ):Enable();
		else
			getglobal( frame:GetName() .. "Row" .. id .. "Up" ):Enable();
			getglobal( frame:GetName() .. "Row" .. id .. "Down" ):Enable();
		end
		
		getglobal( frame:GetName() .. "Row" .. id .. "Text" ):SetText( row[3] );
		getglobal( frame:GetName() .. "Row" .. id .. "Priority" ):SetText( row[1] );
		getglobal( frame:GetName() .. "Row" .. id ):Show();
	end
end

function SSUI:MovePriorityUp()
	local frame = this:GetParent():GetParent();
	local text = getglobal( this:GetParent():GetName() .. "Text" ):GetText();
	
	for id, row in pairs( frame.list ) do
		if( row[3] == text ) then
			if( row[1] > 1 ) then
				frame.varData[2] = row[2];
				frame.list[ id ][1] = row[1] - 1;
				
				SortPriorityList( frame );
				SSUI:SetVariable( frame.varType, frame.varData, frame.list[ id ][1] );			
				return;
			end
		end
	end
end

function SSUI:MovePriorityDown()
	local frame = this:GetParent():GetParent();
	local text = getglobal( this:GetParent():GetName() .. "Text" ):GetText();
	
	for id, row in pairs( frame.list ) do
		if( row[3] == text ) then
			if( row[1] < #( frame.list ) ) then
				frame.varData[2] = row[2];
				frame.list[ id ][1] = row[1] + 1;
				
				SortPriorityList( frame );
				SSUI:SetVariable( frame.varType, frame.varData, frame.list[ id ][1] );			
				return;
			end
		end
	end
end

local function CreatePriorityList( id, page, element )
	table.sort( element.list, function( a, b )
		if( a[1] == b[1] ) then
			return ( a[3] > b[3] );
		end
		
		return ( a[1] < b[1] );
	end );

	local frame = CreateFrame( "Frame", element.parent .. "Option" .. id, getglobal( element.parent ) );
	frame:SetFrameStrata( "MEDIUM" );
	
--[[
	frame:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				tile = true,
				tileSize = 9,
				insets = { left = 2, right = 2, top = 2, bottom = 2 } });	
	frame:SetBackdropColor( 0, 0, 0, 1 );
]]

	frame:SetWidth( 225 );
	frame:EnableMouse( true );
	
	frame.list = element.list;
	frame.frameType = "priority";
	frame.varType = element.varType or page;
	frame.varData = element.var;
	frame.OnChange = element.OnChange;
	frame.arg1 = element.arg1;
	frame.tooltipText = element.tooltip;
	
	frame:SetScript( "OnEnter", SSUI.ShowTooltip );
	frame:SetScript( "OnLeave", SSUI.HideTooltip );
	
	local infoText = frame:CreateFontString( frame:GetName() .. "InfoText", "BACKGROUND", "GameFontNormal" );
	infoText:SetPoint( "TOPLEFT", frame, "TOPLEFT", 9, 13 );
	infoText:SetText( element.text );
	
	local row, text, priority, up, down;
	
	for i=1, 10 do
		row = CreateFrame( "Frame", frame:GetName() .. "Row" .. i, frame );
		text = row:CreateFontString( row:GetName() .. "Text", "BACKGROUND", "GameFontNormalSmall" );
		priority = row:CreateFontString( row:GetName() .. "Priority", "BACKGROUND", "GameFontNormal" );

		up = CreateFrame( "Button", row:GetName() .. "Up", row, "UIPanelScrollUpButtonTemplate" );
		down = CreateFrame( "Button", row:GetName() .. "Down", row, "UIPanelScrollDownButtonTemplate" );
		
		up:SetScript( "OnClick", SSUI.MovePriorityUp );
		down:SetScript( "OnClick", SSUI.MovePriorityDown );
		
		text:SetPoint( "TOPLEFT", row, "TOPLEFT", 5, -5 );
		priority:SetPoint( "TOPRIGHT", up, "TOPRIGHT", 16, 0 );

		up:SetPoint( "TOPRIGHT", row, "TOPRIGHT", -60, -3 );
		down:SetPoint( "TOPRIGHT", up, "TOPRIGHT", 40, 0 );

		row:SetHeight( 20 );
		row:SetWidth( 225 );
		
		if( i > 1 ) then
			row:SetPoint( "TOPLEFT", getglobal( frame:GetName() .. "Row" .. ( i - 1 ) ), "TOPLEFT", 0, -25 );
		else
			row:SetPoint( "TOPLEFT", frame, "TOPLEFT", 5, -5 );
		end
		
		row:Hide();
	end
	
	frame:SetHeight( #( element.list ) * 27 );
	
	SortPriorityList( frame );
end

local function CreateCheckBox( id, page, element )
	local frame = CreateFrame( "CheckButton", element.parent .. "Option" .. id, getglobal( element.parent ), "SSCheckBoxTemplate" );
	
	frame.frameType = "check";
	frame.varType = element.varType or page;
	frame.varData = element.var;
	frame.OnChange = element.OnChange;
	frame.arg1 = element.arg1;
	frame.tooltipText = element.tooltip;
	
	getglobal( frame:GetName() .. "Text" ):SetText( element.text );
	frame:SetChecked( SSUI:GetVariable( frame.varType, element.var ) );
end

local function CreateButton( id, page, element )
	local frame = CreateFrame( "Button", element.parent .. "Option" .. id, getglobal( element.parent ), "SSButtonTemplate" );

	frame:SetWidth( element.width or ( frame:GetTextWidth() + 20 ) );
	if( element.height ) then
		frame:SetHeight( element.height );
	end
	
	frame.frameType = "button"
	frame.OnChange = element.OnChange;
	frame.arg1 = element.arg1;
	frame.tooltipText = element.tooltip;
	
	frame:SetText( element.text );
end

local function CreateInput( id, page, element )
	local frame = CreateFrame( "EditBox", element.parent .. "Option" .. id, getglobal( element.parent ), "SSInputTemplate" );

	if( element.width ) then
		frame:SetWidth( element.width );
	end
	
	if( element.maxLetters ) then
		frame:SetMaxLetters( element.maxLetters );
	end
	
	frame.frameType = "input"
	frame.varType = element.varType or page;
	frame.varData = element.var;
	frame.forceType = element.forceType;
	frame.OnChange = element.OnChange;
	frame.arg1 = element.arg1;
	frame.tooltipText = element.tooltip;
	
	getglobal( frame:GetName() .. "Text" ):SetText( element.text );
	frame:SetText( SSUI:GetVariable( frame.varType, element.var ) or "" );
end

local function CreateSlider( id, page, element )
	local frame = CreateFrame( "Slider", element.parent .. "Option" .. id, getglobal( element.parent ), "SSSliderTemplate" );

	-- Variables
	frame.frameType = "slider";
	frame.varType = element.varType or page;
	frame.varData = element.var;
	
	-- Visual data
	frame.showValue = element.showValue;
	frame.originalText = element.text;
	frame.OnChange = element.OnChange;
	frame.arg1 = element.arg1;
	frame.tooltipText = element.tooltip;

	-- Usage variables
	frame:SetMinMaxValues( element.minValue or 0.0, element.maxValue or 1.0 );
	frame:SetValueStep( element.valueStep or 0.01 );
	frame:SetValue( SSUI:GetVariable( frame.varType, element.var ) );

	-- Change min/max text if needed
	if( element.minText ) then
		getglobal( frame:GetName() .. "Low" ):SetText( element.minText );
	else
		getglobal( frame:GetName() .. "Low" ):SetText( L.ZERO_PERCENT );
	end

	if( element.maxText ) then
		getglobal( frame:GetName() .. "High" ):SetText( element.maxText );
	else
		getglobal( frame:GetName() .. "High" ):SetText( L.HUNDRED_PERCENT );
	end

	if( element.showValue ) then
		local value = SSUI:GetVariable( frame.varType, element.var );
		if( value > 0.0 ) then
			value = value * 100;	
		end

		getglobal( frame:GetName() .. "Text" ):SetText( string.format( element.text, value ) );			
	else
		getglobal( frame:GetName() .. "Text" ):SetText( element.text );
	end
end

local function CreateDropdown( id, page, element )
	local frame = CreateFrame( "Frame", element.parent .. "Option" .. id, getglobal( element.parent ), "SSDropDownTemplate" );
	
	-- Load the required data
	frame.frameType = "dropdown"
	frame.varType = element.varType or page;
	frame.varData = element.var;
	frame.list = element.list;
	frame.OnChange = element.OnChange;
	frame.arg1 = element.arg1;
	frame.tooltipText = element.tooltip;

	if( #( element.list ) > 0 ) then
		local selected = SSUI:GetVariable( frame.varType, element.var );
		UIDropDownMenu_SetSelectedID( frame, selected );

		for index, row in pairs( element.list ) do
			if( index == selected or row[1] == selected ) then
				UIDropDownMenu_SetText( row[2], frame );
			end
		end
	end	

	if( getglobal( frame:GetName() .. "InfoText" ) ) then
		getglobal( frame:GetName() .. "InfoText" ):SetText( element.text );
	end
end

local function CreateColorPicker( id, page, element )
	local frame = CreateFrame( "Button", element.parent .. "Option" .. id, getglobal( element.parent ), "SSColorPickerTemplate" );
	
	frame.frameType = "color";
	frame.varType = element.varType or page;
	frame.varData = element.var;
	frame.OnChange = element.OnChange;
	frame.arg1 = element.arg1;
	frame.tooltipText = element.tooltip;

	local color = SSUI:GetVariable( frame.varType, element.var );
	getglobal( frame:GetName() .. "NormalTexture" ):SetVertexColor( color.r, color.g, color.b );
	getglobal( frame:GetName() .. "Text" ):SetText( element.text );
end

function SSUI:ShowTooltip()
	if( this.tooltipText ) then
		GameTooltip:SetOwner( this, "ANCHOR_RIGHT" );
		GameTooltip:SetText( this.tooltipText, nil, nil, nil, nil, 1 );
	end
end

function SSUI:HideTooltip()
	GameTooltip:Hide();
end

function SSUI:ShowConfig( page )
	-- Find out about any addons that are using this
	SSUI:ScanAndLoad( page );
	
	-- Still no registered data, error out
	if( not RegisteredUI[ page ] ) then
		SSUI:Message( string.format( L.NOPAGE_FOUND, page ) );
		return;
	end
	
	if( not SSUI_Config ) then
		SSUI_Config = {};
	end

	local UI = RegisteredUI[ page ];
	
	-- Create the UI frame if it doesn't exist already
	local configName = "SSUI_" .. page;
	local configFrame;
	if( not getglobal( configName ) ) then
		configFrame = CreateFrame( "Frame", configName, UIParent, "SSUITemplate" );
		configFrame.tabs = 0;
		configFrame.page = page;

		table.insert( UISpecialFrames, configName );
	else
		configFrame = getglobal( configName );
	end
	
	if( SSUI_Config[ page ] ) then
		configFrame:SetPoint( "TOPLEFT", UIParent, "BOTTOMLEFT", SSUI_Config[ page ].x, SSUI_Config[ page ].y );
	end
	
	-- Set the default tab to open
	configFrame.openTab = UI.defaultTab;
	configFrame:Show();
	
	-- Create/show/hide tabs
	for i=1, MAX_TABS do
		local name = configName .. "Tab" .. i;
		local button = getglobal( name );
		
		if( UI.tabs[ i ] ) then
			if( not button and configFrame.tabs < MAX_TABS ) then
				button = CreateFrame( "Button", name, configFrame, "SSTabButtonTemplate" );
				if( i > 1 ) then
					button:SetPoint( "LEFT", configName .. "Tab" .. i - 1, "LEFT", 0, -21 );
				else
					button:SetPoint( "LEFT", configFrame, "TOPLEFT", 14, -32 );		
				end
				
				configFrame.tabs = configFrame.tabs + 1;
			end
						
			button.openFrame = UI.tabs[ i ].frame;
			button:SetText( UI.tabs[ i ].text );
			button:Show();
			
		elseif( button ) then
			button:Hide();
		end
	end
	
	-- Now create the configuration frames
	for _, tab in pairs( UI.tabs ) do
		if( not getglobal( tab.frame ) ) then
			local frame = CreateFrame( "Frame", tab.frame, configFrame, "SSConfigTemplate" );
			
			frame.createdElements = 0;
			frame.noElements = true;
			frame:Hide();
		end
	end
	
	-- Add title
	if( UI.title ) then
		getglobal( configName .. "TitleText" ):SetText( UI.title );
	else
		getglobal( configName .. "TitleText" ):SetText( L.SSUI );
	end
	getglobal( configName .. "Title" ):SetWidth( UI.titleWidth or 175 );

	-- Set close text
	getglobal( configName .. "TabClose" ):SetText( L.CLOSE );
	
	-- Create the UI
	for _, element in pairs( UI.elements ) do
		local parent = getglobal( element.parent );
				
		if( parent.noElements ) then
			parent.createdElements = parent.createdElements + 1;

			local name = element.parent .. "Option" .. parent.createdElements;
			if( not getglobal( name ) ) then
				if( element.type == "check" ) then
					CreateCheckBox( parent.createdElements, page, element );

				elseif( element.type == "button" ) then
					CreateButton( parent.createdElements, page, element );

				elseif( element.type == "input" ) then
					CreateInput( parent.createdElements, page, element );

				elseif( element.type == "slider" ) then
					CreateSlider( parent.createdElements, page, element );

				elseif( element.type == "dropdown" ) then
					CreateDropdown( parent.createdElements, page, element );
				
				elseif( element.type == "priority" ) then
					CreatePriorityList( parent.createdElements, page, element );
					
				elseif( element.type == "color" ) then
					CreateColorPicker( parent.createdElements, page, element );
				end

				getglobal( name ):Show();
			end
			
		elseif( element.type == "priority" and getglobal( element.parent .. "Option" .. parent.createdElements ) ) then
			SortPriorityList( getglobal( element.parent .. "Option" .. parent.createdElements ) );
		end
	end
	
	-- Now position everything
	for _, tab in pairs( UI.tabs ) do
		local optionFrame = getglobal( tab.frame );
		local previousType;
		
		optionFrame.noElements = nil;
		
		for i=1, optionFrame.createdElements do
			local row = getglobal( tab.frame .. "Option" .. i );
			local currentType = row.frameType
			
			-- This is basically a quick hack to get positioning working, i'll improve it later
			if( i > 1 ) then
				local posX = 0;
				local posY = -30;
				
				if( previousType ~= currentType ) then
					if( currentType == "priority" ) then
						posX  = -15;
						posY = -157;
						
					elseif( previousType == "check" ) then
						if( currentType == "dropdown" ) then
							posX = -15;
							posY = -40;
						elseif( currentType == "input" ) then
							posX = 10;
						elseif( currentType == "color" ) then
							posX = 5;
						end
						
					elseif( previousType == "input" ) then
						if( currentType == "check" ) then
							posX = -10;
						elseif( currentType == "button" ) then
							posX = -7;
						elseif( currentType == "dropdown" ) then
							posX = -22;
							posY = -40;
						end
					elseif( previousType == "color" ) then
						if( currentType == "dropdown" ) then
							posX = -18;
							posY = -35;
						elseif( currentType == "input" ) then
							posX = 5;
						elseif( currentType == "slider" ) then
							posY = -40;
						end
						
					elseif( previousType == "dropdown" ) then
						if( currentType == "slider" ) then
							posX = 17;
							posY = -40;
						elseif( currentType == "color" ) then
							posX = 20;
							posY = -40;
						elseif( currentType == "check" ) then
							posY = -40;
							posX = 15;
						end
					end
				
				elseif( currentType == "slider" ) then
					posY = -40;
				end
				
				row:SetPoint( "LEFT", tab.frame .. "Option" .. i - 1, "LEFT", posX, posY );
			else
				row:SetPoint( "TOPLEFT", optionFrame, "TOPLEFT", 10, -10 );
			end
			
			previousType = currentType;
		end
	end
	
	-- Now open the page for the default tab
	SSUI:OpenTab( getglobal( configFrame.openTab ) );
end

function SSUI:DropDown_Initialize()
	local frame;
	if( string.find( this:GetName(), "Button$" ) ) then
		frame = getglobal( string.gsub( this:GetName(), "Button$", "" ) );
	else
		frame = this;
	end
		
	for id, row in pairs( frame.list ) do
		UIDropDownMenu_AddButton( { value = row[1], text = row[2], owner = frame, func = SSUI.DropDown_OnClick } );
	end
end

function SSUI:DropDown_OnClick()
	local frame = this.owner;

	UIDropDownMenu_SetSelectedID( frame, this:GetID() );
	for index, row in pairs( frame.list ) do
		if( index == this:GetID() ) then
			SSUI:SetVariable( frame.varType, frame.varData, row[1] );			
		end
	end
	
	this.ChangeArg1 = frame.arg1;
	
	if( frame.OnChange ) then
		if( type( frame.OnChange ) == "string" ) then
			getglobal( frame.OnChange )( frame.arg1 );
		elseif( type( frame.OnChange ) == "function" ) then
			frame.OnChange( frame.arg1 );
		end
	end
end

function SSUI:CheckBox_OnClick()
	if( this:GetChecked() ) then
		SSUI:SetVariable( this.varType, this.varData, true );
	else
		SSUI:SetVariable( this.varType, this.varData, false );	
	end
	
	if( this.OnChange ) then
		if( type( this.OnChange ) == "string" ) then
			getglobal( this.OnChange )( this.arg1 );
		elseif( type( this.OnChange ) == "function" ) then
			this.OnChange( this.arg1 );
		end
	end
end

function SSUI:Slider_OnValueChanged()
	SSUI:SetVariable( this.varType, this.varData, this:GetValue() );

	if( this.showValue ) then
		local value = SSUI:GetVariable( this.varType, this.varData );
		if( value > 0.0 ) then
			value = value * 100;	
		end

		getglobal( this:GetName() .. "Text" ):SetText( string.format( this.originalText, value ) );			
	end
	
	if( this.OnChange ) then
		if( type( this.OnChange ) == "string" ) then
			getglobal( this.OnChange )( this.arg1 );
		elseif( type( this.OnChange ) == "function" ) then
			this.OnChange( this.arg1 );
		end
	end
end

function SSUI:OpenColorPicker()
	local color = SSUI:GetVariable( this.varType, this.varData );
	
	ColorPickerFrame.varType = this.varType;
	ColorPickerFrame.varData = this.varData;
	ColorPickerFrame.OnChange = this.OnChange;
	ColorPickerFrame.ChangeArg1 = this.arg1;
	ColorPickerFrame.buttonName = this:GetName();
	
	ColorPickerFrame.func = SSUI.SetColor;
	ColorPickerFrame.cancelFunc = SSUI.CancelColor;

	ColorPickerFrame.previousValues = { r = color.r, g = color.g, b = color.b };
	ColorPickerFrame:SetColorRGB( color.r, color.g, color.b );
	ColorPickerFrame:Show();
end

function SSUI:SetColor()
	local r, g, b = ColorPickerFrame:GetColorRGB();
	getglobal( ColorPickerFrame.buttonName .. "NormalTexture" ):SetVertexColor( r, g, b );
	
	SSUI:SetVariable( ColorPickerFrame.varType, ColorPickerFrame.varData, { r = r, g = g, b = b } );
	if( ColorPickerFrame.OnChange ) then
		if( type( ColorPickerFrame.OnChange ) == "string" ) then
			getglobal( ColorPickerFrame.OnChange )( ColorPickerframe.ChangeArg1 );
		elseif( type( ColorPickerFrame.OnChange ) == "function" ) then
			ColorPickerFrame.OnChange( ColorPickerFrame.ChangeArg1 );
		end
	end
end

function SSUI:CancelColor( prevColor )
	getglobal( ColorPickerFrame.buttonName .. "NormalTexture" ):SetVertexColor( prevColor.r, prevColor.g, prevColor.b );
	
	SSUI:SetVariable( ColorPickerFrame.varType, ColorPickerFrame.varData, prevColor );
	if( ColorPickerFrame.OnChange ) then
		if( type( ColorPickerFrame.OnChange ) == "string" ) then
			getglobal( ColorPickerFrame.OnChange )( ColorPickerframe.ChangeArg1 );
		elseif( type( ColorPickerFrame.OnChange ) == "function" ) then
			ColorPickerFrame.OnChange( ColorPickerFrame.ChangeArg1 );
		end
	end
end

function SSUI:EditBox_TextChanged()
	local value = this:GetText();
	if( this.forceType == "int" ) then
		value = tonumber( value ) or 0;
	end
	
	SSUI:SetVariable( this.varType, this.varData, value );
	
	if( this.OnChange ) then
		if( type( this.OnChange ) == "string" ) then
			getglobal( this.OnChange )( this.arg1 );
		elseif( type( this.OnChange ) == "function" ) then
			this.OnChange( this.arg1 );
		end
	end
end

function SSUI:Button_OnClick()
	if( this.OnChange ) then
		if( type( this.OnChange ) == "string" ) then
			getglobal( this.OnChange )( this.arg1 );
		elseif( type( this.OnChange ) == "function" ) then
			this.OnChange( this.arg1 );
		end
	end
end

function SSUI:TabButton_OnClick()
	SSUI:OpenTab( getglobal( this.openFrame ) );
end

function SSUI:GetVariable( page, var )
	if( type( RegisteredUI[ page ].get ) == "string" ) then
		return getglobal( RegisteredUI[ page ].get )( var );
	elseif( type( RegisteredUI[ page ].get ) == "function" ) then
		return RegisteredUI[ page ].get( var );
	end
end

function SSUI:SetVariable( page, var, value )
	if( type( RegisteredUI[ page ].set ) == "string" ) then
		getglobal( RegisteredUI[ page ].set )( var, value );
	elseif( type( RegisteredUI[ page ].set ) == "function" ) then
		RegisteredUI[ page ].set( var, value );
	end
end

function SSUI:OpenTab( openTab )
	for i=1, openTab:GetParent().tabs do
		local tab = getglobal( openTab:GetParent():GetName() .. "Tab" .. i );
		
		getglobal( tab.openFrame ):Hide();
	end
	
	openTab:Show();
end

function SSUI:SavePosition()
	local page = this:GetParent().page;
	if( not SSUI_Config[ page ] ) then
		SSUI_Config[ page ] = {};
	end
	
	SSUI_Config[ page ].x, SSUI_Config[ page ].y = this:GetParent():GetLeft(), this:GetParent():GetTop();
end

function SSUI:ResetPosition()
	SSUI_Config[ this:GetParent().page ] = nil;
end

function SSUI:Hide()
	this:GetParent():Hide();
end

function SSUI:Message( msg )
	DEFAULT_CHAT_FRAME:AddMessage( msg );
end

function SSUI:RegisterUI( page, data )
	if( not RegisteredUI[ page ] ) then
		RegisteredUI[ page ] = data;
		RegisteredUI[ page ].tabs = {};
		RegisteredUI[ page ].elements = {};
		
		-- Search for anything that was registered before us
		-- that wants to use our frame
		for frame, UI in pairs( RegisteredUI ) do
			if( UI.mainPage == page ) then
				for _, tab in pairs( UI.tabs ) do
					SSUI:RegisterTab( frame, tab.frame, tab.text, tab.position );
				end
				
				for _, element in pairs( UI.elements ) do
					SSUI:RegisterElement( frame, element );
				end
				
				RegisteredUI[ frame ].tabs = {};
				RegisteredUI[ frame ].elements = {};
			end
		end
	end
end

function SSUI:RegisterElement( page, data )
	-- Another mod is registering for a mods page, so switch it if it exists
	if( RegisteredUI[ page ].mainPage and RegisteredUI[ RegisteredUI[ page ].mainPage ] ) then
		data.varType = page;
		page = RegisteredUI[ page ].mainPage;
	end
	
	table.insert( RegisteredUI[ page ].elements, data );
end

function SSUI:RegisterTab( page, frame, text, position )
	-- Another mod is registering for a mods page, so switch it if it exists
	if( RegisteredUI[ page ].mainPage and RegisteredUI[ RegisteredUI[ page ].mainPage ] ) then
		page = RegisteredUI[ page ].mainPage;
	end

	for _, tab in pairs( RegisteredUI[ page ].tabs ) do
		if( tab.frame == frame ) then
			return;
		end
	end
	
	table.insert( RegisteredUI[ page ].tabs, { frame = frame, text = text, position = position or 9999 } );

	-- Sort the tabs
	table.sort( RegisteredUI[ page ].tabs, function( a, b )
		return ( a.position < b.position );
	end );
end

function SSUI:ScanAndLoad( page )
	for i=1, GetNumAddOns() do
		local name, _, _, _, _, status = GetAddOnInfo( i );
		
		if( not LoadedAddons[ name ] and status ~= "DISABLED" and GetAddOnMetadata( name, "X-SSUI" ) and GetAddOnMetadata( name, "X-SSUI" ) == page ) then
			UIParentLoadAddOn( name );
			local addon = getglobal( name );
			
			if( addon and type( addon.LoadUI ) == "function" ) then
				addon.LoadUI();
				LoadedAddons[ name ] = true;

			elseif( getglobal( name .. "_LoadUI" ) ) then
				getglobal( name .. "_LoadUI" )();		
				LoadedAddons[ name ] = true;
			end			
		end
	end
end
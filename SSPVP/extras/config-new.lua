local UI = SSPVP:NewModule( "SSPVP-UI" )

local L = SSPVPLocals
local categories
local soundPlaying
local UIList

function UI:Initialize()
	--SSPVP.cmd:RegisterSlashHandler( L["on - Enables SSPVP"], "on", self.CmdEnable )
	--SSPVP.cmd:RegisterSlashHandler( L["off - Disables SSPVP"], "off", self.CmdDisable )	
	--SSPVP.cmd:RegisterSlashHandler( L["ui - Pulls up the configuration page."], "ui", self.OpenUI )
	--SSPVP.cmd:RegisterSlashHandler( L["map - Toggles the battlefield minimap regardless of being inside a battleground."], "map", self.ToggleMinimap )
	
	categories = {
		["General"] = {L["General"], {
			["AutoQueue"] = L["Auto Queue"],
			["Mover"] = L["Frame Moving"],
		}},
		["AutoJoin"] = {L["Auto Join"], {
			["Priorities"] = L["Priorities"],
		}},
	}

	local OptionHouse = DongleStub("OptionHouse-1.0")
	local obj = OptionHouse:RegisterAddOn( "SSPVP", nil, "Amarand", "r" .. tonumber( string.match( "$Revision: 60 $", "(%d+)" ) or 1 ) )
	
	for _, cat in pairs(categories) do
		obj:RegisterCategory(cat[1], self, "LoadFrame", true)
		
		if( type(cat[2]) == "table" ) then
			for _, subName in pairs(cat[2]) do
				obj:RegisterSubCategory(cat[1], subName, self, "LoadFrame", true)
			end
		end
	end
end

-- VAR MANAGEMENT
function UI:SetValue( vars, val )
	if( #( vars ) == 3 ) then
		SSPVP.db.profile[ vars[1] ][ vars[2] ][ vars[3] ] = val
	elseif( #( vars ) == 2 ) then
		SSPVP.db.profile[ vars[1] ][ vars[2] ] = val
	elseif( #( vars ) == 1 ) then
		SSPVP.db.profile[ vars[1] ] = val
	end
end

function UI:GetValue( vars )
	if( #( vars ) == 3 ) then
		return SSPVP.db.profile[ vars[1] ][ vars[2] ][ vars[3] ]
	elseif( #( vars ) == 2 ) then
		return SSPVP.db.profile[ vars[1] ][ vars[2] ]
	elseif( #( vars ) == 1 ) then
		return SSPVP.db.profile[ vars[1] ]
	end
	
	return nil
end

-- CHECKBOX
function UI.OnCheck( self )
	if( self:GetChecked() ) then
		UI:SetValue( self.vars, true )
	else
		UI:SetValue( self.vars, false )
	end

	if( self.func ) then
		self.func(self, self.args)
	end
end

function UI:CreateCheckBox( parent, text, func, vars, args )
	local name = parent:GetName() .. "Option" .. ( parent.id or 1 )
	parent.id = ( parent.id or 1 ) + 1
	
	local check = CreateFrame( "CheckButton", name, parent, "OptionsCheckButtonTemplate" )
	check.args = args
	check.func = func
	check.vars = vars
	check:SetScript( "OnClick", UI.OnCheck )
	check:SetChecked( UI:GetValue( check.vars ) )
		
	getglobal( name .. "Text" ):SetText( text )
	
	return check
end

-- EDIT BOXES
function UI.OnTextChanged( self )
	UI:SetValue( self.vars, self:GetText() )

	if( self.func ) then
		self.func(self, self.args)
	end
end

function UI:CreateInput( parent, infoText, func, vars, args )
	local name = parent:GetName() .. "Option" .. ( parent.id or 1 )
	parent.id = ( parent.id or 1 ) + 1
	
	local input = CreateFrame( "EditBox", name, parent, "InputBoxTemplate" )
	input.func = func
	input.args = args
	input.vars = vars
	input:SetAutoFocus(false)
	input:SetScript( "OnTextChanged", UI.OnTextChanged )
	input:SetText( UI:GetValue( input.vars ) )
	input:SetHeight(20)
	input:SetWidth(120)
	
	local text = input:CreateFontString( name .. "Text", input, "GameFontNormalSmall" )
	text:SetPoint( "LEFT", input, "RIGHT", 5, 0 )
	text:SetText( infoText )
	
	return input
end

-- DROPDOWN
function UI.DropdownShown( self )
	UIDropDownMenu_Initialize( self, UI.InitDropdown )
end

function UI.DropdownClicked()
	local frame = this.owner
	
	for index, row in pairs( frame.list ) do
		if( index == this:GetID() ) then
			UI:SetValue( frame.vars, row[1] )

			UIDropDownMenu_SetText(row[2], frame)
			UIDropDownMenu_SetSelectedValue(frame, row[1])
		end
	end
	
	if( frame.func ) then
		frame.func( this )
	end
end

function UI:InitDropdown()
	local frame = this
	if( string.find( this:GetName(), "Button$" ) ) then
		frame = getglobal( string.gsub( this:GetName(), "Button$", "" ) )
	end

	for id, row in pairs( frame.list ) do
		UIDropDownMenu_AddButton( { value = row[1], text = row[2], owner = frame, func = UI.DropdownClicked } )
	end
end

function UI:CreateDropdown( parent, infoText, list, func, vars, args )
	local name = parent:GetName() .. "Option" .. ( parent.id or 1 )
	parent.id = ( parent.id or 1 ) + 1
	
	local frame = CreateFrame( "Frame", name, parent, "UIDropDownMenuTemplate" )
	frame:SetScript( "OnShow", UI.DropdownShown )
	frame.list = list
	frame.func = func
	frame.vars = vars
	frame.args = args
	
	local text = frame:CreateFontString( name .. "Text", frame, "GameFontNormalSmall" )
	text:SetPoint( "LEFT", frame, "RIGHT", 120, 3 )
	text:SetText( infoText )
	
	local selected = UI:GetValue(frame.vars)
	for index, row in pairs(list) do
		if( selected == row[1] ) then
			UIDropDownMenu_SetText(row[2], frame)
			UIDropDownMenu_SetSelectedValue(frame, row[1])
		end
	end
	
	return frame
end

-- COLOR PICKER
function UI.ColorEntered( self )
	getglobal( self:GetName().."Border" ):SetVertexColor( NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b )
end

function UI.ColorLeft( self )
	getglobal( self:GetName().."Border" ):SetVertexColor( HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b )
end

function UI:SetColor()
	local r, g, b = ColorPickerFrame:GetColorRGB()

	getglobal( ColorPickerFrame.buttonName .. "NormalTexture" ):SetVertexColor( r, g, b )
	UI:SetValue( ColorPickerFrame.vars, { r = r, g = g, b = b } )
	
	if( ColorPickerFrame.callbackFunc ) then
		ColorPickerFrame.callbackFunc()
	end
end

function UI:CancelColor( previous )
	getglobal( ColorPickerFrame.buttonName .. "NormalTexture" ):SetVertexColor( prevous.r, previous.g, previous.b )
	UI:SetValue( ColorPickerFrame.vars, previous )
	
	if( ColorPickerFrame.callbackFunc ) then
		ColorPickerFrame.callbackFunc(ColorPickerFrame.callbackArgs)
	end
end

function UI.OpenPicker( self )
	local color = UI:GetValue( self.vars )
	
	ColorPickerFrame.buttonName = self:GetName()
	ColorPickerFrame.vars = self.vars
	ColorPickerFrame.callbackFunc = self.func
	ColorPickerFrame.callbackArgs = self.args
	ColorPickerFrame.func = UI.SetColor
	ColorPickerFrame.cancelFunc = UI.CancelColor
	
	ColorPickerFrame.previousValues = color
	ColorPickerFrame:SetColorRGB( color.r, color.g, color.b )
	ColorPickerFrame:Show()
end

function UI:CreateColor( parent, infoText, func, vars, args )
	local name = parent:GetName() .. "Option" .. ( parent.id or 1 )
	parent.id = ( parent.id or 1 ) + 1
	
	local button = CreateFrame( "Button", name, parent )
	button:SetHeight( 18 )
	button:SetWidth( 18 )
	button:SetScript( "OnClick", UI.OpenPicker )
	button:SetScript( "OnEnter", UI.ColorEntered )
	button:SetScript( "OnLeave", UI.ColorLeft )
	button:GetNormalTexture():SetTexture( "Interface\\ChatFrame\\ChatFrameColorSwatch" )
	button.vars = vars
	button.func = func
	button.args = args
	
	local border = button:CreateTexture( name .. "Border", "BACKGROUND" )
	border:SetHeight( 16 )
	border:SetWidth( 16 )
	border:SetPoint( "CENTER", 0, 0 )
	border:SetTexture( 1, 1, 1 )
	
	local text = button:CreateFontString( name .. "Text", input, "GameFontNormalSmall" )
	text:SetPoint( "LEFT", button, "RIGHT", 7, 0 )
	text:SetText( infoText )
	
	return button
end

-- SLIDERS
function UI.SliderChanged( self )
	UI:SetValue( self.vars, self:GetValue() )
	
	if( self.func ) then
		self.func(self, self.args)
	end
end

function UI:CreateSlider( parent, infoText, func, vars, args )
	local name = parent:GetName() .. "Option" .. ( parent.id or 1 )
	parent.id = ( parent.id or 1 ) + 1
	
	local frame = CreateFrame( "Slider", name, parent, "OptionsSliderTemplate" )
	frame.vars = vars
	frame.func = func
	frame.args = args
	frame:SetWidth( 140 )
	frame:SetHeight( 16 )
	frame:SetScript( "OnValueChanged", UI.SliderChanged )
	frame:SetMinMaxValues( 0.0, 1.0 )
	frame:SetValueStep( 0.01 )
	frame:SetValue( UI:GetValue( frame.vars ) )

	getglobal( name .. "Low" ):SetText( "0%" )
	getglobal( name .. "High" ):SetText( "100%" )
	getglobal( name .. "Text" ):SetText( infoText )

	return frame
end

-- BUTTON
function UI.ButtonClicked( self )
	if( self.func ) then
		self.func(self, self.args)
	end
end

function UI:CreateButton( parent, text, func, args )
	local name = parent:GetName() .. "Option" .. ( parent.id or 1 )
	parent.id = ( parent.id or 1 ) + 1
	
	local frame = CreateFrame("Button", name, parent, "GameMenuButtonTemplate")
	frame.args = args
	frame:SetScript("OnClick", UI.ButtonClicked)
	frame:SetText(text)
	frame:SetWidth( frame:GetTextWidth() )
	frame:SetHeight( 18 )
	
	return frame
end

-- PRIORITY WIDGET
local function UpdatePriorityList( frame )
	for id, row in pairs( frame.list ) do
		if( row[1] <= 1 ) then
			getglobal(frame:GetName() .. "Row" .. id .. "Up"):Disable()
			getglobal(frame:GetName() .. "Row" .. id .. "Down"):Enable()

		elseif( row[1] >= #( frame.list ) ) then
			getglobal(frame:GetName() .. "Row" .. id .. "Down"):Disable()
			getglobal(frame:GetName() .. "Row" .. id .. "Up"):Enable()
		else
			getglobal(frame:GetName() .. "Row" .. id .. "Up"):Enable()
			getglobal(frame:GetName() .. "Row" .. id .. "Down"):Enable()
		end
		
		getglobal(frame:GetName() .. "Row" .. id .. "Text"):SetText(row[3])
		getglobal(frame:GetName() .. "Row" .. id .. "Priority"):SetText(row[1])
		getglobal(frame:GetName() .. "Row" .. id):Show()
	end
end

local function MovePriorityUp( self )
	local frame = self:GetParent():GetParent()
	local text = getglobal( self:GetParent():GetName() .. "Text" ):GetText();
	
	for id, row in pairs( frame.list ) do
		if( row[3] == text ) then
			if( row[1] > 1 ) then
				frame.list[id][1] = row[1] - 1
				frame.vars[2] = row[2]
								
				UI:SetValue(frame.vars, frame.list[id][1])
				UpdatePriorityList(frame)
				return
			end
		end
	end
end

local function MovePriorityDown( self )
	local frame = self:GetParent():GetParent()
	local text = getglobal( self:GetParent():GetName() .. "Text" ):GetText();

	for id, row in pairs( frame.list ) do
		if( row[3] == text ) then
			if( row[1] < #(frame.list) ) then
				frame.list[id][1] = row[1] + 1
				frame.vars[2] = row[2]
				
				UI:SetValue(frame.vars, frame.list[id][1])
				UpdatePriorityList(frame)
				return
			end
		end
	end
end

function UI:CreatePriority( parent, text, list, vars )
	local name = parent:GetName() .. "Option" .. ( parent.id or 1 )
	parent.id = ( parent.id or 1 ) + 1
	
	table.sort( list, function( a, b )
		if( a[1] == b[1] ) then
			return ( a[3] > b[3] )
		end
		
		return ( a[1] < b[1] )
	end )

	local frame = CreateFrame("Frame", name, parent)
	frame:SetFrameStrata("MEDIUM")
	frame:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 9, insets = { left = 2, right = 2, top = 2, bottom = 2}})	
	frame:SetBackdropColor(0, 0, 0, 1)
	frame:SetWidth(250)
	frame:SetHeight(#(list) * 27)
	frame:EnableMouse(true)
	frame.list = list
	frame.vars = vars
	
	local infoText = frame:CreateFontString(name .. "InfoText", "BACKGROUND", "GameFontNormal")
	infoText:SetPoint("TOPLEFT", frame, "TOPLEFT", 9, 13)
	infoText:SetText(text)
	
	local row, text, priority, up, down
	for i=1, 10 do
		row = CreateFrame("Frame", name .. "Row" .. i, frame)
		text = row:CreateFontString(row:GetName() .. "Text", "BACKGROUND", "GameFontNormalSmall" )
		priority = row:CreateFontString(row:GetName() .. "Priority", "BACKGROUND", "GameFontNormal")

		up = CreateFrame("Button", row:GetName() .. "Up", row, "UIPanelScrollUpButtonTemplate")
		down = CreateFrame("Button", row:GetName() .. "Down", row, "UIPanelScrollDownButtonTemplate")
		
		up:SetScript( "OnClick", MovePriorityUp)
		down:SetScript( "OnClick", MovePriorityDown)
		
		text:SetPoint("TOPLEFT", row, "TOPLEFT", 5, -5)
		priority:SetPoint("TOPRIGHT", up, "TOPRIGHT", 16, 0)

		up:SetPoint("TOPRIGHT", row, "TOPRIGHT", -60, -3)
		down:SetPoint("TOPRIGHT", up, "TOPRIGHT", 40, 0)

		row:SetHeight(20)
		row:SetWidth(250)
		
		if( i > 1 ) then
			row:SetPoint("TOPLEFT", getglobal(name .. "Row" .. ( i - 1 ) ), "TOPLEFT", 0, -25)
		else
			row:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, -5)
		end
		
		row:Hide()
	end
	
	UpdatePriorityList(frame)
	
	return frame
end

function UI:LoadFrame(category, subCat)
	local catFrame, subFrame
	
	-- Not exactly a clean method of getting the frame name
	for frameName, cat in pairs(categories) do
		if( cat[1] == category ) then
			catFrame = frameName
			
			-- Sub category exist and we're viewing a sub cat, so find frame
			if( subCat ~= "" and type(cat[2]) == "table" ) then
				for subCatFrame, subName in pairs(cat[2]) do
					if( subName == subCat ) then
						subFrame = subCatFrame
						break
					end
				end
			end
			
			break
		end
	end
	
	if( not catFrame or ( subCat ~= "" and not subFrame ) ) then
		Debug("No frame or sub frame found")
		Debug(tostring(category) .. "/" .. tostring(subCat))
		Debug(tostring(catFrame) .. "/" .. tostring(subCat))
		return
	end
	
	-- We handle frame caching ourself instead of OH, because we don't
	-- want to recycle frame but I'm lazy and want a single function called for
	-- building the UI so went for this dynamicish way
	-- And it's fancy and fun to do
	local frame = getglobal("SS" .. (subFrame or catFrame))
	if( frame ) then
		return frame
	end
	
	
	self:LoadUI()
	
	local frame = CreateFrame("Frame", "SS" .. (subFrame or catFrame))
	local num = 0

	for _, row in pairs(UIList) do
		-- We don't need the parent category for sub cat configs because the sub category has to be unique anyway
		-- and we can figure out parent just because OH passes it
		if( ( not subFrame and row.parent == catFrame ) or ( subFrame and row.parent == subFrame ) ) then
			local element
			local offsetY = 5
			local offsetX = 0
			
			if( row.type == "check" ) then
				element = self:CreateCheckBox(frame, row.text, row.func, row.var, row.arg1)
				
			elseif( row.type == "input" ) then
				element = self:CreateInput(frame, row.text, row.func, row.var, row.arg1)
				offsetY = 15
				
				if( row.width ) then
					element:SetWidth(row.width)
				end
				
			elseif( row.type == "button" ) then
				element = self:CreateButton(frame, row.text, row.func, row.arg1)
				offsetY = 3
				
				if( row.width ) then
					element:SetWidth(row.width)
				end
			
			elseif( row.type == "dropdown" ) then
				element = self:CreateDropdown(frame, row.text, row.list, row.func, row.var, row.arg1)
				offsetY = -10
				
			elseif( row.type == "color" ) then
				element = self:CreateColor(frame, row.text, row.func, row.var, row.arg1)
			
			elseif( row.type == "slider" ) then
				element = self:CreateSlider(frame, row.text, row.func, row.var, row.arg1)
				
				if( row.minVal ) then
					getglobal(element:GetName() .. "Low"):SetText(row.minText)
					row:SetMinMaxValues(row.minVal, select(2, row:GetMinMaxValues()))
				end
				
				if( row.maxVal ) then
					getglobal(element:GetName() .. "High"):SetText(row.maxText)
					row:SetMinMaxValues((select(1, row:GetMinMaxValues())), row.maxVal)
				end
			
			elseif( row.type == "priority" ) then
				element = self:CreatePriority(frame, row.text, row.list, row.var) 
				offsetX = -20
				offsetY = 0
			end
			
			
			if( element ) then
				num = num + 1
				
				if( num > 1 ) then
					element:SetPoint("TOPLEFT", frame, "TOPLEFT", offsetY, -5 + (-33 * (num - 1)))
				else
					element:SetPoint("TOPLEFT", frame, "TOPLEFT", offsetY, -5 + offsetX)
				end
			end
		end
	end
	
	return frame
end

function UI:Reload( module )
	module = SSPVP:HasModule(module)
	
	if( module and module.Reload ) then
		module.Reload(module)
	end
end

-- We only create the configuration now
-- to avoid it being in memory when 99% of the time you don't care about config
function UI:LoadUI()
	if( UIList ) then
		return
	end
	
	local priorityList = {}
	for key, num in pairs( SSPVP.db.profile.priority ) do
		table.insert( priorityList, { num, key, L[ key ] } )
	end
	
	-- Add the elements
	UIList = {
		-- General
		{ text = L["Enable SSPVP"], func = UI.ToggleSSPVP, type = "check", var = { "general", "enabled" }, parent = "General" },
		{ text = L["Block all messages starting with [SS]"], type = "check", var = { "general", "block" }, parent = "General" },
		{ text = L["Default Channel"], type = "dropdown", list = { { "BATTLEGROUND", L["Battleground"] }, { "RAID", L["Raid"] }, { "PARTY", L["Party"] } },  var = { "general", "channel" }, parent = "General" },
		{ text = L["Enable faction balance overlay"], type = "check", func = self.Reload, arg1 = "SSPVP-Score", var = { "general", "factBalance" }, parent = "General" },
		{ text = L["Auto solo queue when ungrouped"], type = "check", var = { "queue", "autoSolo" }, parent = "AutoQueue" },
		{ text = L["Auto group queue when leader"], type = "check", var = { "queue", "autoGroup" }, parent = "AutoQueue" },
		{ text = L["Lock world PvP objectives"], type = "check", func = self.Reload, arg1 = "SSPVP-Mover", var = { "mover", "world" }, parent = "Mover" },
		{ text = L["Lock battlefield scoreboard"], type = "check", func = self.Reload, arg1 = "SSPVP-Mover", var = { "mover", "score" }, parent = "Mover" },
		{ text = L["Lock capture bars"], type = "check", func = self.Reload, arg1 = "SSPVP-Mover", var = { "mover", "capture" }, parent = "Mover" },
		{ text = L["Sound file"], type = "input", width = 150, var = { "general", "sound" }, parent = "General" },
		{ text = L["Play"], type = "button", width = 100, func = UI.PlaySound, parent = "General" },
 		
 		-- Auto join
 		{ text = L["Enable auto join"], type = "check", var = { "join", "enabled" }, parent = "Join" },
		{ text = L["Battleground join delay"], type = "input", forceType = "int", width = 30, var = { "join", "bgDelay" }, parent = "Join" },
		{ text = L["AFK battleground join delay"], type = "input", forceType = "int", width = 30, var = { "join", "bgAfk" }, parent = "Join" },
		{ text = L["Arena join delay"], type = "input", forceType = "int", width = 30, var = { "join", "arenaDelay" }, parent = "Join" },
		{ text = L["Battlefield auto joining priorities"], list = priorityList, type = "priority", var = { "priority" }, parent = "Priorities" },
 		
 		-- Auto leave
 		{ text = L["Enable auto leave"], type = "check", var = { "leave", "enabled" }, parent = "SSLeave" },
 		{ text = L["Enable confirmation when leaving"], type = "check", var = { "leave", "confirm" }, parent = "SSLeave" },
 		{ text = L["Take score screenshot on game end"], type = "check", var = { "leave", "screen" }, parent = "SSLeave" },
		{ text = L["Auto leave delay"], type = "input", forceType = "int", width = 30, var = { "leave", "delay" }, parent = "SSLeave" },
 		
 		-- Battlefield
 		{ text = L["Auto open minimap when inside a battleground"], type = "check", var = { "bf", "minimap" }, parent = "SSBattlefield" },
 		{ text = L["Auto release when inside an active battlefield"], type = "check", var = { "bf", "release" }, parent = "SSBattlefield" },
 		{ text = L["Auto release even with a soulstone active"], type = "check", var = { "bf", "releaseSS" }, parent = "SSBattlefield" },
 		{ text = L["Auto accept corpse ressurects inside a battlefield"], type = "check", var = { "bf", "autoAccept" }, parent = "SSBattlefield" },
 		{ text = L["Color names by class on score board"], type = "check", var = { "score", "color" }, parent = "SSBattlefield" },
 		{ text = L["Hide class icon next to names on score board"], type = "check", var = { "score", "icon" }, parent = "SSBattlefield" },
 		{ text = L["Show player levels next to names on score board"], type = "check", var = { "score", "level" }, parent = "SSBattlefield" },

 		-- Queue Overlay
		{ text = L["Enable queue overlay"], type = "check", func = SSPVP.Reload, var = { "queue", "enabled" }, parent = "SSQOverlay" },
		{ text = L["Show queue overlay inside battlegrounds"], func = SSPVP.Reload, type = "check", var = { "queue", "insideField" }, parent = "SSQOverlay" },
		{ text = L["Show estimated time until queue is ready"], func = SSPVP.Reload, type = "check", var = { "queue", "showEta" }, parent = "SSQOverlay" },
		{ text = L["Estimated time format"], type = "dropdown", func = SSPVP.Reload, list = { { "hhmmss", L["hh:mm:ss"] }, { "minsec", L["Min X, Sec X"] }, { "min", L["Min X"] } },  var = { "queue", "etaFormat" }, parent = "SSQOverlay" },
 		
 		-- Overlay
		{ text = L["Lock overlay"], type = "check", func = self.Reload, arg1 = "SSPVP-Overlay", var = { "overlay", "locked" }, parent = "SSCOverlay" },
		{ text = L["Timer format"], func = self.Reload, arg1 = "SSPVP-Overlay", type = "dropdown", list = { { "hhmmss", L["hh:mm:ss"] }, { "minsec", L["Min X, Sec X"] }, { "min", L["Min X"] } },  var = { "overlay", "timer" }, parent = "SSCOverlay" },
		{ text = L["Category text type"], func = self.Reload, arg1 = "SSPVP-Overlay", type = "dropdown", list = { { "hide", L["Always hide"] }, { "show", L["Always show"] }, { "auto", L["Auto hiding"] } },  var = { "overlay", "catType" }, parent = "SSCOverlay" },
		{ text = L["Display mode"], func = self.Reload, arg1 = "SSPVP-Overlay", type = "dropdown", list = { { "down", L["Top -> Bottom"] }, { "up", L["Bottom -> Top"] } },  var = { "overlay", "displayType" }, parent = "SSCOverlay" },
		{ text = L["Row padding"], type = "input", func = self.Reload, arg1 = "SSPVP-Overlay", forceType = "int", width = 30, var = { "overlay", "rowPad" }, parent = "SSCOverlay" },
		{ text = L["Category padding"], type = "input", func = self.Reload, arg1 = "SSPVP-Overlay", forceType = "int", width = 30, var = { "overlay", "catPad" }, parent = "SSCOverlay" },
		{ text = L["Background color"], func = self.Reload, arg1 = "SSPVP-Overlay", type = "color", var = { "overlay", "background" }, parent = "SSCOverlay" },
		{ text = L["Border color"], func = self.Reload, arg1 = "SSPVP-Overlay", type = "color", var = { "overlay", "border" }, parent = "SSCOverlay" },
		{ text = L["Text color"], func = self.Reload, arg1 = "SSPVP-Overlay", type = "color", var = { "overlay", "textColor" }, parent = "SSCOverlay" },
		{ text = L["Category text color"], func = self.Reload, arg1 = "SSPVP-Overlay", type = "color", var = { "overlay", "categoryColor" }, parent = "SSCOverlay" },
		{ text = L["Background opacity: %d%%"], func = self.Reload, arg1 = "SSPVP-Overlay", showValue = true, isPercent = true, type = "slider", var = { "overlay", "opacity" }, parent = "SSCOverlay" },
		{ text = L["Text opacity: %d%%"], func = self.Reload, arg1 = "SSPVP-Overlay", showValue = true, isPercent = true, type = "slider", var = { "overlay", "textOpacity" }, parent = "SSCOverlay" },
		
		-- Arena
		{ text = L["Enable enemy team report"], func = self.Reload, arg1 = "SSPVP-Arena", type = "check", var = { "arena", "target" }, parent = "SSCArena" },
		{ text = L["Show enemy number next to name on arena frames"], type = "check", func = self.Reload, arg1 = "SSPVP-Arena", var = { "arena", "enemyNum" }, parent = "SSCArena" },
		{ text = L["Lock team report frame"], type = "check", func = self.Reload, arg1 = "SSPVP-Arena", var = { "arena", "locked" }, parent = "SSCArena" },
		{ text = L["Show enemy health next to name on arena frame"], type = "check", func = self.Reload, arg1 = "SSPVP-Arena", var = { "arena", "showHealth" }, parent = "SSCArena" },
		{ text = L["Show enemy class icon"], type = "check", func = self.Reload, arg1 = "SSPVP-Arena", var = { "arena", "showIcon" }, parent = "SSCArena" },
		{ text = L["Show enemy minions on arena enemy frames"],  type = "check", func = self.Reload, arg1 = "SSPVP-Arena", var = { "arena", "showPets" }, parent = "SSCArena" },
		{ text = L["Enemy pet name color"], type = "color", func = self.Reload, arg1 = "SSPVP-Arena", var = { "arena", "petColor" }, parent = "SSCArena" },
		{ text = L["Border color"], type = "color", func = self.Reload, arg1 = "SSPVP-Arena", var = { "arena", "border" }, parent = "SSCArena" },
		{ text = L["Background color"], type = "color", func = self.Reload, arg1 = "SSPVP-Arena", var = { "arena", "background" }, parent = "SSCArena" },
		{ text = L["Background opacity: %d%%"], func = self.Reload, arg1 = "SSPVP-Arena", showValue = true, isPercent = true, type = "slider", var = { "arena", "opacity" }, parent = "SSCArena" },
		{ text = L["Dead enemy opacity: %d%%"], func = self.Reload, arg1 = "SSPVP-Arena", showValue = true, isPercent = true, type = "slider", var = { "arena", "deadOpacity" }, parent = "SSCArena" },
		{ text = L["Targetting frame scale: %d%%"], func = self.Reload, arg1 = "SSPVP-Arena", showValue = true, isPercent = true, type = "slider", var = { "arena", "scale" }, parent = "SSCArena" },
 		
 		-- Alterac Valley
		{ text = L["Enable capture timers"], type = "check", func = self.Reload, arg1 = "SSPVP-AV", var = { "av", "timers" }, parent = "SSAlteracValley" },
		{ text = L["Enable armor scraps tracking"], type = "check", func = self.Reload, arg1 = "SSPVP-AV", var = { "av", "armor" }, parent = "SSAlteracValley" },
		{ text = L["Enable flesh/medal tracking"], type = "check", func = self.Reload, arg1 = "SSPVP-AV", var = { "av", "medal" }, parent = "SSAlteracValley" },
		{ text = L["Enable blood/crystal tracking"], type = "check", func = self.Reload, arg1 = "SSPVP-AV", var = { "av", "crystal" }, parent = "SSAlteracValley" },
		{ text = L["Enable interval capture messages"], type = "check", func = self.Reload, arg1 = "SSPVP-AV", var = { "av", "enabled" }, parent = "SSAlteracValley" },
		{ text = L["Interval in seconds between messages"], type = "input", forceType = "int", width = 30, var = { "av", "interval" }, parent = "SSAlteracValley" },
		{ text = L["Interval frequency increase"], func = self.Reload, arg1 = "SSPVP-AV", type = "dropdown", list = { { 0, L["None"] }, { 0.75, L["25%"] }, { 0.50, L["50%"] }, { 0.25, L["75%"] } },  var = { "av", "speed" }, parent = "SSAlteracValley" },
		
		-- Arathi Basin
		{ text = L["Enable capture timers"], type = "check", func = self.Reload, arg1 = "SSPVP-AB", var = { "ab", "timers" }, parent = "SSArathiBasin" },
		{ text = L["Enable estimated final score overlay"], type = "check", func = self.Reload, arg1 = "SSPVP-AB", var = { "ab", "overlay" }, parent = "SSArathiBasin" },
		{ text = L["Estimated final score"], type = "check", func = self.Reload, arg1 = "SSPVP-AB", var = { "ab", "finalScore" }, parent = "SSArathiBasin" },
		{ text = L["Estimated time left in the battlefield"], type = "check", func = self.Reload, arg1 = "SSPVP-AB", var = { "ab", "timeLeft" }, parent = "SSArathiBasin" },
		{ text = L["Show bases to win"], type = "check", func = self.Reload, arg1 = "SSPVP-AB", var = { "ab", "basesWin" }, parent = "SSArathiBasin" },
		{ text = L["Show bases to win score"], type = "check", func = self.Reload, arg1 = "SSPVP-AB", var = { "ab", "basesScore" }, parent = "SSArathiBasin" },
		
		-- Warsong Gulch
		{ text = L["Enable carrier names"], type = "check", func = self.Reload, arg1 = "SSPVP-WSG", var = { "wsg", "carriers" }, parent = "SSWarsongGulch" },
		{ text = L["Show border around carrier names"], type = "check", func = self.Reload, arg1 = "SSPVP-WSG", var = { "wsg", "border" }, parent = "SSWarsongGulch" },
		{ text = L["Show carrier health when available"], type = "check", func = self.Reload, arg1 = "SSPVP-WSG", var = { "wsg", "health" }, parent = "SSWarsongGulch" },
		{ text = L["Time until flag respawns"], type = "check",func = self.Reload, arg1 = "SSPVP-WSG", var = { "wsg", "respawn" }, parent = "SSWarsongGulch" },
		{ text = L["Show time elapsed since flag was picked up"], type = "check",func = self.Reload, arg1 = "SSPVP-WSG", var = { "wsg", "flagElapsed" }, parent = "SSWarsongGulch" },
		{ text = L["Show time taken before the flag was captured"], type = "check",func = self.Reload, arg1 = "SSPVP-WSG", var = { "wsg", "flagCapTime" }, parent = "SSWarsongGulch" },

		-- Eye of the Storm
		{ text = L["Enable overlay"], type = "check", func = self.Reload, arg1 = "SSPVP-EoTS", var = { "eots", "overlay" }, parent = "SSEyeOfTheStorm" },
		{ text = L["Enable carrier names"], type = "check", func = self.Reload, arg1 = "SSPVP-EoTS", var = { "eots", "carriers" }, parent = "SSEyeOfTheStorm" },
		{ text = L["Show border around carrier names"], type = "check", func = self.Reload, arg1 = "SSPVP-EoTS", var = { "eots", "border" }, parent = "SSEyeOfTheStorm" },
		{ text = L["Time until flag respawns"], type = "check",func = self.Reload, arg1 = "SSPVP-EoTS", var = { "eots", "respawn" }, parent = "SSEyeOfTheStorm" },
		{ text = L["Estimated time left in the battlefield"], type = "check", func = self.Reload, arg1 = "SSPVP-EoTS", var = { "eots", "timeLeft" }, parent = "SSEyeOfTheStorm" },
		{ text = L["Estimated final score"], type = "check", func = self.Reload, arg1 = "SSPVP-EoTS", var = { "eots", "finalScore" }, parent = "SSEyeOfTheStorm" },
		{ text = L["Show bases to win"], type = "check", func = self.Reload, arg1 = "SSPVP-EoTS", var = { "eots", "towersWin" }, parent = "SSEyeOfTheStorm" },
		{ text = L["Show bases to win score"], type = "check", func = self.Reload, arg1 = "SSPVP-EoTS", var = { "eots", "towersScore" }, parent = "SSEyeOfTheStorm" },
		{ text = L["Show captures to win"], type = "check", func = self.Reload, arg1 = "SSPVP-EoTS", var = { "eots", "captureWin" }, parent = "SSEyeOfTheStorm" },
		{ text = L["Show total flag captures for Alliance and Horde"], type = "check", func = self.Reload, arg1 = "SSPVP-EoTS", var = { "eots", "totalCaptures" }, parent = "SSEyeOfTheStorm" },
		
		-- Auto turn in
		{ text = L["Enable auto turn in"], type = "check", var = { "turnin", "enabled" }, parent = "SSTurnIn" },		
 	}
 	
 	-- Auto turn in types
 	for key, text in pairs( L["TURNTYPES"] ) do
		table.insert( UIList, { text = string.format( L["Disable %s"], text ), type = "check", var = { "turnin", key }, parent = "SSTurnIn" } )
	end
	
	-- Modules
	for name, module in SSPVP:IterateModules() do
		if( L[ name ] ) then
			table.insert( UIList, { text = string.format( L["Disable module %s"], L[ name ] ), type = "check", var = { "modules", name }, parent = "SSModules" } )
		end
	end
end
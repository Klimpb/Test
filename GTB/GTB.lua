local major = "GTB-1.0"
local minor = tonumber(string.match("$Revision: 308 $", "(%d+)") or 1)

assert(LibStub, string.format("%s requires LibStub.", major))

local GTBInstance, oldRevision = LibStub:NewLibrary(major, minor)
if( not GTBInstance ) then return end

local L = {
	["BAD_ARGUMENT"] = "bad argument #%d for '%s' (%s expected, got %s)",
	["MUST_CALL"] = "You must call '%s' from a registered GTB object.",
}

local function assert(level,condition,message)
	if( not condition ) then
		error(message,level)
	end
end

local function argcheck(value, num, ...)
	if( type(num) ~= "number" ) then
		error(L["BAD_ARGUMENT"]:format(2, "argcheck", "number", type(num)), 1)
	end

	for i=1,select("#", ...) do
		if( type(value) == select(i, ...) ) then return end
	end

	local types = string.join(", ", ...)
	local name = string.match(debugstack(2,2,0), ": in function [`<](.-)['>]")
	error(L["BAD_ARGUMENT"]:format(num, name, types, type(value)), 3)
end

-- Widgety fun
-- We only need one tooltip, pointless to make more
local tooltip
local function showInfoTooltip(self)
	if( not tooltip ) then
		tooltip = CreateFrame("GameTooltip", "HAInfoTooltip", nil, "GameTooltipTemplate")
	end

	tooltip:SetOwner(self, "ANCHOR_RIGHT" )
	tooltip:SetText(self.tooltip, nil, nil, nil, nil, 1)
	tooltip:Show()
end

local function hideTooltip(self)
	if( tooltip ) then
		tooltip:Hide()
	end
end

local function positionWidgets(columns, parent, widgets, positionGroup, isGroup)
	local heightUsed = 10
	if( positionGroup or columns > 1 ) then
		heightUsed = 8 + (widgets[1].yPos or 0)
	elseif( isGroup ) then
		heightUsed = 14
	end
	
	if( columns == 1 ) then
		local height = 0
		for i, widget in pairs(widgets) do
			widget:ClearAllPoints()
			
			if( i > 1 ) then
				heightUsed = heightUsed + height + 5 + ( widget.yPos or 0 )
			end

			local xPos = widget.xPos
			if( widget.infoButton and widget.infoButton.type ) then
				xPos = ( xPos or 0 ) + 15
				if( not positionGroup ) then
					widget.infoButton:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -heightUsed)
				else
					widget.infoButton:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, -heightUsed)
				end
				
				widget.infoButton:Show()
			end

			widget:SetPoint("TOPLEFT", parent, "TOPLEFT", xPos or 5, -heightUsed)
			widget:Show()
			height = widget:GetHeight() + ( widget.yPos or 0 )
		end
				
		local checkPos = #(widgets)
		if( checkPos == 1 ) then
			heightUsed = 8
		end
		
		local widget = widgets[checkPos]
		if( widget.data and widget.data.type ~= "color" and widget.data.type ~= "check" ) then
			if( widget:GetHeight() >= 35 ) then
				heightUsed = heightUsed + widget:GetHeight()
			else
				heightUsed = heightUsed + (widget.yPos or 0) + 5
			end
		end
	else
		local height = 0
		local spacePerRow = math.ceil(300 / columns)
		local resetOn = -1
		local row = 0
		
		-- If we have an uneven number of widgets
		-- then we need to create an extra row for the last one
		if( mod(#(widgets), columns) == 1 ) then
			resetOn = #(widgets)
		end

		for i, widget in pairs(widgets) do
			if( row == columns or row == resetOn ) then
				heightUsed = heightUsed + height
				height = 0
				row = 0
			end
			
			-- How far away it is from the next row
			local spacing = 0
			if( row > 0 ) then
				spacing = ( spacePerRow * ( row + 1 ) )
			end

			local xPos = widget.xPos or 0
			if( widget.infoButton and widget.infoButton.type ) then
				xPos = ( xPos or 0 ) + 15
				
				if( not positionGroup ) then
					widget.infoButton:SetPoint("TOPLEFT", parent, "TOPLEFT", spacing, -heightUsed)
				else
					widget.infoButton:SetPoint("TOPLEFT", parent, "TOPLEFT", spacing + 6, -heightUsed)
				end
				
				widget.infoButton:Show()
			end
			
			local extraPad = 0
			if( widget.data.type == "slider" and i > columns ) then
				extraPad = 10
			end

			-- Position
			widget:ClearAllPoints()
			widget:SetPoint("TOPLEFT", parent, "TOPLEFT", spacing + xPos, -heightUsed - extraPad)			
			widget:Show()
			
			-- Find the heightest widget out of this group and use that
			local widgetHeight = widget:GetHeight() + ( widget.yPos or 0 ) + 5
			if( widgetHeight > height ) then
				height = widgetHeight
			end
			
			-- Add the extra padding so we don't get overlap
			if( i == resetOn ) then
				heightUsed = heightUsed + ( widget.yPos or 0 )
			end

			row = row + 1
		end
	end
	
	return heightUsed
end

local function setupWidgetInfo(widget, config, type, msg, skipCall)
	-- No button made, no type, exit silently
	if( not widget.infoButton and not type ) then
		return
	
	-- Removing the display
	elseif( widget.infoButton and widget.infoButton.type and not type ) then
		widget.infoButton.type = nil
		widget.infoButton:Hide()
		return
	end
	
	-- Create (Obviously!) the button
	if( not widget.infoButton ) then
		widget.infoButton = CreateFrame("Button", nil, widget)
		widget.infoButton:SetScript("OnEnter", showInfoTooltip)
		widget.infoButton:SetScript("OnLeave", hideTooltip)
		widget.infoButton:SetTextFontObject(GameFontNormalSmall)
		widget.infoButton:SetHeight(18)
		widget.infoButton:SetWidth(18)
	end

	-- Change the message, nothing else needed
	if( widget.infoButton.type == type ) then
		widget.infoButton.tooltip = msg
		return
	end
	
	if( type == "help" ) then
		widget.infoButton:SetPushedTextOffset(0,0)
		widget.infoButton:SetText(GREEN_FONT_COLOR_CODE .. "[?]" .. FONT_COLOR_CODE_CLOSE)
	elseif( type == "validate" ) then
		widget.infoButton:SetText(RED_FONT_COLOR_CODE .. "[!]" .. FONT_COLOR_CODE_CLOSE)
	end

	widget.infoButton.type = type
	widget.infoButton.tooltip = msg
end

-- SET/GET CONFIGURATION VALUES
-- Validates the set/get/onSet/handler/validate
local function validateFunctions(config, data)
	local type = "function"
	if( config.handler or data.handler ) then
		type = "string"
	end
		
	argcheck(data.handler or config.handler, "handler", "table", "nil")
	argcheck(data.set or config.set, "set", type)
	argcheck(data.get or config.get, "get", type)
	argcheck(data.validate, "validate", type, "nil")
	argcheck(data.onSet or config.onSet, "onSet", type, "nil")
end

-- If the set we call errors, the onSet will not be called
-- so don't error damnits
local function setValue(config, data, value)
	local handler = data.handler or config.handler
	local set = data.set or config.set
	local onSet = data.onSet or config.onSet
		
	if( set and handler ) then
		handler[set](handler, data.var, value)
		
	elseif( set ) then
		set(data.var, value)
	end

	if( onSet and handler ) then
		handler[onSet](handler, data.var, value)
	elseif( onSet ) then
		onSet(data.var, value)
	end
end

local function getValue(config, data)
	local handler = data.handler or config.handler
	local get = data.get or config.get
	local val
	
	if( get and handler ) then
		val = handler[get](handler, data.var)
	elseif( get ) then
		val = get(data.var)
	end
	
	if( val == nil and data.default ~= nil ) then
		setValue(config, data, data.default)
		return data.default
	end
	
	return val
end

-- CHECK BOXES
local function checkShown(self)
	self:SetChecked(getValue(self.parent, self.data))
end

local function checkClicked(self)
	if( self:GetChecked() ) then
		setValue(self.parent, self.data, true)
	else
		setValue(self.parent, self.data, false)
	end
end

-- SLIDERS
local sliderBackdrop = {bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
			edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
			edgeSize = 8, tile = true, tileSize = 8,
			insets = { left = 3, right = 3, top = 6, bottom = 6 }}

local function manualSliderShown(self)
	self.dontSet = true
	self:SetNumber(getValue(self.parent, self.data) * 100)
end

local function sliderShown(self)
	local value = getValue(self.parent, self.data)
	self:SetValue(value)
	
	if( self.data.format ) then
		self.text:SetText(string.format(self.data.format, value * 100))
	else
		self.text:SetText(self.data.text)
	end
	
	if( self.input ) then
		manualSliderShown(self.input)
		self.input:Show()
	end
end

local function updateSliderValue(self)
	if( self.dontSet ) then self.dontSet = nil return end
	
	self:GetParent().dontSet = true
	self:GetParent():SetValue((self:GetNumber()+1) / 100)
end

local function sliderValueChanged(self)
	setValue(self.parent, self.data, self:GetValue())

	if( self.data.format ) then
		self.text:SetText(string.format(self.data.format, self:GetValue() * 100))
	end
	
	if( self.data.manualInput and not self.dontSet ) then
		self.input.dontSet = true	
		self.input:SetNumber(math.floor(self:GetValue() * 100))
	else
		self.dontSet = nil
	end
end

-- INPUT BOX
local function inputShown(self)
	if( not self.data.numeric ) then
		self:SetText(getValue(self.parent, self.data) or "")
	else
		self:SetNumber(getValue(self.parent, self.data))
	end
end

local function inputSetFocus(self)
	self:SetFocus()
end

local function inputClearFocus(self)
	self:ClearFocus()
end

local function inputFocusGained(self)
	self:HighlightText()
end

local function inputChanged(self)
	local val
	if( not self.data.numeric ) then
		val = self:GetText()
	else
		val = self:GetNumber()
	end
	
	if( self.data.validate ) then
		local handler = self.parent.handler or self.data.handler
		if( handler ) then
			val = handler[self.data.validate](handler, self.data.var, val)
		else
			val = self.data.validate(self.data.var, val)
		end
		
		-- Validation error, show [!]
		if( not val ) then
			setupWidgetInfo(self, self.parent, "validate", string.format(self.data.error, self:GetText()))
			return
		
		-- Error cleared, no help, hide [!]
		elseif( not self.data.help ) then
			setupWidgetInfo(self, self.parent)
		
		-- Error cleared, help exists, switch [!] to [?]
		elseif( self.infoButton and self.infoButton.type == "validate" ) then
			setupWidgetInfo(self, self.parent, "help", self.data.help)
		end
	end
	
	setValue(self.parent, self.data, val)
end

local function inputClearAndChange(self)
	inputClearFocus(self)
	inputChanged(self)
end

-- COLOR PICKER
local function colorPickerShown(self)
	local value = getValue(self.parent, self.data)
	self:GetNormalTexture():SetVertexColor(value.r, value.g, value.b)
end

local function colorPickerEntered(self)
	self.border:SetVertexColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
end

local function colorPickerLeft(self)
	self.border:SetVertexColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
end

local function setColorValue()
	local r, g, b = ColorPickerFrame:GetColorRGB()
	
	setValue(ColorPickerFrame.activeButton.parent, ColorPickerFrame.activeButton.data, { r = r, g = g, b = b })
	ColorPickerFrame.activeButton:GetNormalTexture():SetVertexColor(r, g, b)
end

local function cancelColorValue(previous)	
	setValue(ColorPickerFrame.activeButton.parent, ColorPickerFrame.activeButton.data, previous)
	ColorPickerFrame.activeButton:GetNormalTexture():SetVertexColor(previous.r, previous.g, previous.b)
end

local function resetStrata(self)
	self:SetFrameStrata(self.origStrata)
	self.origStrata = nil
	self.activeButton = nil
end

local function openColorPicker(self)
	local value = getValue(self.parent, self.data)
		
	ColorPickerFrame.previousValues = value
	ColorPickerFrame.func = setColorValue
	ColorPickerFrame.cancelFunc = cancelColorValue
	ColorPickerFrame.origStrata = ColorPickerFrame:GetFrameStrata()
	ColorPickerFrame.activeButton = self
	
	ColorPickerFrame:SetFrameStrata("FULLSCREEN")
	ColorPickerFrame:HookScript("OnHide", resetStrata)
	ColorPickerFrame:SetColorRGB(value.r, value.g, value.b)
	ColorPickerFrame:Show()
end

-- DROPDOWNS
local DROPDOWN_ROWS = 10
local openedList
local dropdownBackdrop = {
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	edgeSize = 32,
	tileSize = 32,
	tile = true,
	insets = { left = 11, right = 12, top = 12, bottom = 11 },
}

local function showHighlight(self)
	self.highlight:Show()

	-- Reset timer before it's hidden
	self:GetParent().timeElapsed = 0
end

local function hideHighlight(self)
	self.highlight:Hide()
end

local function showDropdown(self)
	self.width = 0
	
	-- Calculate the width of the list frame
	local selectedValues = getValue(self.parent, self.data)
	if( self.data.multi and ( not selectedValues or type(selectedValues) ~= "table" ) ) then
		selectedValues = {}
		setValue(self.parent, self.data, selectedValues)
	end

	local selectedText
	for id, info in pairs(self.data.list) do
		self.text:SetText(info[2])
		if( self.text:GetStringWidth() > self.width ) then
			self.width = self.text:GetStringWidth() + 75
		end

		if( ( not self.data.multi and info[1] == selectedValues ) or ( self.data.multi and selectedValues[info[1]] ) ) then
			selectedText = info[2]
		end
	end
		
	-- Bad, means we couldn't find the selected text so we default to the first row
	if( not selectedText ) then
		if( not self.data.multi ) then
			setValue(self.parent, self.data, self.data.list[1][1])
		end

		selectedText = self.data.list[1][2]
	end

	-- Set selected text
	self.text:SetText(selectedText)
	
	-- Auto resize so the text doesn't overflow
	local textWidth = self.text:GetStringWidth() + 30
	if( textWidth > self.middleTexture:GetWidth() ) then
		self.middleTexture:SetWidth(textWidth)
	end
end

local function dropdownRowClicked(self)
	local parent = self:GetParent().parentFrame
	if( not parent.data.multi ) then
		setValue(parent.parent, parent.data, self.key)
		showDropdown(parent)

		self:GetParent():Hide()
	else
		local selectedKeys = getValue(parent.parent, parent.data)
		if( selectedKeys[self.key] ) then
			selectedKeys[self.key] = nil	
		else
			selectedKeys[self.key] = true
		end
	
		setValue(parent.parent, parent.data, selectedKeys)

		-- Yes, this is INCREDIBLY hackish
		self:GetParent():Hide()
		self:GetParent():Show()
		
		showDropdown(parent)
	end
end

local function hideDropdown(self)
	if( self.listFrame ) then
		self.listFrame:Hide()
		
		if( openedList == self.listFrame ) then
			openedList = nil
		end
	end
end

local function createListRow(parent, id)
	local button = CreateFrame("Button", nil, parent)
	button:SetWidth(100)
	button:SetHeight(16)
	button:SetScript("OnClick", dropdownRowClicked)
	button:SetTextFontObject(GameFontHighlightSmall)
	button:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
	button:SetHighlightTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
	
	-- GetFontString() returns nil until we SetText
	button:SetText("")
	button:GetFontString():SetPoint("LEFT", button, "LEFT", 40, 0)

	local highlight = button:CreateTexture(nil, "BACKGROUND")
	highlight:ClearAllPoints()
	highlight:SetPoint("TOPLEFT", button, "TOPLEFT", 12, 0)
	highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
	highlight:SetAlpha(0.5)
	highlight:SetBlendMode("ADD")
	highlight:Hide()
	button.highlight = highlight

	button.check = button:CreateTexture(nil, "ARTWORK")
	button.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
	button.check:SetHeight(24)
	button.check:SetWidth(24)
	
	button:SetScript("OnEnter", showHighlight)
	button:SetScript("OnLeave", hideHighlight)
	
	
	if( id > 1 ) then
		button:SetPoint("TOPLEFT", parent.rows[id - 1], "TOPLEFT", 0, -16)
		button.check:SetPoint("TOPLEFT", button, "TOPLEFT", 12, 3)
	else
		button:SetPoint("TOPLEFT", parent, "TOPLEFT", -2, -13)
		button.check:SetPoint("TOPLEFT", button, "TOPLEFT", 12, 3)
	end
	
	parent.rows[id] = button
	
	return button
end

local function updateDropdownList(self, frame)
	if( self ) then
		frame = self
	elseif( not frame ) then
		frame = openedList
	end
	
	if( not frame or not frame.parentFrame ) then
		return
	end

	local parent = frame.parentFrame
	local selectedValues = getValue(parent.parent, parent.data)
	local totalRows = #(parent.data.list)
	local usedRows = 0
	
	OptionHouse:UpdateScroll(frame.scroll, totalRows + 1)
		
	for id, info in pairs(parent.data.list) do
		if( id >= frame.scroll.offset and usedRows < DROPDOWN_ROWS ) then
			usedRows = usedRows + 1
			
			if( not frame.rows[usedRows] ) then
				createListRow(frame, usedRows)
			end
			
			local row = frame.rows[usedRows]
			row:SetWidth(parent.width)
			row.highlight:SetWidth(parent.width)
			row:SetText(info[2])
			row.key = info[1]
			
			if( ( not parent.data.multi and info[1] == selectedValues ) or ( parent.data.multi and selectedValues[info[1]] ) ) then
				row.check:Show()
			else
				row.check:Hide()
			end
		end
	end
end

local function dropdownListShown(self)
	updateDropdownList(self)

	self:SetHeight((min(#(self.parentFrame.data.list), DROPDOWN_ROWS) * 16 ) + 25)
	
	if( #(self.parentFrame.data.list) <= DROPDOWN_ROWS ) then
		self:SetWidth(self.parentFrame.width + 20)
	else
		self:SetWidth(self.parentFrame.width + 50)
	end
end

-- Do we want this? Not sure
local function dropdownCounter(self, elapsed)
	self.timeElapsed = self.timeElapsed + elapsed
	if( self.timeElapsed >= 10 ) then
		self:Hide()
	end
end

local function openDropdown(self)
	PlaySound("igMainMenuOptionCheckBoxOn")
	
	if( not self.listFrame ) then
		self.listFrame = CreateFrame("Frame", nil, self.parent.frame)
		self.listFrame.rows = {}
		self.listFrame.timeElapsed = 0
		self.listFrame:SetBackdrop(dropdownBackdrop)
		self.listFrame:SetToplevel(true)
		self.listFrame:SetFrameStrata("FULLSCREEN")
		self.listFrame:SetScript("OnShow", dropdownListShown)
		--self.listFrame:SetScript("OnUpdate", dropdownCounter)
		self.listFrame:Hide()

		OptionHouse:CreateScrollFrame(self.listFrame, 10, updateDropdownList)
		
		self.listFrame.scroll:SetWidth(36)
		self.listFrame.scroll:SetPoint("TOPLEFT", 10, -12)
		self.listFrame.scroll:SetPoint("BOTTOMRIGHT", -34, 43)
		self.listFrame.scroll.barUpTexture:Hide()
		self.listFrame.scroll.barDownTexture:Hide()
	end

	-- Toggle it open or close
	if( self.listFrame:IsVisible() ) then
		if( openedList == self.listFrame ) then
			openedList = nil
		end
		
		self.listFrame:Hide()
	else
		-- Make sure only one list frame is active at one time
		if( openedList ) then
			openedList:Hide()
		end
		
		openedList = self.listFrame

		self.listFrame.timeElapsed = 0
		self.listFrame.parentFrame = self
		self.listFrame:ClearAllPoints()
		self.listFrame:SetPoint("TOPLEFT", self.leftTexture, "BOTTOMLEFT", 8, 22)

		self.listFrame:Show()

		-- Renachor the frame if need be because it's at the bottom of the screen
		if( self.listFrame:GetBottom() and self.listFrame:GetBottom() <= 300 ) then
			self.listFrame:ClearAllPoints()
			self.listFrame:SetPoint("BOTTOMLEFT", self.leftTexture, "TOPLEFT", 8, -22)
		end
	end
end

local function dropdownClickButton(self)
	openDropdown(self:GetParent())
end

-- GROUP FRAME
local groupBackdrop = {
	bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 16,
	insets = { left = 5, right = 5, top = 5, bottom = 5 }
}

local function createGroup(config, data)
	local group = CreateFrame("Frame", nil, config.frame)
	group:SetWidth(300)
	group:SetBackdrop(groupBackdrop)
	
	if( data and data.background ) then
		group:SetBackdropColor(data.background.r, data.background.g, data.background.b)
	else
		group:SetBackdropColor(0.094117, 0.094117, 0.094117)	
	end
	
	if( data and data.border ) then
		group:SetBackdropBorderColor(data.border.r, data.border.g, data.border.b)
	else
		group:SetBackdropBorderColor(0.4, 0.4, 0.4)
	end
	
	group:SetFrameStrata("DIALOG")
	group.title = group:CreateFontString(nil, "BACKGROUND", "GameFontHighlight")
	group.title:SetPoint("BOTTOMLEFT", group, "TOPLEFT", 9, 0)
	--group.title:SetText(data.text)
	
	return group
end

-- So everything shows up in front of the group
local function updateFrameLevels(...)
	for i=1,select("#", ...) do
		local frame = select(i,...)
		if( frame.SetFrameLevel ) then
			frame:SetFrameLevel(frame:GetParent():GetFrameLevel() + 1)
		end
		
		if( frame.GetChildren ) then
			updateFrameLevels(frame:GetChildren())
		end
	end
end

-- BUTTONS
local function buttonClicked(self)
	local handler = self.data.handler or self.parent.handler
	if( handler ) then
		if( self.data.set ) then
			handler[self.data.set](handler, self.data.var)
		end
		
		if( self.data.onSet ) then
			handler[self.data.onSet](handler, self.data.var)
		end
	else
		if( self.data.set ) then
			self.data.set(self.data.var)
		end
		
		if( self.data.onSet ) then
			self.data.onSet(self.data.var)
		end
	end
end

-- GTB Library
local GTB = {}
local bars = {}

local methods = {}


local function checkVersion()
	if( oldRevision ) then
		bars = GTBInstance.bars or bars
	end
	
	GTB.bars = bars
	
	for k, v in pairs(GTB) do
		GTBInstance[k] = v
	end
end

checkVersion()

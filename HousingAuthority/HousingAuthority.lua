local major = "HousingAuthority-1.0"
local minor = tonumber(string.match("$Revision$", "(%d+)") or 1)

assert(DongleStub, string.format("%s requires DongleStub.", major))

if( not DongleStub:IsNewerVersion(major, minor) ) then return end

local L = {
	["BAD_ARGUMENT"] = "bad argument #%d for '%s' (%s expected, got %s)",
	["BAD_ARGUMENT_TABLE"] = "bad widget table argument '%s' for '%s' (%s expected, got %s)",
	["MUST_CALL"] = "You must call '%s' from a registered HouseAuthority object.",
	["SLIDER_NOTEXT"] = "You must either set text or format for sliders.",
	["CANNOT_CREATE"] = "You cannot create any new widgets for this anymore, HAObj:GetFrame() was called.",
	["CANNOT_ENABLE"] = "Cannot enable scroll frames anymore, HAObj:GetFrame() was called.",
	["OH_NOT_INITIALIZED"] = "OptionHouse has not been initialized yet, you cannot call HAObj:GetFrame() until then.",
	["INVALID_POSITION"] = "Invalid positioning passed, 'compact' or 'onebyone' required, got '%s'.",
	["INVALID_WIDGETTYPE"] = "Invalid type '%s' passed, %s expected'.",
	["CANNOT_CALLGROUP"] = "You must set the groups setting before any other widgets are added.",
	["WIDGETS_MISSINGGROUP"] = "When using groups, all widgets must be grouped. %d out of %d are missing a group.",
}

local function assert(level,condition,message)
	if( not condition ) then
		error(message,level)
	end
end


local function argcheck(value, field, ...)
	if( type(field) ~= "number" and type(field) ~= "string" ) then
		error(L["BAD_ARGUMENT"]:format(2, "argcheck", "number, string", type(field)), 1)
	end

	for i=1, select("#", ...) do
		if( type(value) == select(i, ...) ) then return end
	end

	local types = string.join(", ", ...)
	local name = string.match(debugstack(2,2,0), ": in function [`<](.-)['>]")
	
	if( type(field) == "number" ) then
		error(L["BAD_ARGUMENT"]:format(field, name, types, type(value)), 3)
	else
		error(L["BAD_ARGUMENT_TABLE"]:format(field, name, types, type(value)), 3)
	end
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

local function positionWidgets(columns, parent, widgets, positionGroup)
	local heightUsed = 10
	if( positionGroup ) then
		heightUsed = 8 + (widgets[1].yPos or 0)
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
	else
		local height = 0
		local spacePerRow = math.ceil(300 / columns)
		local resetOn = -1
		local reset
		
		if( mod(#(widgets), columns) == 1 ) then
			resetOn = #(widgets)
		end
		
		for i, widget in pairs(widgets) do
			local row = mod(i, columns)
			
			-- New row
			if( row == 1 and reset or i == resetOn ) then
				heightUsed = heightUsed + height
				height = 0
				reset = nil
			
			-- New row, next 1 we see is the next row
			elseif( row == 1 and not reset ) then
				reset = true
			end
			
			local spacing = 0
			if( row ~= 1 ) then
				spacing = ( spacePerRow * ( row + 2 ) )
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
			
			-- Position
			widget:ClearAllPoints()
			widget:SetPoint("TOPLEFT", parent, "TOPLEFT", spacing + xPos, -heightUsed)			
			widget:Show()
			
			-- Find the heightest widget out of this group
			local widgetHeight = widget:GetHeight() + ( widget.yPos or 0 ) + 5
			if( widgetHeight > height ) then
				height = widgetHeight
			end
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
	argcheck(data.onSet, "onSet", type, "nil")
end


local function setValue(config, data, value)
	local handler = data.handler or config.handler
	local set = data.set or config.set
	local onSet = data.onSet or config.onSet
	
	if( set and handler ) then
		if( type(data.var) == "table" ) then
			handler[set](handler, value, unpack(data.var))
		else
			handler[set](handler, value, data.var)
		end
		
	elseif( set ) then
		if( type(data.var) == "table" ) then
			set(value, unpack(data.var))
		else
			set(value, data.var)
		end
	end

	if( onSet and handler ) then
		if( type(data.var) == "table" ) then
			handler[onSet](handler, value, unpack(data.var))
		else
			handler[onSet](handler, value, data.var)
		end
		
	elseif( onSet ) then
		if( type(data.var) == "table" ) then
			onSet(value, unpack(data.var))
		else
			onSet(value, data.var)
		end
	end
end

local function getValue(config, data)
	local handler = data.handler or config.handler
	local get = data.get or config.get
	local val
	
	if( get and handler ) then
		if( type(data.var) == "table" ) then
			val = handler[get](handler, unpack(data.var))
		else
			val = handler[get](handler, data.var)
		end
		
	elseif( get ) then
		if( type(data.var) == "table" ) then
			val = get(unpack(data.var))
		else
			val = get(data.var)
		end
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

local function sliderShown(self)
	local value = getValue(self.parent, self.data)
	self:SetValue(value)
	
	if( self.data.format ) then
		self.text:SetText(string.format(self.data.format, value * 100))
	else
		self.text:SetText(self.data.text)
	end
end

local function sliderValueChanged(self)
	setValue(self.parent, self.data, self:GetValue())

	if( self.data.format ) then
		self.text:SetText(string.format(self.data.format, self:GetValue() * 100))
	end
end

-- INPUT BOX
local function inputShown(self)
	if( not self.data.numeric ) then
		self:SetText(getValue(self.parent, self.data))
	else
		self:SetNumber(getValue(self.parent, self.data))
	end
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
			if( type(self.data.var) == "table" ) then
				val = handler[self.data.validate](handler, unpack(self.data.var), val)
			else
				val = handler[self.data.validate](handler, self.data.var, val)
			end
		else
			if( type(self.data.var) == "table" ) then
				val = self.data.validate(unpack(self.data.var), val)
			else
				val = self.data.validate(self.data.var, val)
			end
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

-- COLOR PICKER
local activeButton
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
	local self = activeButton
	local r, g, b = ColorPickerFrame:GetColorRGB()
	
	setValue(self.parent, self.data, {r = r, g = g, b = b})
	self:GetNormalTexture():SetVertexColor(r, g, b)
end

local function cancelColorValue(previous)
	local self = activeButton
	
	setValue(self.parent, self.data, previous)
	self:GetNormalTexture():SetVertexColor(previous.r, previous.g, previous.b)
end

local function openColorPicker(self)
	local value = getValue(self.parent, self.data)
	activeButton = self
	
	ColorPickerFrame.previousValues = value
	ColorPickerFrame.func = setColorValue
	ColorPickerFrame.cancelFunc = cancelColorValue
	
	ColorPickerFrame:SetColorRGB(value.r, value.g, value.b)
	ColorPickerFrame:Show()
end

-- DROPDOWNS
local activeDropdown
local function dropdownClicked(self)
	UIDropDownMenu_SetSelectedValue(activeDropdown, this.value)
	setValue(activeDropdown.parent, activeDropdown.data, this.value)
	activeDropdown = nil
end

local function initDropdown()
	activeDropdown = activeDropdown or this:GetParent()
	for _, row in pairs(activeDropdown.data.list) do
		UIDropDownMenu_AddButton({ value = row[1], text = row[2], func = dropdownClicked })
	end
end

local function dropdownShown(self)
	activeDropdown = self
	
	UIDropDownMenu_Initialize(self, initDropdown)
	UIDropDownMenu_SetSelectedValue(self, getValue(self.parent, self.data))
end

-- GROUP FRAME
local groupBackdrop = {
	--bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", --options frame background
	bgFile = "Interface\\ChatFrame\\ChatFrameBackground", -- kc_linkview frame background
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
	
	if( ddata and ata.border ) then
		group:SetBackdropBorderColor(data.border.r, data.border.g, data.border.b)
	else
		group:SetBackdropBorderColor(0.4, 0.4, 0.4)
	end
	
	group.title = group:CreateFontString(nil, "BACKGROUND", "GameFontHighlight")
	group.title:SetPoint("BOTTOMLEFT", group, "TOPLEFT", 9, 0)
	--group.title:SetText(data.text)
	
	return group
end

-- Housing Authority
local HouseAuthority = {}
local configs = {}
local id = 0

local methods = { "GetFrame", "CreateConfiguration", "CreateGroup", "CreateLabel", "CreateDropdown", "CreateColorPicker", "CreateInput", "CreateSlider", "CreateCheckBox" }

-- Stage 0, Adding widgets, can call Create*
-- Stage 1, Frame is being finished up (first GetFrame() call)
-- Stage 2, Frame is finished, positioning has been called/frame returned
function HouseAuthority:RegisterFrame(data)
	argcheck(data, 1, "table")
	argcheck(data.columns, "columns", "number", "nil")
	
	if( not data.columns ) then
		data.columns = 1
	end
	
	local type = "function"
	if( data.handler ) then
		type = "string"	
	end
	
	argcheck(data.handler, "handler", "table", "nil")
	argcheck(data.set, "set", type, "nil")
	argcheck(data.get, "get", type, "nil")
	argcheck(data.onSet, "onSet", type, "nil")
	
	id = id + 1
	
	local config = { id = id, columns = data.columns, stage = 0, widgets = {}, handler = data.handler, get = data.get, frame = data.frame, set = data.set, onSet = data.onSet }
	config.obj = { id = id }
	
	for _, method in pairs(methods) do
		config.obj[method] = HouseAuthority[method]
	end
		
	configs[id] = config

	return configs[id].obj
end

-- In order to allow even people who call HAObj:CreateGroup manually to use them
-- we have to create all of the groups when GetFrame is called
function HouseAuthority.CreateGroup(config, data)
	argcheck(data, 2, "table")
	argcheck(data.background, "background", "table")
	argcheck(data.border, "border", "table")
	assert(3, config and configs[config.id], string.format(L["MUST_CALL"], "CreateGroup"))
	assert(3, configs[config.id].stage == 0, L["CANNOT_CREATE"])
	
	configs[config.id].groupData = data
end

function HouseAuthority.CreateLabel(config, data)
	argcheck(data, 2, "table")
	argcheck(data.text, "text", "string")
	argcheck(data.color, "color", "table", "nil")
	argcheck(data.fontPath, "fontPath", "string", "nil")
	argcheck(data.fontSize, "fontSize", "number", "nil")
	argcheck(data.fontFlag, "fontFlag", "string", "nil")
	argcheck(data.font, "font", "table", "nil")
	assert(3, config and configs[config.id], string.format(L["MUST_CALL"], "CreateLabel"))
	assert(3, configs[config.id].stage == 0, L["CANNOT_CREATE"])
	
	data.type = "label"
		
	local label = configs[config.id].frame:CreateFontString(nil, "ARTWORK")
	label.parent = config
	label.data = data
	label.xPos = 8
	label.yPos = 5
	
	if( data.font ) then
		label:SetFontObject(data.font)	
	elseif( data.fontPath and data.fontSize ) then
		label:SetFont(data.fontPath, data.fontSize, data.fontFlag)
	else
		label:SetFontObject(GameFontNormal)
	end
	
	if( data.color ) then
		label:SetTextColor(data.color.r, data.color.g, data.color.b)
	end
	
	label:SetText(data.text)
	label:SetHeight(20)
	
	table.insert(configs[config.id].widgets, label)
	return label
end

function HouseAuthority.CreateColorPicker(config, data)
	argcheck(data, 2, "table")
	argcheck(data.text, "text", "string")
	argcheck(data.help, "help", "string", "nil")
	argcheck(data.var, "var", "string", "table")
	argcheck(data.default, "default", "table", "nil")
	assert(3, config and configs[config.id], string.format(L["MUST_CALL"], "CreateColorPicker"))
	assert(3, configs[config.id].stage == 0, L["CANNOT_CREATE"])
	
	validateFunctions(configs[config.id], data)	

	config = configs[config.id]
	
	data.type = "color"
	
	local button = CreateFrame("Button", nil, config.frame)
	button.parent = config
	button.data = data
	button.xPos = 10
	button.yPos = 2
	
	button:SetHeight(18)
	button:SetWidth(18)
	button:SetScript("OnShow", colorPickerShown)
	button:SetScript("OnClick", openColorPicker)
	button:SetScript("OnEnter", colorPickerEntered)
	button:SetScript("OnLeave", colorPickerLeft)
	button:SetNormalTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")
	
	button.border = button:CreateTexture(nil, "BACKGROUND")
	button.border:SetHeight(16)
	button.border:SetWidth(16)
	button.border:SetPoint("CENTER", 0, 0)
	button.border:SetTexture(1, 1, 1)
	button:Hide()
	
	if( data.text ) then
		local text = button:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
		text:SetPoint("LEFT", button, "RIGHT", 5, 0)
		text:SetText(data.text)	
	end
	
	if( data.help ) then
		setupWidgetInfo(button, config, "help", data.help)
	end
	
	table.insert(config.widgets, button)
	return button
end

function HouseAuthority.CreateInput(config, data)
	argcheck(data, 2, "table")
	argcheck(data.text, "text", "string")
	argcheck(data.var, "var", "string", "table")
	argcheck(data.default, "default", "number", "string", "nil")
	argcheck(data.realTime, "realTime", "boolean", "nil")
	argcheck(data.numeric, "numeric", "boolean", "nil")
	argcheck(data.error, "error", "string", "nil")
	argcheck(data.help, "help", "string", "nil")
	argcheck(data.width, "width", "number", "nil")
	assert(3, config and configs[config.id], string.format(L["MUST_CALL"], "CreateInput"))
	assert(3, configs[config.id].stage == 0, L["CANNOT_CREATE"])
	
	validateFunctions(configs[config.id], data)	

	config = configs[config.id]
	data.type = "input"
	
	local input = CreateFrame("EditBox", nil, config.frame)
	input.parent = config
	input.data = data
	input.xPos = 15
	
	input:SetScript("OnShow", inputShown)
	input:SetScript("OnEscapePressed", inputClearFocus)
	input:SetScript("OnEditFocusGained", inputFocusGained)
	
	if( data.numeric ) then
		input:SetNumeric(true)
	end
	
	if( not data.realTime ) then
		input:SetScript("OnEditFocusLost", inputChanged)
		input:SetScript("OnEnterPressed", inputChanged)
	else
		input:SetScript("OnTextChanged", inputChanged)
	end
	
	input:SetAutoFocus(false)
	input:EnableMouse(true)
	
	input:SetHeight(20)
	input:SetWidth(120 or data.width)
	input:SetFontObject(ChatFontNormal)
	input:Hide()
	
	local left = input:CreateTexture(nil, "BACKGROUND")
	left:SetTexture("Interface\\Common\\Common-Input-Border")
	left:SetWidth(8)
	left:SetHeight(20)
	left:SetPoint("LEFT", -5, 0)
	left:SetTexCoord(0, 0.0625, 0, 0.625)
	
	local right = input:CreateTexture(nil, "BACKGROUND")
	right:SetTexture("Interface\\Common\\Common-Input-Border")
	right:SetWidth(8)
	right:SetHeight(20)
	right:SetPoint("RIGHT", 0, 0)
	right:SetTexCoord(0.9375, 1.0, 0, 0.625)
	
	local middle = input:CreateTexture(nil, "BACKGROUND")
	middle:SetTexture("Interface\\Common\\Common-Input-Border")
	middle:SetWidth(10)
	middle:SetHeight(20)
	middle:SetPoint("LEFT", left, "RIGHT")
	middle:SetPoint("RIGHT", right, "LEFT")
	middle:SetTexCoord(0.0625, 0.9375, 0, 0.625)
	
	if( data.text ) then
		local text = input:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
		text:SetPoint("LEFT", input, "RIGHT", 5, 0)
		text:SetText(data.text)
	end

	if( data.help ) then
		setupWidgetInfo(input, config, "help", data.help)
	end

	table.insert(config.widgets, input)
	return input
end

function HouseAuthority.CreateSlider(config, data)
	argcheck(data, 2, "table")
	argcheck(data.default, "default", "number", "nil")
	argcheck(data.help, "help", "string", "nil")
	argcheck(data.var, "var", "string", "table")
	argcheck(data.text, "text", "string", "nil")
	argcheck(data.format, "format", "string", "nil")
	argcheck(data.min, "min", "number", "nil")
	argcheck(data.minText, "minText", "string", "nil")
	argcheck(data.max, "max", "number", "nil")
	argcheck(data.maxText, "minText", "string", "nil")
	argcheck(data.step, "step", "number", "nil")
	assert(3, ( data.text or data.format ), L["SLIDER_NOTEXT"])
	assert(3, config and configs[config.id], string.format(L["MUST_CALL"], "CreateSlider"))
	assert(3, configs[config.id].stage == 0, L["CANNOT_CREATE"])
	
	validateFunctions(configs[config.id], data)	
	
	config = configs[config.id]
	
	data.type = "slider"
	
	local slider = CreateFrame("Slider", nil, config.frame)
	slider.parent = config
	slider.data = data
	slider.xPos = 10
	slider.yPos = 10

	slider:SetScript("OnShow", sliderShown)
	slider:SetScript("OnValueChanged", sliderValueChanged)
	slider:SetWidth(128)
	slider:SetHeight(17)
	slider:SetMinMaxValues(data.min or 0.0, data.max or 1.0)
	slider:SetValueStep(data.step or 0.01)	
	slider:SetOrientation("HORIZONTAL")
	slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
	slider:SetBackdrop(sliderBackdrop)
	slider:Hide()
	
	slider.text = slider:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	slider.text:SetPoint("BOTTOM", slider, "TOP", 0, 0)
	
	if( not data.text and not data.format ) then
		slider.text:Hide()
	end
	
	local min = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	min:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 2, 3)
	
	if( not data.minText ) then
		min:SetText((data.min or 0.0) * 100 .. "%")
	else
		min:SetText(data.minText)
	end
	
	local max = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	max:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", -2, 3)		
	
	if( not data.maxText ) then
		max:SetText((data.max or 1.0) * 100 .. "%" )
	else
		max:SetText(data.maxText)
	end
	
	if( data.help ) then
		setupWidgetInfo(slider, config, "help", data.help)
	end

	table.insert(config.widgets, slider)
	return slider
end

function HouseAuthority.CreateCheckBox(config, data)
	argcheck(data, 2, "table")
	argcheck(data.default, "default", "boolean", "nil")
	argcheck(data.help, "help", "string", "nil")
	argcheck(data.var, "var", "string", "table")
	assert(3, config and configs[config.id], string.format(L["MUST_CALL"], "CreateCheckBox"))
	assert(3, configs[config.id].stage == 0, L["CANNOT_CREATE"])
	
	validateFunctions(configs[config.id], data)

	config = configs[config.id]
	
	data.type = "check"

	local check = CreateFrame("CheckButton", nil, config.frame)
	check.parent = config
	check.data = data
	check.xPos = 5
	
	check:SetScript("OnShow", checkShown)
	check:SetScript("OnClick", checkClicked)
	check:SetWidth(26)
	check:SetHeight(26)
	check:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
	check:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
	check:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
	check:SetDisabledCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled")
	check:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
	check:Hide()
	
	if( data.text ) then
		local text = check:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
		text:SetPoint("LEFT", check, "RIGHT", 5, 0)
		text:SetText(data.text)
	end
	
	if( data.help ) then
		setupWidgetInfo(check, config, "help", data.help)
	end

	table.insert(config.widgets, check)
	return check
end

function HouseAuthority.CreateDropdown(config, data)
	argcheck(data, 2, "table")
	argcheck(data.list, "list", "table")
	argcheck(data.default, "default", "string", "nil")
	argcheck(data.help, "help", "string", "nil")
	argcheck(data.var, "var", "string", "table")
	assert(3, config and configs[config.id], string.format(L["MUST_CALL"], "CreateDropdown"))
	assert(3, configs[config.id].stage == 0, L["CANNOT_CREATE"])
	
	validateFunctions(configs[config.id], data)
	
	config = configs[config.id]
	config.dropNum = ( config.dropNum or 0 ) + 1
	
	data.type = "dropdown"

	local button = CreateFrame("Frame", "HADropdownID" .. config.id .. "Num" .. config.dropNum, config.frame, "UIDropDownMenuTemplate")
	button.parent = config
	button.data = data
	button.xPos = -10
	button:SetScript("OnShow", dropdownShown)
	button:Hide()
	
	if( data.text ) then
		local text = button:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
		text:SetPoint("LEFT", "HADropdownID" .. config.id .. "Num" .. config.dropNum .. "Button", "RIGHT", 10, 0)
		text:SetText(data.text)
	end
	
	if( data.help ) then
		setupWidgetInfo(button, config, "help", data.help)
	end

	table.insert(config.widgets, button)
	return button
end

function HouseAuthority.GetFrame(config)
	assert(3, config and configs[config.id], string.format(L["MUST_CALL"], "GetFrame"))
	assert(3, OptionHouseFrames.addon, L["OH_NOT_INITIALIZED"])
	
	local config = configs[config.id]
	if( config.stage == 2 ) then
		return config.scroll or config.frame
	end
	
	config.stage = 1
		
	-- Now figure out how many groups we have/need
	config.groups = {}
	local totalGroups = 0
	local groupedWidgets = 0

	for _, widget in pairs(config.widgets) do
		if( widget.data.group ) then
			if( not config.groups[widget.data.group] ) then
				config.groups[widget.data.group] = {}
				totalGroups = totalGroups + 1
			end
			
			table.insert(config.groups[widget.data.group], widget)
			groupedWidgets = groupedWidgets + 1
		end
		
		if( config.columns > 1 and widget.data.type == "slider" ) then
			widget.yPos = widget.yPos + 5
		end
	end
	
	-- Grouping is "disabled" so postion it directly to the frame
	local totalHeight = 0
	if( totalGroups == 0 ) then
		totalHeight = positionWidgets(config.columns, config.frame, config.widgets)
	else
		assert(3, groupedWidgets == #(config.widgets), string.format(L["WIDGETS_MISSINGGROUP"], groupedWidgets, #(config.widgets)))
		
		-- Create all the groups, then position the objects to the widget
		local frames = {}
		for text, widgets in pairs(config.groups) do
			local frame = createGroup(config, config.groupData)
			
			-- Reparent/framelevel/position/blah the widgets
			for i, widget in pairs(widgets) do
				widget:SetParent(frame)
				widget:SetFrameLevel(frame:GetFrameLevel() + 2 )
				widget.xPos = ( widget.xPos or 0 ) + 5
			end

			-- Now reposition them
			local height = positionWidgets(config.columns, frame, widgets, true)
			
			-- Give some frame info
			frame.yPos = 5
			frame.title:SetText(text)
			frame:SetWidth(600)
			frame:SetHeight(height + 30)
			table.insert(frames, frame)
			
			totalHeight = totalHeight + height + 35
		end
		
		-- Now position all of the groups
		positionWidgets(1, config.frame, frames)
	end

	-- Do we even need a scroll frame?
	if( totalHeight >= 280 ) then
		local scroll = CreateFrame("ScrollFrame", "HAScroll" .. config.id, OptionHouseFrames.addon, "UIPanelScrollFrameTemplate")
		scroll:SetPoint("TOPLEFT", OptionHouseFrames.addon, "TOPLEFT", 190, -105)
		scroll:SetPoint("BOTTOMRIGHT", OptionHouseFrames.addon, "BOTTOMRIGHT", -35, 40)

		config.frame:SetParent(scroll)
		config.frame:SetWidth(10)
		config.frame:SetHeight(10)
		
		scroll:SetScrollChild(config.frame)
		config.scroll = scroll
	end	
	
	config.stage = 2
	
	return config.scroll or config.frame
end

function HouseAuthority:CreateConfiguration(data, frameData)
	argcheck(data, 1, "table")
	argcheck(frameData, 2, "table", "nil")

	frameData = frameData or {}
	if( not frameData.frame ) then
		frameData.frame = CreateFrame("Frame", nil, OptionHouseFrames.addon)
	end
	
	local handler = HouseAuthority:RegisterFrame(frameData)
	local widgets = {["label"] = "CreateLabel", ["check"] = "CreateCheckBox",
			["input"] = "CreateInput", ["dropdown"] = "CreateDropdown",
			["color"] = "CreateColorPicker", ["slider"] = "CreateSlider",
			["group"] = "CreateGroup"}
	
	for id, widget in pairs(data) do
		if( widget.type and widgets[widget.type] ) then
			handler[widgets[widget.type]](handler, widget)
		else
			error(string.format(L["INVALID_WIDGETTYPE"], widget.type or "nil", "label, check, input, dropdown, color, slider, group"), 3)
		end
	end
	
	return handler.GetFrame(handler)
end

function HouseAuthority:GetVersion() return major, minor end

local function Activate(self, old)
	if( old ) then
		id = old.id or id
		configs = old.configs or configs
	end

	for id, config in pairs(configs) do
		for _, method in pairs(methods) do
			configs[id].obj[method] = HouseAuthority[method]
		end
	end
	
	self.id = id
	self.configs = configs
end

HouseAuthority = DongleStub:Register(HouseAuthority, Activate)

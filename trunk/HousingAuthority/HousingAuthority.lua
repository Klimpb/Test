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

local function positionWidgets(config)
	if( config.positionType == "onebyone" ) then
		local heightUsed = 10
		local height = 0
		for i, widget in pairs(config.widgets) do
			widget:ClearAllPoints()

			if( i > 1 ) then
				heightUsed = heightUsed + height + 5 + ( widget.yPos or 0 )
			end
			
			local xPos = widget.xPos
			if( widget.infoButton and widget.infoButton.type ) then
				xPos = ( xPos or 0 ) + 15
				widget.infoButton:SetPoint("TOPLEFT", config.frame, "TOPLEFT", 0, -heightUsed)
				widget.infoButton:Show()
			end

			widget:SetPoint("TOPLEFT", config.frame, "TOPLEFT", xPos or 5, -heightUsed)
			height = widget:GetHeight() + ( widget.yPos or 0 )
		end
	elseif( config.positionType == "compact" ) then
	
	end
end

local function setupWidgetInfo(widget, config, type, msg, skipCall)
	-- No button made, no type, exit silently
	if( not widget.infoButton and not type ) then
		return
	
	-- Removing the display
	elseif( widget.infoButton and widget.infoButton.type and not type ) then
		widget.infoButton.type = nil
		widget.infoButton:Hide()
		
		if( config.positionType ~= "onebyone" and not skipCall ) then
			positionWidgets(config)
		end
		return
	end
	
	if( not widget.infoButton ) then
		widget.infoButton = CreateFrame("Button", nil, widget)
		widget.infoButton:SetScript("OnEnter", showInfoTooltip)
		widget.infoButton:SetScript("OnLeave", hideTooltip)
		widget.infoButton:SetTextFontObject(GameFontNormal)
		widget.infoButton:SetHeight(18)
		widget.infoButton:SetWidth(18)
	end

	-- Change the message, nothing else needed
	if( widget.infoButton.type == type ) then
		widget.infoButton.tooltip = msg
		return
	end
	
	if( type == "help" ) then
		widget.infoButton:SetText("[?]")
	elseif( type == "validate" ) then
		widget.infoButton:SetText("[!]")
	end

	widget.infoButton.type = type
	widget.infoButton.tooltip = msg
	
	if( not skipCall ) then
		positionWidgets(config)
	end
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
	this:HighlightText()
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


-- Housing Authority
local HouseAuthority = {}
local configs = {}
local id = 0

local methods = { "GetFrame", "CreateConfiguration", "CreateLabel", "CreateDropdown", "CreateColorPicker", "CreateInput", "CreateSlider", "CreateCheckBox" }
local widgets = { ["label"] = "CreateLabel", ["check"] = "CreateCheckBox", ["input"] = "CreateInput", ["dropdown"] = "CreateDropdown", ["color"] = "CreateColorPicker", ["slider"] = "CreateSlider" }

-- Stage 0, Adding widgets, can call Create*
-- Stage 1, Frame is finalized, you can no longer add new widgets
function HouseAuthority:RegisterFrame(data)
	argcheck(data, 1, "table")
	argcheck(data.positionType, "positionType", "string", "nil")
	if( data.positionType and data.positionType ~= "compact" and data.positionType ~= "onebyone" and data.positionType == "none" ) then
		error(string.format(L["INVALID_POSITION"], data.positionType), 3)
	end
	
	if( data.positionType == nil ) then
		data.positionType = "onebyone"	
	elseif( data.positionType == "none" ) then
		data.positionType = nil
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
	
	local config = { id = id, positionType = data.positionType, stage = 0, widgets = {}, handler = data.handler, get = data.get, frame = data.frame, set = data.set, onSet = data.onSet }
	config.obj = { id = id }
	
	for _, method in pairs(methods) do
		config.obj[method] = HouseAuthority[method]
	end
		
	configs[id] = config

	return configs[id].obj
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
		
	local label = configs[config.id].frame:CreateFontString(nil, "ARTWORK")
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
	
	local button = CreateFrame("Button", nil, config.frame)
	button.parent = config
	button.data = data
	button.xPos = 10
	
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
	
	local text = button:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	text:SetPoint("LEFT", button, "RIGHT", 5, 0)
	text:SetText(data.text)	
	
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
	
	local text = config.frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	text:SetPoint("LEFT", input, "RIGHT", 5, 0)
	text:SetText(data.text)

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
	
	local slider = CreateFrame("Slider", nil, config.frame)
	slider.parent = config
	slider.data = data
	slider.xPos = 10
	slider.yPos = 15

	slider:SetScript("OnShow", sliderShown)
	slider:SetScript("OnValueChanged", sliderValueChanged)
	slider:SetWidth(128)
	slider:SetHeight(17)
	slider:SetMinMaxValues(data.min or 0.0, data.max or 1.0)
	slider:SetValueStep(data.step or 0.01)	
	slider:SetOrientation("HORIZONTAL")
	slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
	slider:SetBackdrop(sliderBackdrop)
	
	slider.text = slider:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	slider.text:SetPoint("BOTTOM", slider, "TOP", 0, 0)
	
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

	local text = config.frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	text:SetPoint("LEFT", check, "RIGHT", 5, 0)
	text:SetText(data.text)
	
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

	local button = CreateFrame("Frame", "HADropdownID" .. config.id .. "Num" .. config.dropNum, config.frame, "UIDropDownMenuTemplate")
	button.parent = config
	button.data = data
	button.xPos = -10
	button:SetScript("OnShow", dropdownShown)
	
	if( data.text ) then
		local text = config.frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
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
	if( config.stage == 1 ) then
		return config.scroll or config.frame
	end
	
	config.stage = 1
	
	-- Do we even need a scroll frame?
	local height = 0
	for _, widget in pairs(config.widgets) do
		height = height + widget:GetHeight() + ( widget.yPos or 10 )
	end

	if( height >= 280 ) then
		local scroll = CreateFrame("ScrollFrame", "HAScroll" .. config.id, OptionHouseFrames.addon, "UIPanelScrollFrameTemplate")
		scroll:SetPoint("TOPLEFT", OptionHouseFrames.addon, "TOPLEFT", 190, -105)
		scroll:SetPoint("BOTTOMRIGHT", OptionHouseFrames.addon, "BOTTOMRIGHT", -35, 40)

		config.frame:SetParent(scroll)
		config.frame:SetWidth(10)
		config.frame:SetHeight(10)
		
		scroll:SetScrollChild(config.frame)
		config.scroll = scroll
	end
	
	positionWidgets(config)
	
	return config.scroll or config.frame
end

function HouseAuthority:CreateConfiguration(data, frameData)
	argcheck(data, 1, "table")
	argcheck(frameData, 2, "table", "nil")

	frameData = frameData or {}
	if( not frameData.frame ) then
		frameData.frame = CreateFrame("Frame")
	end
	
	local handler = HouseAuthority:RegisterFrame(frameData)
	
	for id, widget in pairs(data) do
		if( widget.type and widgets[widget.type] ) then
			handler[widgets[widget.type]](handler, widget)
		else
			local validTypes = {}
			for type, _ in pairs(widgets) do
				table.insert(validTypes, type)
			end
			
			error(string.format(L["INVALID_WIDGETTYPE"], widget.type or "nil", table.concat(validTypes, ", ")), 3)
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

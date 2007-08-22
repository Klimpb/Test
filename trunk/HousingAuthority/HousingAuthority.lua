local major = "HousingAuthority-1.0"
local minor = tonumber(string.match("$Revision$", "(%d+)") or 1)

assert(DongleStub, string.format("%s requires DongleStub.", major))

if( not DongleStub:IsNewerVersion(major, minor) ) then return end

local L = {
	["BAD_ARGUMENT"] = "bad argument #%d to '%s' (%s expected, got %s)",
	["BAD_ARGUMENT_TABLE"] = "bad argument for %s to '%s' (%s expected, got %s)",
	["MUST_CALL"] = "You must call '%s' from a registered HouseAuthority object.",
	["SLIDER_NOTEXT"] = "You must either set text or format for sliders.",
	["CANNOT_CREATE"] = "You cannot create any new widgets for this anymore, HAObj:GetFrame() was called.",
	["CANNOT_ENABLE"] = "Cannot enable scroll frames anymore, HAObj:GetFrame() was called."
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

-- SET/GET CONFIGURATION VALUES
-- Validates the set/get/onSet/handler/validate
local function validateFunctions(config, data)
	local type = "function"
	if( config.handler or data.handler ) then
		type = "string"
	end
	
	argcheck(data.handler or config.handler, "string", "nil")
	argcheck(data.set or config.set, type)
	argcheck(data.get or config.get, type)
	argcheck(data.validate, type, "nil")
	argcheck(data.onSet, type, "nil")
end

local function getValue(config, data)
	local handler = data.handler or config.handler
	local get = data.get or config.get
	
	if( get and handler ) then
		if( type(data.var) == "table" ) then
			return handler[get](handler, unpack(data.var)) or data.default
		else
			return handler[get](handler, data.var) or data.default
		end
		
	elseif( get ) then
		if( type(data.var) == "table" ) then
			return get(unpack(data.var)) or data.default
		else
			return get(data.var) or data.default
		end
	end
	
	return nil
end

local function setValue(config, data, value)
	local handler = data.handler or config.handler
	local set = data.set or config.set
	local onSet = data.onSet or config.onSet
	
	if( set and handler ) then
		if( type(data.var) == "table" ) then
			return handler[set](handler, unpack(data.var)) or data.default
		else
			return handler[set](handler, data.var) or data.default
		end
		
	elseif( set ) then
		if( type(data.var) == "table" ) then
			return set(unpack(data.var)) or data.default
		else
			return set(data.var) or data.default
		end
	end

	if( onSet and handler ) then
		if( type(data.var) == "table" ) then
			return handler[onSet](handler, unpack(data.var)) or data.default
		else
			return handler[onSet](handler, data.var) or data.default
		end
		
	elseif( onSet ) then
		if( type(data.var) == "table" ) then
			return onSet(unpack(data.var)) or data.default
		else
			return onSet(data.var) or data.default
		end
	end
end

-- DROPDOWN
local dropdownBackdrop = {	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = true,
				tileSize = 9,
				edgeSize = 9,
				insets = { left = 2, right = 2, top = 2, bottom = 2 }}

local function dropdownShown(self)
	local value = getValue(self.parent, self.data)
	-- No default, no value, set it to the first row
	if( not value ) then
		value = self.data.list[1][1]
	end

	self.selectedKey = value
	
	for _, row in pairs(self.data.list) do
		if( row[1] == value ) then
			self:SetText(row[2])
			self:SetWidth(self:GetFontString():GetStringWidth() + 3)
		end
	end
	
	if( self.rowFrame ) then
		self.rowFrame:Hide()
	end
end

local function dropdownSelected(self)
	local dropdown = self:GetParent():GetParent()
	
	setValue(dropdown.parent, dropdown.data, self.configValue)
	dropdownShown(dropdown)
end

local function popDropdown(self)
	if( not self.rows ) then
		self.rows = {}
		
		self.rowFrame = CreateFrame("Frame", nil, self)
		self.rowFrame:SetBackdrop(backdrop)
		self.rowFrame:SetBackdropColor(0, 0, 0, 1)
		self.rowFrame:SetBackdropBorderColor(0.75, 0.75, 0.75, 0.80)
	end
	
	
	local frameWidth = 0
	for i, configRow in pairs(self.data.list) do
		local row
		if( self.rows[i] ) then
			row = self.rows[i]
		else
			row = CreateFrame("Button", nil, self.rowFrame)
			row:SetScript("OnClick", dropdownSelected)
			row:SetFontObject(GameFontNormalSmall)
			row:SetHeight(18)
			
			if( i > 1 ) then
				row:SetPoint( "TOPLEFT", self.rows[i-1], "TOPLEFT", 0, -10)
			else
				row:SetPoint( "TOPLEFT", self.rowFrame, "TOPLEFT", 0, -2)
			end

			self.rows[i] = row
		end
		
		-- Highlight the selected button
		if( configRow[1] == self.selectedKey ) then
			row:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
		else
			row:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
		end
		
		row.configValue = configRow[1]
		row:SetText(configRow[2])
		
		-- Figure out whats the largest width so the frame is wide enough
		row.textWidth = row:GetFontString():GetStringWidth() + 3
		if( row.textWidth > frameWidth ) then
			frameWidth = row.textWidth
		end
	end
	
	for i, row in pairs(self.rows) do
		if( self.data.list[i] ) then
			row:SetWidth(frameWidth)
			row:Show()
		else
			row:Hide()
		end
	end
	
	self.rowFrame:SetWidth(frameWidth)
	self.rowFrame:SetHeight(#(self.data.list) + (#(self.data.list) * 10))
	self.rowFrame:Show()
end

-- CHECK BOXES
local function checkShown(self)
	self:SetChecked(getValue(self.parent, self.data))
end

local function checkClicked(self)
	if( self:GetChecked() ) then
		setValue(self.parent, self.data, true)
	else
		setValue(self.parent, self.data, true)
	end
end

-- SLIDERS
local function sliderShown(self)
	local value = getValue(self.parent, self.data)
	slider:SetValue(value)
	
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
	input:SetText(getValue(self.parent, self.data))
end

local function inputChanged(self)
	local val = self:GetText()
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
		
		if( not val ) then
			-- Then throw a validation error here
			return
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
	self.button:SetVertexColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
end

local function colorPickerLeft(self)
	self.button:SetVertexColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
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
	local value = getValue(self.parent, self.dat
	activeButton = self
	
	ColorPickerFrame.previousValues = value
	ColorPickerFrame.func = setColorValue
	ColorPickerFrame.cancelFunc = cancelColorValue
	
	ColorPickerFrame:SetColorRGB(value.r, value.g, value.b)
	ColorPickerFrame:Show()
end

-- Housing Authority
local HouseAuthority = {}
local configs = {}
local id = 0
local methods = { "GetFrame", "CreateDropdown", "CreateColorPicker", "CreateInput", "CreateSlider", "CreateCheckBox" }

-- Stage 0, Adding widgets, can call Create*
-- Stage 1, Frame is finalized, you can no longer add new widgets

function HouseAuthority:RegisterFrame(data)
	validateFunctions(data, data)
	
	id = id + 1
	
	local config = { id = id, stage = 0, widgets = {}, get = data.get, frame = data.frame, set = data.set, onSet = data.onSet }
	config.obj = { id = id }
	
	for _, method in pairs(methods) do
		config.obj[method] = HouseAuthority[method]
	end
	
	configs[id] = config

	return configs.obj
end


function HouseAuthority.CreateColorPicker(config, data)
	argcheck(data.text, "text", "string")
	argcheck(data.var, "var", "string", "table")
	argcheck(data.default, "default", "table", "nil")
	assert(3, configs[config.id], string.format(L["MUST_CALL"], "CreateDropdown"))
	assert(3, configs[config.id].stage == 0, L["CANNOT_CREATE"])
	
	validateFunctions(configs[config.id], data)	

	config = configs[config.id]
	
	local button = CreateFrame("Button", nil, config.frame)
	button.parent = config
	button.data = data
	
	button:SetHeight(18)
	button:SetWidth(18)
	button:SetScript("OnShow", colorPickerShown)
	button:SetScript("OnClick", openColorPicker)
	button:SetScript("OnEnter", colorPickerEntered)
	button:SetScript("OnLeave", colorPickerLeft)
	button:SetNormalTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")
	button:Hide()
	
	button.border = CreateFrame("Button", nil, config.frame)
	button.border:SetHeight(18)
	button.border:SetWidth(16)
	button.border:SetPoint("CENTER", 0, 0)
	button.border:SetTexture(1, 1, 1)
	
	local text = config.frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	text:SetPoint("LEFT", check, "RIGHT", 5, 0)
	text:SetText(data.text)	
	
	table.insert(config.widgets, button)
	configs[config.id] = config
end

function HouseAuthority.CreateInput(config, data)
	argcheck(data.text, "text", "string")
	argcheck(data.var, "var", "string", "table")
	argcheck(data.default, "default", "number", "string", "nil")
	argcheck(data.realTime, "realTime", "boolean", "nil")
	argcheck(data.error, "error", "string", "nil")
	assert(3, configs[config.id], string.format(L["MUST_CALL"], "CreateDropdown"))
	assert(3, configs[config.id].stage == 0, L["CANNOT_CREATE"])
	
	validateFunctions(configs[config.id], data)	

	config = configs[config.id]
	
	local input = CreateFrame("EditBox", nil, config.frame)
	input.parent = config
	input.data = data
	
	input:SetScript("OnShow", inputShown)
	if( not data.realTime ) then
		input:SetScript("OnEditFocusLost", inputChanged)
		input:SetScript("OnEnterPressed", inputChanged)
	else
		input:SetScript("OnTextChanged", inputChanged)
	end
	
	input:SetAutoFocus(false)
	input:EnableMouse(true)
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
	
	local text = config.frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	text:SetPoint("LEFT", check, "RIGHT", 5, 0)
	text:SetText(data.text)

	table.insert(config.widgets, input)
	
	configs[config.id] = config
end

function HouseAuthority.CreateSlider(config, data)
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
	assert(3, configs[config.id], string.format(L["MUST_CALL"], "CreateDropdown"))
	assert(3, configs[config.id].stage == 0, L["CANNOT_CREATE"])
	
	validateFunctions(configs[config.id], data)	
	
	config = configs[config.id]
	
	local slider = CreateFrame("Slider", nil, config.frame)
	slider.parent = config
	slider.data = data

	slider:SetScript("OnShow", sliderShown)
	slider:SetScript("OnValueChanged", sliderValueChanged)
	slider:SetWidth(128)
	slider:SetHeight(17)
	slider:SetMinMaxValues(data.min or 0.0, data.max or 1.0)
	slider:SetValueStep(data.step or 0.01)	
	slider:SetOrientation("HORIZONTAL")
	slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
	slider:SetBackdrop(WidgetWarlock.HrizontalSliderBG)
	slider:Hide()
	
	slider.text = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	slider.text:SetPoint("BOTTOM", slider, "TOP", 0, 0)
	
	local min = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	min:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 2, 3)
	
	if( not data.minText ) then
		min:SetText((data.min * 100) .. "%")
	else
		min:SetText(data.minText)
	end
	
	local max = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	max:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", -2, 3)		
	
	if( not data.maxText ) then
		max:SetText((data.max * 100) .. "%" )
	else
		max:SetText(data.maxText)
	end
	
	configs[config.id] = config
end

function HouseAuthority.CreateCheckBox(config, data)
	argcheck(data.default, "default", "boolean", "nil")
	argcheck(data.help, "help", "string", "nil")
	argcheck(data.var, "var", "string", "table")
	assert(3, configs[config.id], string.format(L["MUST_CALL"], "CreateDropdown"))
	assert(3, configs[config.id].stage == 0, L["CANNOT_CREATE"])
	
	validateFunctions(configs[config.id], data)

	config = configs[config.id]

	local check = CreateFrame("CheckButton", nil, config.frame)
	check.parent = config
	check.data = data
	
	check:SetScript("OnShow", checkShown)
	check:SetScript("OnClick", checkClicked)
	check:SetWidth(18)
	check:SetHeight(18)
	check:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
	check:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
	check:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
	check:SetDisabledCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled")
	check:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
	check:Hide()

	local text = config.frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	text:SetPoint("LEFT", check, "RIGHT", 5, 0)
	text:SetText(data.text)
	
	table.insert(config.widgets, widget)
	configs[config.id] = config
end

function HouseAuthority.CreateDropdown(config, data)
	argcheck(data.list, "list", "table")
	argcheck(data.default, "default", "string", "nil")
	argcheck(data.help, "help", "string", "nil")
	argcheck(data.var, "var", "string", "table")
	assert(3, configs[config.id], string.format(L["MUST_CALL"], "CreateDropdown"))
	assert(3, configs[config.id].stage == 0, L["CANNOT_CREATE"])
	
	validateFunctions(configs[config.id], data)

	config = configs[config.id]
	
	local button = CreateFrame("Button", nil, config.frame)
	button.parent = config
	button.data = data

	button:SetScript("OnShow", dropdownShown)
	button:SetScript("OnClick", popDropdown)

	button:SetFontObject(GameFontNormalSmall)
	button:SetHeight(18)

	button:SetBackdrop(backdrop)
	button:SetBackdropColor(0, 0, 0, 1)
	button:SetBackdropBorderColor(0.75, 0.75, 0.75, 0.80)
	button:Hide()

	if( data.text ) then
		local text = config.frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
		text:SetPoint("LEFT", button, "RIGHT", 5, 0)
		text:SetText(data.text)
	end
	
	table.insert(config.widgets, button)
	configs[config.id] = config
end

function HouseAuthority.GetFrame(config)
	assert(3, configs[config.id], string.format(L["MUST_CALL"], "GetFrame"))
	local config = configs[config.id]
	if( config.stage == 1 ) then
		return config.scroll or config.frame
	end
	
	config.stage = 1
	
	-- Position everything
	local parent = config.frame
	
	-- Do we even need a scroll frame?
	local height = 0
	for _, widget in pairs(config.widgets) do
		height = widget:GetHeight() + 10
	end

	if( height >= 280 ) then
		parent:SetWidth(630)
		parent:SetHeight(305)
		
		local scroll
		
	end
	
	local heightUsed = 0
	for i, widget in pairs(config.widgets) do
		widget:ClearAllPoints()
		
		if( i > 1 ) then
			heightUsed = heightUsed + widget:GetHeight()
			widget:SetPoint("TOPLEFT", config.widgets[i-1], "TOPLEFT", 10, heightUsed)
		else
			heightUsed = widget:GetHeight()
			widget:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, 0)		
		end
	end
	
	
	configs[config.id] = config
	return parent
end

function HouseAuthority:GetVersion() return major, minor end

local function Activate(self, old)
	if( old ) then
		id = old.id or id
		configs = old.configs or configs
	end
	
	self.id = id
	self.configs = configs
end

HouseAuthority = DongleStub:Register(HouseAuthority, Activate)

local major = "SSOverlay-1.0"
local minor = tonumber(string.match("$Revision: 703$", "(%d+)") or 1)

assert(LibStub, string.format("%s requires LibStub.", major))

local Overlay = LibStub:NewLibrary(major, minor)
if( not Overlay ) then return end

local CREATED_ROWS = 0
local MAX_ROWS = 20
local ADDED_ENTRIES = 0
local rows, catCount, categories, config = {}, {}, {}, {}
local longestText, resortRows = 0
local SavedVariables = {}

--[[
	["faction"] = { label = L["Faction Balance"], order = 0 },
	["timer"] = { label = L["Timers"], order = 20 },
	["match"] = { label = L["Match Info"], order = 30 },
	["mine"] = { label = L["Mine Reinforcement"], order = 50 },
	["queue"] = { label = L["Battlefield Queue"], order = 60 },
]]

function Overlay:RegisterCategory(id, label, order)
	if( not categories[id] ) then
		categories[id] = { label = label, order = order }
	end
end

function Overlay:Reload()
	if( not self.frame ) then
		return
	end
	
	self.frame:SetScale(config.scale)
	self.frame:SetBackdropColor(config.background.r, config.background.g, config.background.b, config.opacity)
	self.frame:SetBackdropBorderColor(config.border.r, config.border.g, config.border.b, config.opacity)
	self:UpdateOverlay()

	self.frame:EnableMouse(not config.locked)
	
	for i=1, CREATED_ROWS do
		local row = self.rows[i]
		
		-- If overlay is unlocked, disable mouse so we can move, If it's locked, then enable it if we're not disabling it
		if( not config.locked ) then
			row:EnableMouse(false)
		else
			row:EnableMouse(not config.noClick)
		end

		if( i > 1 ) then
			row:SetPoint("TOPLEFT", self.rows[CREATED_ROWS - 1], "TOPLEFT", 0, -12)
		else
			row:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 5, -5)
		end
	end

	local scale = self.frame:GetEffectiveScale()
	if( not config.growUp ) then
		self.frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", config.x / scale, config.y / scale)
	else
		self.frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", config.x / scale, config.y / scale)
	end
end

local function onClick(self)
	-- So you won't accidentally click the overlay, make sure we have an on click too
	if( not IsModifierKeyDown() or not rows[self.dataID].func ) then
		return
	end
	
	-- Trigger it
	local row = rows[self.dataID]
	if( row.handler ) then
		row.handler[row.func](row.handler, unpack(row.args))
	elseif( type(row.func) == "string" ) then
		getglobal(row.func)(unpack(row.args))
	elseif( type(row.func) == "function" ) then
		row.func(unpack(row.args))
	end
end

local function formatShortTime(seconds)
	local hours = 0
	local minutes = 0
	if( seconds >= 3600 ) then
		hours = floor(seconds / 3600)
		seconds = mod(seconds, 3600)
	end

	if( seconds >= 60 ) then
		minutes = floor(seconds / 60)
		seconds = mod(seconds, 60)
	end
	
	if( seconds < 0 ) then
		seconds = 0
	end

	if( hours > 0 ) then
		return string.format("%d:%02d:%02d", hours, minutes, seconds)
	else
		return string.format("%02d:%02d", minutes, seconds)
	end
end

local function formatTime(seconds)
	if( config.shortTime ) then
		return formatShortTime(seconds)
	else
		return SecondsToTime(seconds)
	end
end

local function onUpdate(self)
	local time = GetTime()
	local row = rows[self.dataID]
	
	if( row.type == "up" ) then
		row.seconds = row.seconds + (time - row.lastUpdate)
	elseif( row.type == "down" ) then
		row.seconds = row.seconds - (time - row.lastUpdate)
	end
	
	row.lastUpdate = time
	
	if( floor(row.seconds) <= 0 and row.type == "down" ) then
		Overlay:RemoveRow(row.id)
	else
		self.text:SetFormattedText(row.text, formatTime(row.seconds))
		
		-- Do a quick recheck incase the text got bigger in the update without
		-- something being removed/added
		if( longestText < (self.text:GetStringWidth() + 10) ) then
			longestText = self.text:GetStringWidth() + 20
			Overlay.frame:SetWidth(longestText)
		end
	end
end

-- Update display
local function sortOverlay(a, b)
	if( not a ) then
		return true
	elseif( not b ) then
		return false
	end
	
	if( a.sortID ~= b.sortID ) then
		return a.sortID < b.sortID
	end

	return a.addOrder < b.addOrder
end

function Overlay:FormatTime(seconds, skipSeconds)
	if( config.shortTime ) then
		return formatShortTime(seconds)
	else
		return SecondsToTime(seconds, skipSeconds)
	end
end

function Overlay:UpdateCategoryText()
	-- Figure out total unique categories we're showing
	local activeCats = 0
	for _, total in pairs(catCount) do
		if( total > 0 ) then
			activeCats = activeCats + 1
		end
	end
			
	-- Now add category texts as required
	for name, total in pairs(catCount) do
		if( activeCats > 1 and total > 0 ) then
			self:RegisterRow("catText", "cat" .. name, name, categories[name].label, nil, nil, 1)
		else
			self:RemoveRow("cat" .. name)
		end
	end
end

function Overlay:UpdateOverlay()
	local totalRows = #(rows)
	if( totalRows == 0 ) then
		longestText = 0
		
		if( self.frame ) then
			self.frame:Hide()

		end
		return
	end
	
	if( not self.frame ) then
		self:CreateFrame()
	end

	if( resortRows ) then
		table.sort(rows, sortOverlay)
		resortRows = nil
	end
	
	for id, data in pairs(rows) do
		if( id > MAX_ROWS ) then
			break
		end
		
		local row = self.rows[id]
		if( not row ) then
			row = self:CreateRow()
		end
		
		-- Text rows just need static text no fancy stuff timers and elapsed rows actually need an OnUpdate
		if( data.type == "text" or data.type == "catText" ) then
			row.text:SetText(data.text)
			row:SetScript("OnUpdate", nil)
		elseif( data.type == "up" or data.type == "down" ) then
			row.text:SetFormattedText(data.text, formatTime(data.seconds))
			row:SetScript("OnUpdate", onUpdate)
		end
		
		if( data.color ) then
			row.text:SetTextColor(data.color.r, data.color.g, data.color.b)
		elseif( data.type == "catText" ) then
			row.text:SetTextColor(config.categoryColor.r, config.categoryColor.g, config.categoryColor.b)
		else
			row.text:SetTextColor(config.textColor.r, config.textColor.g, config.textColor.b)
		end
		
		row.dataID = id
		row:Show()
		
		if( longestText < (row.text:GetStringWidth() + 10) ) then
			longestText = row.text:GetStringWidth() + 20
		end
	end
	
	-- Hide anything unused, and adjust the row width to match the overlay
	for i=1, CREATED_ROWS do
		if( i > totalRows ) then
			self.rows[i].dataID = nil
			self.rows[i]:Hide()
		else
			self.rows[i]:SetWidth(longestText + 15)
		end
	end
	
	-- Resize
	self.frame:SetHeight(min(MAX_ROWS, totalRows) * (self.rows[1].text:GetHeight() + 2) + 9)
	self.frame:SetWidth(longestText)
	self.frame:Show()
end

-- Remove an entry by id or category
function Overlay:RemoveAll()
	longestText = 0
	
	for i=#(rows), 1, -1 do
		table.remove(rows, i)
	end
	
	for cat in pairs(catCount) do
		catCount[cat] = nil
	end
	
	if( self.frame ) then
		for i=1, CREATED_ROWS do
			self.rows[i]:Hide()
		end
		
		self.frame:Hide()
	end
end

function Overlay:RemoveRow(id)
	for i=#(rows), 1, -1 do
		local row = rows[i]
		if( row and row.id == id ) then
			longestText = 0
			table.remove(rows, i)
			
			if( row.type ~= "catText" ) then
				catCount[row.category] = catCount[row.category] - 1
				self:UpdateCategoryText()
			end

			
			self:UpdateOverlay()
		end
	end
end

function Overlay:RemoveCategory(category)
	local updated
	for i=#(rows), 1, -1 do
		if( rows[i].category == category ) then
			table.remove(rows, i)
			updated = true
		end
	end
	
	if( updated ) then
		longestText = 0
		catCount[category] = nil
		
		self:UpdateCategoryText()
		self:UpdateOverlay()
	end
end

-- Adding new rows
function Overlay:RegisterText(id, category, text, color)
	self:RegisterRow("text", id, category, text, color, nil, 2)
end

function Overlay:RegisterTimer(id, category, text, seconds, color)
	self:RegisterRow("down", id, category, text, color, seconds, 3)
end

function Overlay:RegisterElapsed(id, category, text, seconds, color)
	self:RegisterRow("up", id, category, text, color, seconds, 4)
end

-- Generic register, only used internally
function Overlay:RegisterRow(type, id, category, text, color, seconds, priority)
	local row
	local newRow
	-- Grab an existing entry if we haven't deleted them yet
	for _, data in pairs(rows) do
		if( data.id == id ) then
			row = data
			break
		end
	end
	
	if( not row ) then
		row = {}
		newRow = true
	end
	
	row.type = type
	row.id = id
	row.category = category
	row.text = text
	row.color = color
	row.category = category
	row.addOrder = row.addOrder or ADDED_ENTRIES
	row.sortID = categories[category].order + priority
	
	-- Set start time and last update for timers
	if( type == "up" or type == "down" ) then
		row.seconds = seconds
		row.lastUpdate = GetTime()
	else
		row.seconds = nil
		row.lastUpdate = nil
	end

	-- New row time
	if( newRow ) then
		ADDED_ENTRIES = ADDED_ENTRIES + 1
		resortRows = true
		table.insert(rows, row)
		
		-- Infinite recursion is bad
		if( row.type ~= "catText" ) then
			catCount[category] = (catCount[category] or 0 ) + 1
			self:UpdateCategoryText()
		end

	end
	
	self:UpdateOverlay()
end

-- Associates something to run when we click on a row in the overlay
local noArgs = {}
function Overlay:RegisterOnClick(id, handler, func, ...)
	local row
	for _, data in pairs(rows) do
		if( data.id == id ) then
			row = data
			break
		end
	end

	if( not row ) then
		return
	end
	
	if( type(handler) == "function" or type(handler) == "string" ) then
		row.func = handler
	elseif( type(handler) == "table" and type(func) == "string" ) then
		row.handler = handler
		row.func = func
	end
	
	if( select("#", ...) > 0 ) then
		row.args = { ... }
	else
		row.args = noArgs
	end
end

-- Create container frame
function Overlay:CreateFrame()
	self.rows = {}

	-- Setup the overlay frame
	self.frame = CreateFrame("Frame", nil, UIParent)
	self.frame:RegisterForDrag("LeftButton")
	self.frame:SetScale(config.scale)
	self.frame:SetClampedToScreen(true)
	self.frame:SetMovable(true)
	self.frame:SetFrameStrata("BACKGROUND")
		
	self.frame:SetScript("OnDragStop", function(self)
		if( self.isMoving ) then
			self:StopMovingOrSizing()

			local scale = self:GetEffectiveScale()
			config.x = self:GetLeft() * scale
			
			if( not config.growUp ) then
				config.y = self:GetTop() * scale
			else
				config.y = self:GetBottom() * scale
			end
		end
	end)

	self.frame:SetScript("OnDragStart", function(self)
		if( not config.locked ) then
			self.isMoving = true
			self:StartMoving()
		end
	end)

	self.frame:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = true,
				tileSize = 9,
				edgeSize = 9,
				insets = { left = 2, right = 2, top = 2, bottom = 2 }})	
				
	self:Reload()
end

-- Create a new row
function Overlay:CreateRow()
	if( CREATED_ROWS >= MAX_ROWS or not self.frame ) then
		return
	end

	CREATED_ROWS = CREATED_ROWS + 1

	local row = CreateFrame("Frame", nil, self.frame)
	row:SetScript("OnMouseUp", onClick)
	row:SetFrameStrata("LOW")
	row:SetHeight(13)
	row:SetWidth(250)
	
	if( not config.locked ) then
		row:EnableMouse(false)
	else
		row:EnableMouse(not config.noClick)
	end
	
	local text = row:CreateFontString(nil, "BACKGROUND")
	text:SetJustifyH("LEFT")
	text:SetFontObject(GameFontNormalSmall)
	text:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
	row.text = text

	if( CREATED_ROWS > 1 ) then
		row:SetPoint("TOPLEFT", self.rows[CREATED_ROWS - 1], "TOPLEFT", 0, -12)
	else
		row:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 5, -5)
	end
	
	-- Reposition it if we're growing up
	if( config.growUp ) then
		local scale = self.frame:GetEffectiveScale()
		self.frame:ClearAllPoints()
		self.frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", config.x / scale, config.y / scale)
	end

	self.rows[CREATED_ROWS] = row
	return row
end

-- CONFIGURATION HANDLING
local L = {
	["Color"] = "Color",
	["Category text color"] = "Category text color",
	["Text color"] = "Text color",
	["Border color"] = "Border color",
	["Background color"] = "Background color",
	
	["Overlay"] = "Overlay",
	["Disable overlay clicking"] = "Disable overlay clicking",
	["Grow display up"] = "Grow display up",
	["Use HH:MM:SS short time format"] = "Use HH:MM:SS short time format",
	
	["Frame"] = "Frame",
	["Background opacity"] = "Background opacity",
	["Lock overlay"] = "Lock overlay",
	["Scale"] = "Scale",
}

-- Defaults
local defaults = {
	locked = true,
	noClick = false,
	growUp = false,
	shortTime = true,
	x = 300,
	y = 600,
	opacity = 1.0,
	background = { r = 0, g = 0, b = 0 },
	border = { r = 0.75, g = 0.75, b = 0.75 },
	textColor = { r = 1, g = 1, b = 1 },
	categoryColor = { r = 0.75, g = 0.75, b = 0.75 },
	scale = 1.0,
}

function Overlay:RegisterDB(handler)
	if( not handler.db.profile.overlay ) then
		handler.db.profile.overlay = CopyTable(defaults)
	end
	
	local sv = handler.db.profile.overlay
	sv.lastUpdate = sv.lastUpdate or time()
	table.insert(SavedVariables, sv)

	-- This is meant as a syncing tool, basically whenever we update a setting will set the last update time
	-- then will load the one with the latest settings meaning removing modules won't mess up configuration
	if( not config.lastUpdate or config.lastUpdate < sv.lastUpdate ) then
		config = sv
		self:Reload()
	end
	
	-- Do a quick check to see if we need to resync anything
	if( config.lastUpdate ) then
		for _, db in pairs(SavedVariables) do
			if( db.lastUpdate < config.lastUpdate ) then
				db = CopyTable(sv)
			end
		end
	end
end

-- Handle resyncing configuration
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:SetScript("OnEvent", function()
	for _, db in pairs(SavedVariables) do
		if( db.lastUpdate ~= config.lastUpdate ) then
			db = CopyTable(config)
			db.lastUpdate = time()
		end
	end
end)

-- GUI
-- General set/get
local function set(info, value)
	config[info[(#info)]] = value
	Overlay:Reload()
end

local function get(info)
	return config[info[(#info)]]
end

-- Set/Get colors
local function setColor(info, r, g, b)
	set(info, {r = r, g = g, b = b})
end

local function getColor(info)
	local value = get(info)
	if( type(value) == "table" ) then
		return value.r, value.g, value.b
	end
	
	return value
end

function Overlay:LoadOptions()
	return {
		type = "group",
		order = 1,
		name = L["Overlay"],
		get = get,
		set = set,
		handler = Overlay,
		args = {
			growUp = {
				order = 1,
				type = "toggle",
				name = L["Grow display up"],
				width = "full",
			},
			noClick = {
				order = 2,
				type = "toggle",
				name = L["Disable overlay clicking"],
				width = "full",
			},
			shortTime = {
				order = 3,
				type = "toggle",
				name = L["Use HH:MM:SS short time format"],
				width = "full",
			},
			frame = {
				type = "group",
				order = 4,
				inline = true,
				name = L["Frame"],
				args = {
					locked = {
						order = 1,
						type = "toggle",
						name = L["Lock overlay"],
						width = "full",
					},
					opacity = {
						order = 2,
						type = "range",
						name = L["Background opacity"],
						min = 0, max = 1.0, step = 0.01,
					},
					scale = {
						order = 2,
						type = "range",
						name = L["Scale"],
						min = 0.1, max = 2.0, step = 0.01,
					},
				},
			},
			color = {
				type = "group",
				order = 5,
				inline = true,
				name = L["Color"],
				set = setColor,
				get = getColor,
				args = {
					background = {
						order = 1,
						type = "color",
						name = L["Background color"],
					},
					border = {
						order = 1,
						type = "color",
						name = L["Border color"],
					},
					textColor = {
						order = 1,
						type = "color",
						name = L["Text color"],
					},
					categoryColor = {
						order = 1,
						type = "color",
						name = L["Category text color"],
					},
				},
			},
		},
	}
end
--[[ 
	Simple Buff Bars, Mayen/Amarand (Horde) from Icecrown (US) PvE
]]

SimpleBB = LibStub("AceAddon-3.0"):NewAddon("SimpleBB", "AceEvent-3.0", "AceBucket-3.0")

local L = SimpleBBLocals

local SML, MAINHAND_SLOT, OFFHAND_SLOT
local mainEnabled, offEnabled

local frame = CreateFrame("Frame")


function SimpleBB:OnInitialize()
	self.defaults = {
		profile = {
			locked = false,
			showTrack = true,
			showTemp = true,
			showExample = false,
			
			buffTimes = {["buffs"] = {}, ["tempBuffs"] = {}, ["debuffs"] = {}},

			groups = {
				buffs = {
					tempColor = {r = 0.5, g = 0.0, b = 0.5},
					color = {r = 0.30, g = 0.50, b = 1.0},
					texture = "Minimalist",
					sortBy = "timeleft",
					iconPosition = "LEFT",
					height = 16,
					width = 200,
					maxRows = 100,
					scale = 1.0,
					alpha = 1.0,
					spacing = 0,
					colorByType = true,
					anchorSpacing = 20,
					anchorTo = "",
					showStack = true,
					font = "Friz Quadrata TT",
					fontSize = 12,
					passive = false,
					time = "hhmmss",
					position = { x = 600, y = 600 },
				},
				debuffs = {
					color = {r = 0.30, g = 0.50, b = 1.0},
					texture = "Minimalist",
					sortBy = "timeleft",
					iconPosition = "LEFT",
					height = 16,
					width = 200,
					maxRows = 100,
					scale = 1.0,
					alpha = 1.0,
					spacing = 0,
					colorByType = true,
					showStack = true,
					anchorTo = "buffs",
					anchorSpacing = 10,
					font = "Friz Quadrata TT",
					fontSize = 12,
					passive = false,
					time = "hhmmss",
					position = { x = 600, y = 600 },
				},
			},
		},
	}

	self.db = LibStub:GetLibrary("AceDB-3.0"):New("SimpleBBDB", self.defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "Reload")
	self.db.RegisterCallback(self, "OnProfileCopied", "Reload")
	self.db.RegisterCallback(self, "OnProfileReset", "Reload")

	self.revision = tonumber(string.match("$Revision: 811 $", "(%d+)") or 1)
	
	SML = LibStub:GetLibrary("LibSharedMedia-3.0")
	SML.RegisterCallback(self, "LibSharedMedia_Registered", "TextureRegistered")
		
	-- Player buff/debuff rows
	self.buffs = {}
	self.debuffs = {}
	self.activeTrack = {untilCancelled = true, sortID = "z", type = "tracking"}
	self.tempBuffs = {[1] = {}, [2] = {}}
	
	self.groups = {}
	for name in pairs(self.db.profile.groups) do
		self.groups[name] = self:CreateGroup(name)
		self.groups[name].rows = {}
	end
	
	-- Setup the SlotIDs for Mainhand/Offhands
	MAINHAND_SLOT = GetInventorySlotInfo("MainHandSlot")
	OFFHAND_SLOT = GetInventorySlotInfo("SecondaryHandSlot")
	
	-- Kill Blizzards buff frame
	BuffFrame:UnregisterEvent("UNIT_AURA")
	TemporaryEnchantFrame:Hide()
	BuffFrame:Hide()
	
	-- Force a buff check, and update the bar display
	self:RegisterEvent("PLAYER_ENTERING_WORLD", function(self)
		self = SimpleBB
		self:UnregisterEvent("PLAYER_ENTEIRNG_WORLD")
		self:RegisterEvent("UNIT_AURA")
		self:RegisterEvent("MINIMAP_UPDATE_TRACKING", "UpdateTracking")

		self:ReloadBars()
		
		if( self.db.profile.showTemp ) then
			frame:Show()
		else
			frame:Hide()
		end
		
		self:UNIT_AURA(nil, "player")
		self:UpdateTracking()
	end)
end

-- If we want a texture that was registered later after we loaded, reload the bars so it uses the correct one
function SimpleBB:TextureRegistered(event, mediaType, key)
	if( mediaType == SML.MediaType.STATUSBAR or mediaType == SML.MediaType.FONT ) then
		for name, config in pairs(self.db.profile.groups) do
			if( config.texture == key or config.font == key ) then
				self:ReloadBars()
				return
			end
		end
	end
end

function SimpleBB:Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99Simple Buff Bars|r: " .. msg)
end

-- Configuration changed, update bars
function SimpleBB:Reload()
	if( not self.db.profile.showTrack ) then
		self.activeTrack.enabled = nil
	end
	
	if( not self.db.profile.showTemp ) then
		self.tempBuffs[1].enabled = nil
		self.tempBuffs[2].enabled = nil
		frame:Hide()
	else
		frame:Show()
	end
	
	self:ReloadBars()

	self:UNIT_AURA(nil, "player")
	self:UpdateTracking()
	
	self:UpdateDisplay("buffs")
	self:UpdateDisplay("debuffs")
end

-- BAR MANAGEMENT
local function OnShow(self)
	local config = SimpleBB.db.profile.groups[self.name]
	if( config.anchorTo and config.anchorTo ~= self.name and SimpleBB.groups[config.anchorTo] ) then
		if( SimpleBB.groups[config.anchorTo]:IsVisible() ) then
			local spacing = -config.anchorSpacing
			if( SimpleBB.db.profile.groups[config.anchorTo].growUp ) then
				spacing = config.anchorSpacing
			end

			self:SetPoint("TOPLEFT", SimpleBB.groups[config.anchorTo].container, "BOTTOMLEFT", 0, spacing)
			self:SetMovable(false)
		else
			local scale = self:GetEffectiveScale()
			local position = SimpleBB.db.profile.groups[config.anchorTo].position
			self:ClearAllPoints()
			self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", position.x / scale, position.y / scale)
			self:SetMovable(true)
		end
		
	elseif( config.position ) then
		local scale = self:GetEffectiveScale()
		self:ClearAllPoints()
		self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", config.position.x / scale, config.position.y / scale)
		self:SetMovable(true)
	else
		self:ClearAllPoints()
		self:SetPoint("CENTER", UIParent, "CENTER")
		self:SetMovable(true)
	end

	-- Check if something is anchored to us, if it is then we need to reposition them
	for name, data in pairs(SimpleBB.db.profile.groups) do
		if( data.anchorTo == self.name ) then
			OnShow(SimpleBB.groups[name])
		end
	end
end

-- Check if something is anchored to us, if it is then we need to reposition them
local function OnHide(self)
	for name, data in pairs(SimpleBB.db.profile.groups) do
		if( data.anchorTo == self.name ) then
			OnShow(SimpleBB.groups[name])
		end
	end
end

local backdrop = {bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeSize = 0.80,
		insets = {left = 1, right = 1, top = 1, bottom = 1}}

function SimpleBB:CreateGroup(name)
	-- Set defaults
	local frame = CreateFrame("Frame", nil, UIParent)
	frame:SetMovable(true)
	frame:Hide()
	
	frame:SetScript("OnHide", OnHide)
	frame:SetScript("OnShow", OnShow)
	frame.name = name
	
	-- This is wrapped around all the bars so we can have things "linked" together
	frame.container = CreateFrame("Frame", nil, frame)
	
	return frame
end

-- Updates the actual positioning of things
local function updateBar(id, row, display, config)
	local texture = SML:Fetch(SML.MediaType.STATUSBAR, config.texture)
	row:SetWidth(config.width)
	row:SetHeight(config.height)
	row:SetStatusBarTexture(texture)
	row:Hide()
	
	row.bg:SetStatusBarTexture(texture)
	
	--if( not config.colorByType ) then
	--	row:SetStatusBarColor(config.color.r, config.color.g, config.color.b, 0.80)
	--	row.bg:SetStatusBarColor(config.color.r, config.color.g, config.color.b, 0.30)
	--end
	
	row.icon:SetPoint("TOPLEFT", row, "TOP" .. config.iconPosition, display.iconPad, 0)
	row.icon:SetHeight(config.height)
	row.icon:SetWidth(config.height)
	
	local font = SML:Fetch(SML.MediaType.FONT, config.font)
	row.timer:SetFont(font, config.fontSize)
	row.timer:SetShadowOffset(1, -1)
	row.timer:SetShadowColor(0, 0, 0, 1)
	row.timer:SetHeight(config.height)
	
	row.text:SetFont(font, config.fontSize)
	row.text:SetShadowOffset(1, -1)
	row.text:SetShadowColor(0, 0, 0, 1)
	row.text:SetHeight(config.height)
	row.text:SetWidth(config.width - 40)
	
	-- Position
	if( id > 1 ) then
		if( not config.growUp ) then
			row:SetPoint("TOPLEFT", display.rows[id - 1], "BOTTOMLEFT", 0, -config.spacing)
		else
			row:SetPoint("BOTTOMLEFT", display.rows[id - 1], "TOPLEFT", 0, config.spacing)
		end
	elseif( config.growUp ) then
		row:SetPoint("BOTTOMLEFT", display, "TOPLEFT", display.barOffset, 0)
	else
		row:SetPoint("TOPLEFT", display, "BOTTOMLEFT", display.barOffset, 0)
	end
end

-- Reload everything in positioning and such
function SimpleBB:ReloadBars()
	for name, config in pairs(self.db.profile.groups) do
		local display = self.groups[name]
		display:SetWidth(config.width + config.height)
		display:SetHeight(config.height)
		display:SetScale(config.scale)
		display:SetAlpha(config.alpha)
						
		OnShow(display)

		if( config.iconPosition == "LEFT" ) then
			display.iconPad = -config.height
			display.barOffset = config.height
		else
			display.iconPad = 0
			display.barOffset = 0
		end
		
		-- Update bars
		for id, row in pairs(display.rows) do
			updateBar(id, row, display, config)
		end
		
		self:UpdateDisplay(name)
	end
end

-- Bar scripts
local function OnDragStart(self)
	if( IsAltKeyDown() and not SimpleBB.db.profile.locked ) then
		local parent = self:GetParent()
		if( parent:IsMovable() ) then
			parent:StartMoving()
			parent.isMoving = true
		end
	end
end

local function OnDragStop(self)
	local parent = self:GetParent()
	if( parent.isMoving ) then
		parent:StopMovingOrSizing()
		parent.isMoving = nil

		local scale = parent:GetEffectiveScale()
		SimpleBB.db.profile.groups[parent.name].position = { x = parent:GetLeft() * scale, y = parent:GetTop() * scale }
		
		if( parent.queueUpdate ) then
			parent.queueUpdate = nil
			
			SimpleBB:UpdateDisplay("buffs")
			SimpleBB:UpdateDisplay("debuffs")
		end
	end
end

local function OnClick(self, mouseButton)
	if( mouseButton ~= "RightButton" ) then
		return
	end
	
	if( self.type == "tempBuffs" ) then
		CancelItemTempEnchantment(self.data.slotID - 15)
	elseif( self.type == "tracking" ) then
		ToggleDropDownMenu(1, nil, MiniMapTrackingDropDown, self, 0, -5)
	end
end

local function OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
	if( self.type == "buffs" ) then
		GameTooltip:SetUnitBuff("player", self.data.buffIndex)
	elseif( self.type == "debuffs") then
		GameTooltip:SetUnitDebuff("player", self.data.buffIndex)
	elseif( self.type == "tempBuffs" ) then
		GameTooltip:SetInventoryItem("player", self.data.slotID)
	elseif( self.type == "tracking" ) then
		GameTooltip:SetTracking()
	end
end

local function OnLeave(self)
	GameTooltip:Hide()
end

-- Grab a bar to use
function SimpleBB:CreateBar(parent)
	-- Create the actual bar
	local frame = CreateFrame("StatusBar", nil, parent)
	frame:EnableMouse(true)
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", OnDragStart)
	frame:SetScript("OnDragStop", OnDragStop)
	frame:SetScript("OnMouseUp", OnClick)
	frame:SetScript("OnEnter", OnEnter)
	frame:SetScript("OnLeave", OnLeave)
	frame:Hide()
	
	frame.bg = CreateFrame("StatusBar", nil, frame)
	frame.bg:SetMinMaxValues(0, 1)
	frame.bg:SetValue(1)
	frame.bg:SetAllPoints(frame)
	frame.bg:SetFrameLevel(0)
		
	-- Create icon
	frame.icon = frame:CreateTexture(nil, "ARTWORK")
	
	-- Icon border
	frame.iconBorder = frame:CreateTexture(nil, "OVERLAY")
	frame.iconBorder:SetPoint("TOPLEFT", frame.icon)
	frame.iconBorder:SetPoint("BOTTOMRIGHT", frame.icon)
	frame.iconBorder:Hide()
	
	-- Timer text
	frame.timer = frame:CreateFontString(nil, "OVERLAY")
	frame.timer:SetJustifyH("RIGHT")
	frame.timer:SetJustifyV("CENTER")
	frame.timer:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, 0)
	
	-- Display Text
	frame.text = frame:CreateFontString(nil, "OVERLAY")
	frame.text:SetJustifyH("LEFT")
	frame.text:SetJustifyV("CENTER")
	frame.text:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, 0)
	
	table.insert(parent.rows, frame)
	
	-- Update positioning
	updateBar(#(parent.rows), frame, parent, self.db.profile.groups[parent.name])
end

local formatTime = {
	["hhmmss"] = function(text, timeLeft)
		local hours, minutes, seconds = 0, 0, 0
		if( timeLeft >= 3600 ) then
			hours = floor(timeLeft / 3600)
			timeLeft = mod(timeLeft, 3600)
		end

		if( timeLeft >= 60 ) then
			minutes = floor(timeLeft / 60)
			timeLeft = mod(timeLeft, 60)
		end

		seconds = timeLeft > 0 and timeLeft or 0

		if( hours > 0 ) then
			text:SetFormattedText("%d:%02d:%02d", hours, minutes, seconds)
		else
			text:SetFormattedText("%02d:%02d", minutes > 0 and minutes or 0, seconds)
		end
	end,
	["blizzard"] = function(text, timeLeft)
		local hours, minutes, seconds = 0, 0, 0
		if( timeLeft >= 3600 ) then
			hours = floor(timeLeft / 3600)
			timeLeft = mod(timeLeft, 3600)
		end

		if( timeLeft >= 60 ) then
			minutes = floor(timeLeft / 60)
			timeLeft = mod(timeLeft, 60)
		end

		if( hours > 0 ) then
			text:SetFormattedText("%dh%dm", hours, minutes)
		elseif( minutes > 0 ) then
			text:SetFormattedText("%dm", minutes)
		else
			text:SetFormattedText("%02ds", timeLeft > 0 and timeLeft or 0)
		end
	end,
}

-- Update visuals
local function OnUpdate(self)
	-- Time left
	local time = GetTime()
	self.secondsLeft = self.secondsLeft - (time - self.lastUpdate)
	self.lastUpdate = time
	
	self:SetValue(self.secondsLeft)

	-- Timer text, need to see if this can be optimized a bit later
	--[[
	local hour = floor(self.secondsLeft / 3600)
	local minutes = self.secondsLeft - (hour * 3600)
	minutes = floor(minutes / 60)
	
	local seconds = self.secondsLeft - ((hour * 3600) + (minutes * 60))
	]]
	
	formatTime[self.timeOption](self.timer, self.secondsLeft)
end

-- Update a single row
local buffTypes = {
	buff = {r = 0.30, g = 0.50, b = 1.0},
}

-- Setup a temporary table we can toss everything into
local tempRows = {}

local function updateRow(row, config, data)
	-- Set name/rank
	if( data.rank and data.stack and data.stack > 1 and config.showRank and config.showStack ) then
		row.text:SetFormattedText("%s %s (%s)", data.name, data.rank, data.stack)
	elseif( data.rank and config.showRank ) then
		row.text:SetFormattedText("%s %s", data.name, data.rank)
	elseif( data.stack and data.stack > 1 and config.showStack ) then
		row.text:SetFormattedText("%s (%s)", data.name, data.stack)
	else
		row.text:SetText(data.name)
	end
		
	-- Set icon
	row.icon:SetWidth(config.height)
	row.icon:SetHeight(config.height)
	row.icon:SetTexture(data.icon)
	row.icon:Show()
	
	local color
	if( data.type == "tempBuffs" ) then
		color = config.tempColor
		row.iconBorder:SetTexCoord(0, 0, 0, 0)
		row.iconBorder:SetTexture("Interface\\Buttons\\UI-TempEnchant-Border")
		row.iconBorder:Show()
	elseif( data.type == "debuffs" or data.buffIndex == -1 ) then
		if( config.colorByType ) then
			color = DebuffTypeColor[data.buffType] or DebuffTypeColor.none
		else
			color = config.color
		end

		row.iconBorder:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
		row.iconBorder:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
		row.iconBorder:SetVertexColor(color.r, color.g, color.b)
		row.iconBorder:Show()
	elseif( data.type == "tracking" and data.trackingType ~= "spell" ) then
		color = buffTypes.buff

		row.iconBorder:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
		row.iconBorder:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
		row.iconBorder:SetVertexColor(0.81, 0.81, 0.81)
		row.iconBorder:Show()
	elseif( config.colorByType ) then
		color = buffTypes.buff
		row.iconBorder:Hide()
	else
		color = config.color
		row.iconBorder:Hide()
	end
	
	-- Color bar by the debuff type
	if( color ) then
		row:SetStatusBarColor(color.r, color.g, color.b, 0.80)
		row.bg:SetStatusBarColor(color.r, color.g, color.b, 0.30)
	end

	-- Setup for sorting
	local time = GetTime()
	row.enabled = true
	row.type = data.type
	row.data = data
	row.timeOption = config.time
	
	-- Don't use an on update if it has no timer
	if( not data.untilCancelled ) then
		row.endTime = data.endTime or 0
		row.secondsLeft = row.endTime - time
		row.lastUpdate = time

		row:SetMinMaxValues(0, data.startSeconds)
		row:SetScript("OnUpdate", OnUpdate)

		row.timer:SetHeight(config.height)
		row.text:SetWidth(config.width - 40)
		row.timer:Show()
	else
		row:SetScript("OnUpdate", nil)
		row:SetMinMaxValues(0, 1)
		row:SetValue(config.fillTimeless and 1 or 0)
		row.text:SetWidth(config.width)
		row.timer:Hide()
	end
end

-- This is fairly ugly, I'm not exactly sure how I want to clean it up yet.
-- I think I'll go with some sort of single index I can sort by, and manipulate that based on setting
-- In fact, maybe I should turn this into a loadstring so I don't have to repeat the code, that also means
-- I don't have to load the functions when you probably won't need them 
local sorting = {
	["timeleft"] = function(a, b)
		if( not b or not a.enabled ) then
			return false
		elseif( not b.enabled ) then
			return true
		end
		
		if( a.type == "tracking" ) then
			return true
		elseif( b.type == "tracking" ) then
			return false
		end
		
		if( a.untilCancelled and b.untilCancelled ) then
			return a.name < b.name
		elseif( a.untilCancelled ) then
			return true
		elseif( b.untilCancelled ) then
			return false
		end

		if( a.type == "tempBuffs" and b.type == "tempBuffs" ) then
			return a.slotID < b.slotID
		elseif( a.type == "tempBuffs" ) then
			return true
		elseif( b.type == "tempBuffs" ) then
			return false
		end
		
		return a.endTime > b.endTime

	end,
	["index"] = function(a, b)
		if( not b or not a.enabled ) then
			return false
		elseif( not b.enabled ) then
			return true
		end
		
		if( a.type == "tracking" ) then
			return true
		elseif( b.type == "tracking" ) then
			return false
		end
		
		if( a.type == "tempBuffs" and b.type == "tempBuffs" ) then
			return a.slotID < b.slotID
		elseif( a.type == "tempBuffs" ) then
			return true
		elseif( b.type == "tempBuffs" ) then
			return false
		end
		
		return a.buffIndex < b.buffIndex
	end,
}


-- Update display for the passed time
function SimpleBB:UpdateDisplay(displayID)
	local display = self.groups[displayID]
	local buffs = self[displayID]
	local config = self.db.profile.groups[displayID]
	
	-- Clear table
	for i=#(tempRows), 1, -1 do
		table.remove(tempRows, i)
	end
	
	-- Create buffs
	for id, data in pairs(self[displayID]) do
		if( data.enabled and ( config.passive and not data.untilCancelled or not config.passive ) ) then
			data.type = displayID
			table.insert(tempRows, data)
		end
	end
	
	-- Merge temp weapon enchants and tracking into buffs
	if( displayID == "buffs") then
		-- Tracking
		if( self.activeTrack.enabled ) then
			table.insert(tempRows, self.activeTrack)
		end

		-- Temp weapon enchants
		for id, data in pairs(self.tempBuffs) do
			if( data.enabled ) then
				data.type = "tempBuffs"
				table.insert(tempRows, data)
			end
		end
	end
	
	-- Example for configuration
	if( self.db.profile.showExample ) then
		table.insert(tempRows, self.example[displayID])
	end
		
	-- Nothing to show
	if( #(tempRows) == 0 ) then
		display:Hide()
		return
	elseif( #(tempRows) > #(display.rows) ) then
		for id in pairs(tempRows) do
			if( not display.rows[id] ) then
				self:CreateBar(display)
			end
		end
	end

	display:Show()

	table.sort(tempRows, sorting[config.sortBy])
	
	-- Position
	local lastRow = 0
	for id, row in pairs(display.rows) do
		local buff = tempRows[id]
		if( buff and buff.enabled and id <= config.maxRows ) then
			updateRow(row, config, buff)
			lastRow = id
			row:Show()
		else
			row:Hide()
		end
	end
	
	-- Setup the container frame to wrap around it, so we can position other groups to it (if needed)
	if( display.rows[1] and display.rows[1]:IsVisible() ) then
		display.container:ClearAllPoints()
		
		-- Update frame size based on rows used
		if( config.iconPosition == "LEFT" ) then
			display.container:SetPoint("TOPLEFT", display.rows[1].icon)
			display.container:SetPoint("BOTTOMRIGHT", display.rows[lastRow])
		else
			display.container:SetPoint("TOPLEFT", display.rows[1])
			display.container:SetPoint("BOTTOMRIGHT", display.rows[lastRow].icon)
		end
	end
end

-- Get the start seconds of this buff/debuff/ect
function SimpleBB:GetStartTime(type, name, rank, timeLeft)
	if( not name ) then
		return timeLeft
	end
	
	local bID = name .. (rank or "")
	if( self.db.profile.buffTimes[type][bID] ) then
		if( timeLeft < self.db.profile.buffTimes[type][bID] ) then
			timeLeft = self.db.profile.buffTimes[type][bID]
		else
			self.db.profile.buffTimes[type][bID] = timeLeft
		end
	else
		self.db.profile.buffTimes[type][bID] = timeLeft
	end
		
	return timeLeft
end

-- Update auras
function SimpleBB:UpdateAuras(type, filter)
	for _, data in pairs(self[type]) do data.enabled = nil; data.untilCancelled = nil; end
		
	local time = GetTime()
	local buffID = 1
	while( true ) do
		local name, rank, texture, count, debuffType, duration, endTime, isMine, isStealable = UnitAura("player", buffID, filter)
		if( not name ) then break end
		
		if( not self[type][buffID] ) then
			self[type][buffID] = {}
		end
				
		local buff = self[type][buffID]
		buff.enabled = true
		buff.type = type
		buff.buffIndex = buffID
		buff.untilCancelled = duration == 0 and endTime == 0
		buff.icon = texture
		buff.buffType = debuffType
		buff.stack = count or 0
		--buff.startSeconds = duration or endTime and self:GetStartTime(type, name, rank, endTime - time) or 0
		buff.startSeconds = duration
		buff.endTime = endTime
		buff.name = name
		buff.rank = tonumber(string.match(rank, "(%d+)"))
		
		buffID = buffID + 1
	end
end

function SimpleBB:UpdateTracking()
	if( not self.db.profile.showTrack ) then
		return
	end
	
	self.activeTrack.enabled = nil
	
	for i=1, GetNumTrackingTypes() do
		local name, texture, active, type = GetTrackingInfo(i)
		if( active ) then
			self.activeTrack.name = name
			self.activeTrack.icon = texture
			self.activeTrack.trackingType = type
			self.activeTrack.enabled = true
		end
	end
	
	if( not self.activeTrack.enabled ) then
		self.activeTrack.name = L["None"]
		self.activeTrack.icon = GetTrackingTexture()
		self.activeTrack.trackingType = nil
		self.activeTrack.enabled = true
	end
	
	self:UpdateDisplay("buffs")
end

-- Parse out name/rank from a temp weapon buff
function SimpleBB:ParseName(slotID)
	if( not self.tooltip ) then
		self.tooltip = CreateFrame("GameTooltip", "SimpleBBTooltip", UIParent, "GameTooltipTemplate")
		self.tooltip:SetOwner(UIParent, "ANCHOR_NONE")
	end
	
	self.tooltip:SetInventoryItem("player", slotID)
	
	for i=1, self.tooltip:NumLines() do
		local text = getglobal("SimpleBBTooltipTextLeft" .. i):GetText()
		local name = string.match(text, "^(.+) %(%d+ [^%)]+%)$")
		if( name ) then
			local tName, rank = string.match(name, "^(.+) ([0-9]+)$")
			if( tName and rank ) then
				name = tName
			end
			
			return name, rank
		end
	end
	
	return nil, nil
end

-- Update temp weapon enchants
function SimpleBB:UpdateTempEnchant(id, slotID, hasEnchant, timeLeft, charges)
	local tempBuff = self.tempBuffs[id]
	if( not hasEnchant ) then
		tempBuff.enabled = nil
		tempBuff.untilCancelled = nil
		return
	end
	
	local name, rank = self:ParseName(slotID)
	
	-- When the players entering/leaving the world, we get a bad return on the name/rank
	-- So we only update it if we found one, and thus fixes it!
	if( name ) then
		tempBuff.name = name
		tempBuff.rank = rank
	end

	local timeLeft = timeLeft / 1000

	tempBuff.enabled = true
	tempBuff.type = "tempBuffs"
	tempBuff.slotID = slotID

	tempBuff.timeLeft = timeLeft
	tempBuff.endTime = GetTime() + timeLeft
	tempBuff.startSeconds = self:GetStartTime("tempBuffs", name, rank, timeLeft)

	tempBuff.icon = GetInventoryItemTexture("player", slotID)
	tempBuff.stack = charges or 0
end

-- Update player buff/debuffs
function SimpleBB:UNIT_AURA(event, unit)
	if( unit ~= "player" ) then
		return
	end
	
	self:UpdateAuras("buffs", "HELPFUL|PASSIVE")
	self:UpdateAuras("debuffs", "HARMFUL")
	
	self:UpdateDisplay("buffs")
	self:UpdateDisplay("debuffs")
end

-- Update temp weapons
local timeElapsed = 0
frame:SetScript("OnUpdate", function(self, elapsed)
	timeElapsed = timeElapsed + elapsed
	
	if( timeElapsed >= 1 ) then
		timeElapsed = 0

		local hasMain, mainTimeLeft, mainCharges, hasOff, offTimeLeft, offCharges = GetWeaponEnchantInfo()
		local self = SimpleBB
		
		self:UpdateTempEnchant(1, MAINHAND_SLOT, hasMain, mainTimeLeft, mainCharges)
		if( self.tempBuffs[1].enabled ) then
			self:UpdateTempEnchant(2, OFFHAND_SLOT, hasOff, offTimeLeft, offCharges)
		else
			self.tempBuffs[2].enabled = nil
			self:UpdateTempEnchant(1, OFFHAND_SLOT, hasOff, offTimeLeft, offCharges)
		end

		-- Update if needed
		self:UpdateDisplay("buffs")
	end
end)
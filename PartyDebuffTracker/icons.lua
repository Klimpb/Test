if( not Trackery ) then return end

local Icons = Trackery:NewModule("Icons", "AceEvent-3.0")

local ICON_SIZE = 20
local POSITION_SIZE = ICON_SIZE + 2
local methods = {"CreateDisplay", "ClearTimers", "CreateTimer", "RemoveTimer", "TimerExists", "UnitDied", "ReloadVisual"}

function Icons:OnInitialize()
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

-- Reposition the passed frames timers
local function repositionTimers(type)
	local frame = Icons[type]
	if( not frame or not Trackery.db.profile.anchors[type].position ) then
		return
	end
	
	local displayType = Trackery.db.profile.anchors[type].displayType
	
	-- Reposition everything
	for id, icon in pairs(frame.active) do
		if( id > 1 ) then
			icon:ClearAllPoints()
			if( displayType == "down" ) then
				icon:SetPoint("TOPLEFT", frame.active[id - 1], "BOTTOMLEFT", 0, 0)
			elseif( displayType == "left" ) then
				icon:SetPoint("TOPRIGHT", frame.active[id - 1], "TOPLEFT", 0, 0)
			elseif( displayType == "right" ) then
				icon:SetPoint("TOPLEFT", frame.active[id - 1], "TOPRIGHT", 0, 0)
			else
				icon:SetPoint("BOTTOMLEFT", frame.active[id - 1], "TOPLEFT", 0, 0)
			end
		else
			local scale = frame:GetEffectiveScale()
			local position = Trackery.db.profile.anchors[type].position
			
			if( displayType == "up" ) then
				icon:ClearAllPoints()
				icon:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", position.x / scale, (position.y / scale) + ICON_SIZE)
			else
				icon:ClearAllPoints()
				icon:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", position.x / scale, (position.y / scale) - frame:GetHeight())
			end
		end
	end
end

-- Sort timers by time left
local function sortTimers(a, b)
	return a.timeLeft < b.timeLeft
end


-- Dragging functions
local function OnDragStart(self)
	if( IsAltKeyDown() ) then
		self.isMoving = true
		self:StartMoving()
	end
end

local function OnDragStop(self)
	if( self.isMoving ) then
		self.isMoving = nil
		self:StopMovingOrSizing()
		
		local anchor = Trackery.db.profile.anchors[self.type]
		if( not anchor.position ) then
			anchor.position = { x = 0, y = 0 }
		end
		
		local scale = self:GetEffectiveScale()
		anchor.position.x = self:GetLeft() * scale
		anchor.position.y = self:GetTop() * scale
	end
end

local function OnShow(self)
	local position = Trackery.db.profile.anchors[self.type].position
	if( position ) then
		local scale = self:GetEffectiveScale()
		self:ClearAllPoints()
		self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", position.x / scale, position.y / scale)
	else
		self:ClearAllPoints()
		self:SetPoint("CENTER", UIParent, "CENTER")
	end
end

-- Update icon timer
local function OnUpdate(self, elapsed)
	local time = GetTime()
	self.timeLeft = self.timeLeft - (time - self.lastUpdate)
	self.lastUpdate = time
	
	if( self.timeLeft <= 0 ) then
		-- Check if we should start the timer again
		if( self.repeatTimer ) then
			self.timeLeft = self.startSeconds
			self.lastUpdate = time
			
			local anchor = Icons[self.type]
			table.sort(anchor.active, sortTimers)
			repositionTimers(anchor.type)
			return
		end

		Icons:RemoveTimer(self.type, self.spellID, self.sourceGUID)
		return
	end
	
	if( self.timeLeft > 10 ) then
		self.text:SetFormattedText("%d", self.timeLeft)
	else
		self.text:SetFormattedText("%.1f", self.timeLeft)
	end
	
	-- <=30% left, go red
	--if( self.timeLeft <= self.redAt ) then
	--	self.text:SetTextColor(1, 0, 0)
	--else
	--	self.text:SetTextColor(1, 1, 1)
	--end
end

-- Create our little icon frame
local function createRow(parent)
	local frame = CreateFrame("Frame", nil, UIParent)
	frame:SetWidth(50)
	frame:SetHeight(ICON_SIZE)
	frame:SetScript("OnUpdate", OnUpdate)
	frame:SetScale(parent:GetScale())
	frame:SetClampedToScreen(true)
	frame:Hide()
	
	frame.icon = frame:CreateTexture(nil, "BACKGROUND")
	frame.icon:SetWidth(ICON_SIZE)
	frame.icon:SetHeight(ICON_SIZE)
	frame.icon:SetPoint("LEFT")
	
	frame.text = frame:CreateFontString(nil, "BACKGROUND")
	frame.text:SetFont((GameFontHighlight:GetFont()), 12, "OUTLINE")
	frame.text:SetPoint("LEFT", POSITION_SIZE, 0)
	--frame.text:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)

	frame.stackText = frame:CreateFontString(nil, "BACKGROUND")
	frame.stackText:SetFont((GameFontHighlight:GetFont()), 12, "OUTLINE")
	frame.stackText:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", 0, 0)
	
	return frame
end

-- PUBLIC METHODS
-- Create our main display frame
local backdrop = {bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeSize = 0.80,
		insets = {left = 1, right = 1, top = 1, bottom = 1}}

function Icons:CreateDisplay(type)
	local frame = CreateFrame("Frame", nil, UIParent)
	frame:SetWidth(120)
	frame:SetHeight(12)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:SetClampedToScreen(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScale(Trackery.db.profile.anchors[type].scale)
	frame:SetBackdrop(backdrop)
	frame:SetBackdropColor(0, 0, 0, 1.0)
	frame:SetBackdropBorderColor(0.75, 0.75, 0.75, 1.0)
	frame:SetScript("OnDragStart", OnDragStart)
	frame:SetScript("OnDragStop", OnDragStop)
	frame:SetScript("OnShow", OnShow)
	frame:Hide()
	
	frame.active = {}
	frame.inactive = {}
	frame.type = type
	
	if( Trackery.db.profile.showAnchors ) then
		frame:Show()
	end
	
	-- Display name
	frame.text = frame:CreateFontString(nil, "OVERLAY")
	frame.text:SetPoint("CENTER", frame)
	frame.text:SetFont((GameFontHighlight:GetFont()), 11)
	frame.text:SetText(Trackery.db.profile.anchors[type].text)
	
	return frame
end

-- Return an object to access our visual style
function Icons:LoadVisual()
	local obj = {}
	for _, func in pairs(methods) do
		obj[func] = Icons[func]
	end
	
	-- Create anchors
	for name, data in pairs(Trackery.db.profile.anchors) do
		if( data.enabled ) then
			Icons[name] = obj:CreateDisplay(name)
		end
	end
	
	return obj
end

-- Clear all running timers for this anchor type
function Icons:ClearTimers(type)
	local frame = Icons[type]
	if( not frame ) then
		return
	end
	
	for i=#(frame.active), 1, -1 do
		frame.active[i]:Hide()
				
		table.insert(frame.inactive, frame.active[i])
		table.remove(frame.active, i)
	end
end

-- Unit died, remove their timers
function Icons:UnitDied(diedGUID)
	-- Loop through all created anchors
	for anchorName in pairs(Trackery.db.profile.anchors) do
		local frame = Icons[anchorName]
		if( frame and #(frame.active) > 0 ) then
			-- Now through all active timers
			for i=#(frame.active), 1, -1 do
				local row = frame.active[i]

				if( row.sourceGUID == diedGUID ) then
					row:Hide()

					table.insert(frame.inactive, row)
					table.remove(frame.active, i)
				end
			end

			-- No more icons, hide the base frame
			if( #(frame.active) == 0 ) then
				frame:Hide()
			end

			-- Reposition everything
			repositionTimers(anchorName)
		end
	end
end

-- Create a new timer
function Icons:CreateTimer(showIn, spellID, spellName, icon, seconds, stack, sourceGUID)
	local anchorFrame = Icons[showIn]
	if( not anchorFrame or not Trackery.db.profile.anchors[showIn] or not Trackery.db.profile.anchors[showIn].enabled ) then
		return
	end	

	-- Check if we need to create a new row
	local frame = table.remove(anchorFrame.inactive, 1)
	if( not frame ) then
		frame = createRow(anchorFrame)
	end
	
	if( stack > 0 ) then
		frame.stackText:SetText(stack)
		frame.stackText:Show()
	else
		frame.stackText:Hide()
	end

	-- Set it for when it fades
	frame.id = id
	
	frame.spellID = spellID
	frame.spellName = spellName

	frame.sourceGUID = sourceGUID

	frame.startSeconds = seconds
	frame.timeLeft = seconds
	frame.lastUpdate = GetTime()
	frame.stack = stack
	frame.redAt = seconds * 0.30
	
	frame.type = anchorFrame.type
	frame.icon:SetTexture(icon)
	frame:Show()
	
	-- Change this icon to active
	table.insert(anchorFrame.active, frame)
	table.sort(anchorFrame.active, sortTimers)

	-- Reposition
	repositionTimers(anchorFrame.type)
end

-- Remove a specific anchors timer by spellID/sourceGUID
function Icons:RemoveTimer(anchorName, spellID, sourceGUID)
	local anchorFrame = Icons[anchorName]
	if( not anchorFrame ) then
		return nil
	end
	
	-- Remove the icon timer
	local removed
	for i=#(anchorFrame.active), 1, -1 do
		local row = anchorFrame.active[i]
		if( row.spellID == spellID and row.sourceGUID == sourceGUID ) then
			row:Hide()
			
			table.insert(anchorFrame.inactive, row)
			table.remove(anchorFrame.active, i)
			
			removed = true
			break
		end
	end
	
	-- Didn't remove anything, nothing to change
	if( not removed ) then
		return nil
	end
	
	-- Reposition everything
	repositionTimers(anchorFrame.type)
	return true
end

function Icons:ReloadVisual()
	-- Update anchors and icons inside
	for key, data in pairs(Trackery.db.profile.anchors) do
		local frame = Icons[key]
		if( frame ) then
			-- Update frame scale
			frame:SetScale(data.scale)

			-- Update icon scale
			for _, frame in pairs(frame.active) do
				frame:SetScale(data.scale)
			end

			for _, frame in pairs(frame.inactive) do
				frame:SetScale(data.scale)
			end

			-- Annnd make sure it's shown or hidden
			if( Trackery.db.profile.showAnchors ) then
				frame:Show()
			else
				frame:Hide()
			end
		end
	end
end


-- We delay this until PEW to fix UIScale issues
function Icons:PLAYER_ENTERING_WORLD()
	for key, data in pairs(Trackery.db.profile.anchors) do
		local frame = self[key]
		if( frame ) then
			OnShow(frame)
		end
	end
	
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end
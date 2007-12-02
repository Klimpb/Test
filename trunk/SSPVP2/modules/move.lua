local Move = SSPVP:NewModule("Move", "AceEvent-3.0")
local L = SSPVPLocals
local originalPosition = {}
local tooltip

function Move:OnEnable()
	if( self.defaults ) then return end

	self.defaults = {
		profile = {
			score = true,
			pvp = true,
			capture = true,
			position = {},
		},
	}
	
	self.db = SSPVP.db:RegisterNamespace("move", self.defaults)
	self:RestorePosition("pvp", WorldStateAlwaysUpFrame)
	self:RestorePosition("score", WorldStateScoreFrame)

	tooltip = CreateFrame("GameTooltip", "SSInfoTooltip", nil, "GameTooltipTemplate")

	self:Reload()
end

function Move:Reload()
	self:TogglePVP()
	self:ToggleCapture()
	self:ToggleScore()
end

function Move:SavePosition(type, frame)
	if( not self.db.profile.position[type] ) then
		self.db.profile.position[type] = {}

	end
	

	self.db.profile.position[type].x = frame:GetLeft()
	self.db.profile.position[type].y = frame:GetTop()
end

function Move:ResetPosition(type, frame)
	frame:ClearAllPoints()
	frame:SetPoint(unpack(originalPosition[type]))
	
	self.db.profile.position[type] = nil
end

function Move:RestorePosition(type, frame)
	-- Save original position before we modify it
	if( not originalPosition[type] ) then
		originalPosition[type] = {frame:GetPoint()}
	end

	if( not self.db.profile.position[type] ) then
		return
	end
	
	frame:ClearAllPoints()
	frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", self.db.profile.position[type].x, self.db.profile.position[type].y)
end

local function showTooltip(self)
	tooltip:SetOwner(self, "ANCHOR_RIGHT")
	tooltip:SetText(L["Left Click + Drag to move the frame, Right Click + Drag to reset it to it's original position."], nil, nil, nil, nil, 1)
	tooltip:Show()
end

local function hideTooltip(self)
	tooltip:Hide()
end

function Move:ToggleCapture()
	if( self.db.profile.capture ) then
		if( self.captureFrame ) then
			self.captureFrame:Hide()
		end
		
		return
	end

end

function Move:TogglePVP()
	if( self.db.profile.pvp ) then
		if( self.pvpFrame ) then
			self.pvpFrame:Hide()
		end
		
		return
	end
	
	self.pvpFrame = self:CreateAnchor("pvp", L["PvP Objectives Anchor"], WorldStateAlwaysUpFrame)
end


function Move:ToggleScore()
	if( self.db.profile.score ) then
		if( self.scoreFrame ) then
			self.scoreFrame:Hide()
		end
		
		return
	end
	
	self.scoreFrame = self:CreateAnchor("score", L["Score Objectives Anchor"], WorldStateScoreFrame)
end

local backdrop = {bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 9,
		edgeSize = 9,
		insets = { left = 2, right = 2, top = 2, bottom = 2 }}

local function onDragStart(self)
	if( button == "RightButton" ) then
		Move:ResetPosition(self.type, self.anchor)
		return
	end

	self.isMoving = true
	self.anchor:SetMovable(true)
	self.anchor:StartMoving()
end

local function onDragStop(self)
	if( self.isMoving ) then
		Move:SavePosition(self.type, self.anchor)

		-- Whenever you call StopMovingOrSizing() SetUserPlaced is changed
		-- back to true
		self.isMoving = nil
		self.anchor:StopMovingOrSizing()
		self.anchor:SetUserPlaced(nil)
		self.anchor:SetMovable(false)
	end
end

function Move:CreateAnchor(type, text, anchor)
	local frame = CreateFrame("Frame", nil, anchor)
	frame:SetHeight(20)
	frame:SetWidth(150)
	frame:RegisterForDrag("LeftButton", "RightButton")
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:SetPoint("CENTER", anchor, "TOP", 0, 0)
	frame:SetScript("OnEnter", showTooltip)
	frame:SetScript("OnLeave", hideTooltip)
	
	frame.type = type
	frame.anchor = anchor
	
	frame:SetScript("OnDragStart", onDragStart)
	frame:SetScript("OnDragStop", onDragStop)
	
	frame:SetBackdrop(backdrop)	
	frame:SetBackdropColor(0, 0, 0, 1.0)
	frame:SetBackdropBorderColor(0.75, 0.75, 0.75, 1.0)

	frame.text = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	frame.text:SetText(text)
	frame.text:SetPoint("CENTER", frame, "CENTER")
	
	return frame
end
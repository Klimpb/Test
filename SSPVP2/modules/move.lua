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

function Move:TogglePVP()
	if( self.db.profile.pvp ) then
		if( self.pvpFrame ) then
			self.pvpFrame:Hide()
		end
		
		return
	end
	
	self.pvpFrame = CreateFrame("Frame", nil, WorldStateAlwaysUpFrame)
	self.pvpFrame:SetHeight(20)
	self.pvpFrame:SetWidth(125)
	self.pvpFrame:RegisterForDrag("LeftButton", "RightButton")
	self.pvpFrame:EnableMouse(true)
	self.pvpFrame:SetMovable(true)
	self.pvpFrame:SetClampedToScreen(true)
	self.pvpFrame:SetPoint("CENTER", WorldStateAlwaysUpFrame, "TOP", 12, 0)
	self.pvpFrame:SetScript("OnEnter", showTooltip)
	self.pvpFrame:SetScript("OnLeave", hideTooltip)
	self.pvpFrame:SetScript("OnDragStart", function(self, button)
		if( button == "RightButton" ) then
			Move:ResetPosition("pvp", WorldStateAlwaysUpFrame)
			return
		end
		
		self.isMoving = true

		WorldStateAlwaysUpFrame:SetMovable(true)
		WorldStateAlwaysUpFrame:StartMoving()
	end)
	
	self.pvpFrame:SetScript("OnDragStop", function(self)
		if( self.isMoving ) then
			self.isMoving = nil
			
			Move:SavePosition("pvp", WorldStateAlwaysUpFrame)

			WorldStateAlwaysUpFrame:StopMovingOrSizing()
			WorldStateAlwaysUpFrame:SetUserPlaced(nil)
			WorldStateAlwaysUpFrame:SetMovable(false)
		end
	end)
	
	self.pvpFrame:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = true,
				tileSize = 9,
				edgeSize = 9,
				insets = { left = 2, right = 2, top = 2, bottom = 2 }})	
	self.pvpFrame:SetBackdropColor(0, 0, 0, 1.0)
	self.pvpFrame:SetBackdropBorderColor(0.75, 0.75, 0.75, 1.0)

	self.pvpFrame.text = self.pvpFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	self.pvpFrame.text:SetText(L["PvP Objectives Anchor"])
	self.pvpFrame.text:SetPoint("CENTER", self.pvpFrame, "CENTER")
end

function Move:ToggleCapture()
	if( self.db.profile.capture ) then
		if( self.captureFrame ) then
			self.captureFrame:Hide()
		end
		
		return
	end

end

function Move:ToggleScore()
	if( self.db.profile.score ) then
		if( self.scoreFrame ) then
			self.scoreFrame:Hide()
		end
		
		return
	end

	self.scoreFrame = CreateFrame("Frame", nil, WorldStateScoreFrame)
	self.scoreFrame:SetHeight(20)
	self.scoreFrame:SetWidth(150)
	self.scoreFrame:RegisterForDrag("LeftButton", "RightButton")
	self.scoreFrame:EnableMouse(true)
	self.scoreFrame:SetMovable(true)
	self.scoreFrame:SetClampedToScreen(true)
	self.scoreFrame:SetPoint("CENTER", WorldStateScoreFrame, "TOP", 0, 0)
	self.scoreFrame:SetScript("OnEnter", showTooltip)
	self.scoreFrame:SetScript("OnLeave", hideTooltip)
	self.scoreFrame:SetScript("OnDragStart", function(self, button)
		if( button == "RightButton" ) then
			Move:ResetPosition("score", WorldStateScoreFrame)
			return
		end
		
		self.isMoving = true

		WorldStateScoreFrame:SetMovable(true)
		WorldStateScoreFrame:StartMoving()
	end)
	
	self.scoreFrame:SetScript("OnDragStop", function(self)
		if( self.isMoving ) then
			self.isMoving = nil
			
			Move:SavePosition("score", WorldStateScoreFrame)

			WorldStateScoreFrame:StopMovingOrSizing()
			WorldStateScoreFrame:SetUserPlaced(nil)
			WorldStateScoreFrame:SetMovable(false)
		end
	end)
	
	self.scoreFrame:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = true,
				tileSize = 9,
				edgeSize = 9,
				insets = { left = 2, right = 2, top = 2, bottom = 2 }})	
	self.scoreFrame:SetBackdropColor(0, 0, 0, 1.0)
	self.scoreFrame:SetBackdropBorderColor(0.75, 0.75, 0.75, 1.0)

	self.scoreFrame.text = self.scoreFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	self.scoreFrame.text:SetText(L["Score Objectives Anchor"])
	self.scoreFrame.text:SetPoint("CENTER", self.scoreFrame, "CENTER")
end
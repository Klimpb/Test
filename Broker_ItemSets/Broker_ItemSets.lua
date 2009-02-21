local BIS = ItemSets:NewModule("Broker_ItemSets", "AceEvent-3.0")
local timeElapsed = 0
local frame, LDBObj

function BIS:OnInitialize()
	-- Create LDB object
	LDBObj = LibStub("LibDataBroker-1.1"):NewDataObject("ItemSets", {type = "data source", OnClick = BIS.OnClick, OnEnter = BIS.OnEnter, OnLeave = BIS.OnLeave, icon = "Interface\\Icons\\INV_Sword_126", text = ""})

	-- Update set information
	self:RegisterEvent("PLAYER_ENTERING_WORLD", function()
		BIS:UnregisterEvent("PLAYER_ENTERING_WORLD")
		BIS:UpdateSet()
	end)
	
	-- Throttle updating on this
	self:RegisterEvent("UNIT_INVENTORY_CHANGED", function()
		timeElapsed = 0
		frame:Show()
	end)
	
	-- Queue updated
	self:RegisterMessage("IS_UPDATE_QUEUED", "UpdateSet")
end

function BIS:UpdateSet()
	local equippedName = ItemSets.db.profile.setName
	local queuedName = ItemSets.db.profile.queued.name
	
	if( queuedName ) then
		LDBObj.text = string.format("%s (%s)", equippedName or "Unknown", queuedName)
	elseif( equippedName ) then
		LDBObj.text = equippedName
	else
		LDBObj.text = "Unknown set"
	end
end

local function equipSet(self)
	ItemSets:EquipByName(self.name)
end

local function pushSet(self)
	ItemSets:PushSet(self:GetParent().name)
end

local function pullSet(self)
	ItemSets:PullSet(self:GetParent().name)
end

-- AHEM
local tooltip
local insideChild
local function childOnEnter(self)
	insideChild = true
end

local function childOnLeave(self)
	insideChild = nil
	if( not MouseIsOver(self:GetParent()) and not MouseIsOver(self:GetParent():GetParent()) ) then
		tooltip:Hide()
	end
end

local function sortSets(a, b)
	return a.name < b.name
end

function BIS.OnClick(frame, mouse)
	if( mouse == "RightButton" ) then
		ItemSets.modules.Config:Open()
	end
end

function BIS.OnEnter(frame)
	if( not tooltip ) then
		tooltip = CreateFrame("Frame", nil, frame)
		tooltip:SetBackdrop(GameTooltip:GetBackdrop())
		tooltip:SetBackdropBorderColor(TOOLTIP_DEFAULT_COLOR.r, TOOLTIP_DEFAULT_COLOR.g, TOOLTIP_DEFAULT_COLOR.b);
		tooltip:SetBackdropColor(TOOLTIP_DEFAULT_BACKGROUND_COLOR.r, TOOLTIP_DEFAULT_BACKGROUND_COLOR.g, TOOLTIP_DEFAULT_BACKGROUND_COLOR.b, 1.0);
		tooltip:SetScale(0.90)
		tooltip:SetWidth(165)
		tooltip:SetClampedToScreen(true)
		tooltip:SetToplevel(true)
		tooltip:SetFrameStrata("HIGH")
		tooltip:SetScript("OnLeave", BIS.OnLeave)
		tooltip:EnableMouse(true)
		tooltip.rows = {}
	end
	
	tooltip:SetPoint("TOPLEFT", frame, "BOTTOMLEFT")
	tooltip:Show()

	for _, row in pairs(tooltip.rows) do
		row:Hide()
	end	

	-- Load up buttons for clicks
	local usedRows = 0
	local height = 4
	for name, items in pairs(ItemSets.db.profile.sets) do
		usedRows = usedRows + 1
		height = height + 23
		
		local row = tooltip.rows[usedRows]
		if( not row ) then
			row = CreateFrame("Button", nil, tooltip)
			row:SetHeight(15)
			row:SetWidth(80)
			row:SetHighlightFontObject(GameFontNormal)
			row:SetNormalFontObject(GameFontHighlight)
			row:SetScript("OnClick", equipSet)
			row:SetScript("OnEnter", childOnEnter)
			row:SetScript("OnLeave", childOnLeave)
			row:SetText("*")
			row:GetFontString():SetPoint("TOPLEFT", row)

			row.push = CreateFrame("Button", nil, row, "UIPanelButtonGrayTemplate")
			row.push:SetText("Push")
			row.push:SetPoint("TOPRIGHT", row, "TOPRIGHT", 31, 0)
			row.push:SetHeight(15)
			row.push:SetWidth(34)
			row.push:SetScript("OnClick", pushSet)
			row.push:SetScript("OnEnter", childOnEnter)
			row.push:SetScript("OnLeave", childOnLeave)

			row.pull = CreateFrame("Button", nil, row, "UIPanelButtonGrayTemplate")
			row.pull:SetText("Pull")
			row.pull:SetPoint("TOPLEFT", row.push, "TOPRIGHT", 2, 0)
			row.pull:SetHeight(15)
			row.pull:SetWidth(34)
			row.pull:SetScript("OnClick", pullSet)
			row.pull:SetScript("OnEnter", childOnEnter)
			row.pull:SetScript("OnLeave", childOnLeave)

			tooltip.rows[usedRows] = row
		end
		
		row.name = name
		row:SetText(name)
		row:Show()
	end
	
	-- Nothing to show
	if( usedRows == 0 ) then
		tooltip:Hide()
		return
	end
	
	-- Sort by alphabetical order
	table.sort(tooltip.rows, sortSets)
	
	-- Reposition based on new order
	for id, row in pairs(tooltip.rows) do
		if( id > 1 ) then
			row:ClearAllPoints()
			row:SetPoint("TOPLEFT", tooltip.rows[id - 1], "BOTTOMLEFT", 0, -8)
		else
			row:ClearAllPoints()
			row:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 8, -6)
		end

	end
	
	tooltip:SetHeight(height)
end

function BIS.OnLeave(frame)
	if( tooltip and not MouseIsOver(tooltip) and not insideChild ) then
		tooltip:Hide()
	end
end

frame = CreateFrame("Frame")
frame:Hide()
frame:SetScript("OnUpdate", function(self, elapsed)
	timeElapsed = timeElapsed + elapsed
	
	if( timeElapsed >= 0.50 ) then
		self:Hide()
		BIS:UpdateSet()
	end
end)
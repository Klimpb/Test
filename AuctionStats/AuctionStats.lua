AuctionStats = LibStub("AceAddon-3.0"):NewAddon("AuctionStats", "AceEvent-3.0")

local L = AuctionStatLocals

local MAX_DATE_ROWS = 23
local MAX_DATA_ROWS = 19
local MAX_DATA_COLUMNS = 4

local monthTable = {day = 1, hour = 0}

-- Total data per day/month including the item statistics related to that
local auctionData = {}

-- Quick sortable tables we can use
local auctionDisplay = {}

function AuctionStats:OnInitialize()
	self.defaults = {
		profile = {
		},
	}
	self.db = LibStub:GetLibrary("AceDB-3.0"):New("AuctionStatsDB", self.defaults)
	
	-- No data found, default to current char
	if( not self.db.profile.gatherData ) then
		self.db.profile.gatherData = {[string.format("%s:%s", GetRealmName(), UnitName("player"))] = true}
	end
	
	SLASH_AUCTIONSTATS1 = "/auctionstats"
	SLASH_AUCTIONSTATS2 = "/as"
	SlashCmdList["AUCTIONSTATS"] = function(msg)
		AuctionStats:CreateGUI()
		AuctionStats.frame:Show()
	end
end

local function sortTime(a, b)
	return a < b
end

local function getTime(currentTime, day, hour)
	monthTable.year = date("%Y", currentTime)
	monthTable.month = date("%m", currentTime)
	monthTable.day = day or date("%d", currentTime)
	monthTable.hour = hour or 0
	
	return time(monthTable)
end

local function hideTooltip()
	GameTooltip:Hide()
end

local function showTooltip(self)
	if( self.tooltip ) then
		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
		GameTooltip:SetText(self.tooltip, nil, nil, nil, nil, 1)
	end
end

local function showDisplayGUI(self)
	AuctionStats.frame.dataKey = self.dataKey
	AuctionStats.frame.resortList = true
	AuctionStats:ViewBreakdown()
end

-- Quick merge function to add the data from one table to the main one
local mergeKeys = {"totalSold", "totalMade", "totalDeposit", "totalFee", "totalSpent", "totalBought", "totalProfit"}
local function mergeDataTables(to, from)
	for _, key in pairs(mergeKeys) do
		to[key] = (to[key] or 0) + from[key]
	end
end

function AuctionStats:ParseData()
	for k in pairs(auctionData) do auctionData[k] = nil end
	
	for charID in pairs(self.db.profile.gatherData) do
		local server, name = string.split(":", charID)
		
		-- Make sure this server/character has data
		if( BeanCounterDB[server] and BeanCounterDB[server][name] ) then
			local auctionDB = BeanCounterDB[server][name]
			
			-- Loop through items we've succesfully bought out, or bid and won
			for itemid, itemData in pairs(auctionDB["completedBids/Buyouts"]) do
				itemid = tonumber(itemid)
				
				-- Annd loop through each transaction for this item
				for _, line in pairs(itemData) do
					local itemName, _, _, _, _, buyout, bid, buyer, arrivedAt = string.split(";", line)
					local time = getTime(arrivedAt, nil, 10)
					
					if( not auctionData[time] ) then
						auctionData[time] = {type = "day", time = time, temp = {}}
					end

					if( not auctionData[time].temp[itemid] ) then
						auctionData[time].temp[itemid] = { totalSold = 0, totalMade = 0, totalDeposit = 0, totalFee = 0, totalSpent = 0, totalBought = 0 }
					end

					auctionData[time].temp[itemid].time = time
					auctionData[time].temp[itemid].itemid = itemid
					auctionData[time].temp[itemid].totalBought = auctionData[time].temp[itemid].totalBought + 1
					
					-- If the buyout is 0 then we won it off of bid
					buyout = tonumber(buyout)
					if( buyout > 0 ) then
						auctionData[time].temp[itemid].totalSpent = auctionData[time].temp[itemid].totalSpent + buyout
					else
						auctionData[time].temp[itemid].totalSpent = auctionData[time].temp[itemid].totalSpent + bid
					end
				end
			end
			
			-- Loop through items we've succesfully sold
			for itemid, itemData in pairs(auctionDB["completedAuctions"]) do
				itemid = tonumber(itemid)

				-- Loop through each item transaction
				for _, line in pairs(itemData) do
					local itemName, _, money, deposit, fee, buyout, bid, buyer, arrivedAt = string.split(";", line)
					local time = getTime(arrivedAt, nil, 10)
					if( not auctionData[time] ) then
						auctionData[time] = {type = "day", time = time, temp = {}}
					end

					if( not auctionData[time].temp[itemid] ) then
						auctionData[time].temp[itemid] = { totalSold = 0, totalMade = 0, totalDeposit = 0, totalFee = 0, totalSpent = 0, totalBought = 0 }
					end
					
					
					auctionData[time].temp[itemid].time = time
					auctionData[time].temp[itemid].itemid = itemid
					auctionData[time].temp[itemid].totalSold = auctionData[time].temp[itemid].totalSold + 1
					auctionData[time].temp[itemid].totalMade = auctionData[time].temp[itemid].totalMade + money
					auctionData[time].temp[itemid].totalDeposit = auctionData[time].temp[itemid].totalDeposit + deposit
					auctionData[time].temp[itemid].totalFee = auctionData[time].temp[itemid].totalFee + fee
				end
			end
		end
	end
	
	-- Now make a summary based on month
	for time, row in pairs(auctionData) do
		local month = getTime(time, 1, 0)
		if( not auctionData[month] ) then
			auctionData[month] = {type = "month", time = month, temp = {}}
		end
		
		for itemid, data in pairs(row.temp) do
			if( not auctionData[month].temp[itemid] ) then
				auctionData[month].temp[itemid] = {}
			end
			
			data.totalProfit = data.totalMade - data.totalSpent
			
			-- Merge the items total stats, this months total stats, and this days total stats
			mergeDataTables(auctionData[month].temp[itemid], data)
			mergeDataTables(auctionData[month], data)
			mergeDataTables(auctionData[time], data)
		end
	end
	
	-- Now we have to take our item tables, and turn them into indexed ones
	for time, row in pairs(auctionData) do

		row.items = {}
		for itemid, data in pairs(row.temp) do
			data.time = time
			data.itemid = itemid
			data.itemLink = select(2, GetItemInfo(itemid)) or itemid
			data.itemName = select(1, GetItemInfo(itemid)) or itemid
			
			table.insert(row.items, data)
		end
		
		-- Remove our temp table for gathering the data
		row.temp = nil
	end
	
	-- Add in the time formats so we can actually do our display things
	for time in pairs(auctionData) do
		table.insert(auctionDisplay, time)
	end
	
	table.sort(auctionDisplay, sortTime)
end

-- This is quickly hacked together, I'll clean it up later
function AuctionStats:FormatNumber(number, decimal)
	-- Quick "rounding"
	if( decimal and math.floor(number) ~= number ) then
		number = string.format("%.1f", number)
	else

		number = math.floor(number + 0.5)

	end

	while( true ) do
		number, k = string.gsub(number, "^(-?%d+)(%d%d%d)", "%1,%2")
		if( k == 0 ) then break end

	end

	return number
end

function AuctionStats:UpdateBrowserRow(data, id)
	local color
	if( data.totalProfit < 0 ) then
		color = RED_FONT_COLOR_CODE
	elseif( data.totalProfit > 0 ) then
		color = GREEN_FONT_COLOR_CODE
	else
		color = "|cffffffff"
	end

	local row = self.dateRows[id]
	row.profit:SetFormattedText("[%s%s%sg]", color, self:FormatNumber(data.totalProfit / 10000), FONT_COLOR_CODE_CLOSE)
	row.tooltip = string.format(L["Spent: |cffffffff%s|rg\nMade: |cffffffff%s|r\nProfit: |cffffffff%s|rg"], self:FormatNumber(data.totalSpent / 10000), self:FormatNumber(data.totalMade / 10000), self:FormatNumber(data.totalProfit / 10000))
	row.dataKey = data.time
	row:Show()
	
	if( data.type == "day" ) then
		row:SetText(date("%A, %d", data.time))
	else
		row:SetText(date("%b %Y", data.time))
	end
end

function AuctionStats:UpdateBrowseGUI()
	local self = AuctionStats
	FauxScrollFrame_Update(self.leftFrame.scroll, #(auctionDisplay), MAX_DATE_ROWS, 22)
	
	-- Hide everything to reset it
	for i=1, MAX_DATE_ROWS do
		self.dateRows[i]:Hide()
	end
	
	-- List!
	local usedRows = 0
	for id, key in pairs(auctionDisplay) do
		if( id >= FauxScrollFrame_GetOffset(self.leftFrame.scroll) and usedRows < MAX_DATE_ROWS ) then
			usedRows = usedRows + 1
			self:UpdateBrowserRow(auctionData[key], usedRows)
			
			if( #(auctionDisplay) < MAX_DATE_ROWS ) then
				self.dateRows[usedRows]:SetWidth(168)
			else
				self.dateRows[usedRows]:SetWidth(149)
			end
		end
	end
end

local function sortBreakdownData(self)
	if( self.sortType ~= AuctionStats.frame.sortType ) then
		AuctionStats.frame.sortOrder = false
		AuctionStats.frame.sortType = self.sortType
	else
		AuctionStats.frame.sortOrder = not AuctionStats.frame.sortOrder
	end
	
	AuctionStats.frame.resortList = true
	AuctionStats:ViewBreakdown()
end

local function sortItemData(a, b)
	local sortBy = AuctionStats.frame.sortType
	
	
	if( AuctionStats.frame.sortOrder ) then
		return a[sortBy] < b[sortBy]
	else
		return a[sortBy] > b[sortBy]

	end
end

function AuctionStats:ViewBreakdown()
	local self = AuctionStats
	FauxScrollFrame_Update(self.middleFrame.scroll, #(auctionData[self.frame.dataKey].items), MAX_DATA_ROWS, 22)
	
	if( self.frame.resortList ) then
		table.sort(auctionData[self.frame.dataKey].items, sortItemData)
		self.frame.resortList = nil
	end

	-- Hide everything to reset it
	for i=1, MAX_DATA_ROWS do
		for j=1, MAX_DATA_COLUMNS do
			self.rows[i][j]:Hide()
		end

	end

	-- List!
	local usedRows = 0
	for id, data in pairs(auctionData[self.frame.dataKey].items) do
		if( data.day == self.frame.currentDay and id >= FauxScrollFrame_GetOffset(self.middleFrame.scroll) and usedRows < MAX_DATA_ROWS ) then
			usedRows = usedRows + 1

			local row = self.rows[usedRows]

			row[1]:SetText(data.itemLink)
			row[1].tooltip = data.itemLink
			
			row[2]:SetFormattedText("%s|cffffffffg|r", self:FormatNumber(data.totalMade / 10000))
			row[2]:SetTextColor(0, 1, 0)
			if( data.totalSold > 0 ) then
				row[2].tooltip = string.format(L["Auctions Completed: %d\nAverage Price: |cffffffff%s|rg"], data.totalSold, self:FormatNumber((data.totalMade / data.totalSold) / 10000, true))
			else
				row[2].tooltip = string.format(L["Auctions Completed: %d\nAverage Price: |cffffffff%s|rg"], 0, 0)
			end
						
			row[3]:SetFormattedText("%s|cffffffffg|r", self:FormatNumber(data.totalSpent / 10000))
			row[3]:SetTextColor(1, 0, 0)
			if( data.totalBought > 0 ) then
				row[3].tooltip = string.format(L["Auctions Won: %d\nAverage Price: |cffffffff%s|rg"], data.totalBought, self:FormatNumber((data.totalSpent / data.totalBought) / 10000, true))
			else
				row[3].tooltip = string.format(L["Auctions Won: %d\nAverage Price: |cffffffff%s|rg"], 0, 0)
			end

			row[4]:SetFormattedText("%s|cffffffffg|r", self:FormatNumber(data.totalProfit / 10000))

			if( data.totalProfit < 0 ) then
				row[4]:SetTextColor(1, 0, 0)	
			elseif( data.totalProfit > 0 ) then
				row[4]:SetTextColor(0, 1, 0)	
			else
				row[4]:SetTextColor(1, 1, 1)	
			end

			for j=1, MAX_DATA_COLUMNS do
				self.rows[usedRows][j]:Show()
			end
		end
	end
end

-- GUI Creation
function AuctionStats:CreateGUI()
	self.frame = CreateFrame("Frame", "AuctionStatsGUI", UIParent)
	self.frame:SetWidth(550)
	self.frame:SetHeight(400)
	self.frame:SetMovable(true)
	self.frame:EnableMouse(true)
	self.frame:SetClampedToScreen(true)
	self.frame:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		edgeSize = 26,
		insets = {left = 9, right = 9, top = 9, bottom = 9},
	})
	self.frame:SetScript("OnShow", function(self)
		AuctionStats:ParseData()
		AuctionStats:UpdateBrowseGUI()
		
		-- Show the last days info if we have nothing selected
		if( not self.dataKey ) then
			self.dataKey = auctionDisplay[#(auctionDisplay)]
			AuctionStats:ViewBreakdown()
		end
	end)
	
	self.frame.sortOrder = false
	self.frame.sortType = "totalProfit"
	self.frame.resortList = true
	self.frame:Hide()
	
	-- Make it act like a real frame
	self.frame:SetAttribute("UIPanelLayout-defined", true)
	self.frame:SetAttribute("UIPanelLayout-enabled", true)
 	self.frame:SetAttribute("UIPanelLayout-area", "doublewide")
	self.frame:SetAttribute("UIPanelLayout-whileDead", true)
	table.insert(UISpecialFrames, "AuctionStatsGUI")
	
	-- Create the title/movy thing
	local texture = self.frame:CreateTexture(nil, "ARTWORK")
	texture:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
	texture:SetPoint("TOP", 0, 12)
	texture:SetWidth(250)
	texture:SetHeight(60)
	
	local title = CreateFrame("Button", nil, self.frame)
	title:SetPoint("TOP", 0, 4)
	title:SetText(L["Auction Stats"])
	title:SetPushedTextOffset(0, 0)

	title:SetTextFontObject(GameFontNormal)
	title:SetHeight(20)
	title:SetWidth(200)
	title:RegisterForDrag("LeftButton")
	title:SetScript("OnDragStart", function(self)
		self.isMoving = true
		AuctionStats.frame:StartMoving()
	end)
	
	title:SetScript("OnDragStop", function(self)
		if( self.isMoving ) then
			self.isMoving = nil
			AuctionStats.frame:StopMovingOrSizing()
		end
	end)
	
	-- Close button, this needs more work not too happy with how it looks
	local button = CreateFrame("Button", nil, self.frame, "UIPanelCloseButton")
	button:SetHeight(27)
	button:SetWidth(27)
	button:SetPoint("TOPRIGHT", -1, -1)
	button:SetScript("OnClick", function()
		HideUIPanel(AuctionStats.frame)
	end)
	
	-- Container frame backdrop
	local backdrop = {
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 16,
		insets = { left = 3, right = 3, top = 5, bottom = 3 }
	}
	
	-- Left 30%ish width panel
	self.leftFrame = CreateFrame("Frame", nil, self.frame)
	self.leftFrame:SetWidth(175)
	self.leftFrame:SetHeight(368)
	self.leftFrame:SetBackdrop(backdrop)
	self.leftFrame:SetBackdropColor(0, 0, 0, 0.65)
	self.leftFrame:SetBackdropBorderColor(0.75, 0.75, 0.75, 0.90)
	self.leftFrame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 12, -20)
	
	-- Date scroll frame
	self.leftFrame.scroll = CreateFrame("ScrollFrame", "AuctionStatsGUIScrollLeft", self.frame, "FauxScrollFrameTemplate")
	self.leftFrame.scroll:SetPoint("TOPLEFT", self.leftFrame, "TOPLEFT", 0, -30)
	self.leftFrame.scroll:SetPoint("BOTTOMRIGHT", self.leftFrame, "BOTTOMRIGHT", -26, 3)
	self.leftFrame.scroll:SetScript("OnVerticalScroll", function() FauxScrollFrame_OnVerticalScroll(22, self.UpdateBrowseGUI) end)
	
	-- Create the date listing for the scroll frame
	self.dateRows = {}
	
	for i=1, MAX_DATE_ROWS do
		local row = CreateFrame("Button", nil, self.frame)
		row:SetWidth(149)
		row:SetHeight(14)
		row:SetTextFontObject(GameFontHighlightSmall)
		row:SetText("*")
		row:GetFontString():SetPoint("LEFT", row, "LEFT", 0, 0)
		row:SetScript("OnClick", showDisplayGUI)
		row:SetScript("OnEnter", showTooltip)
		row:SetScript("OnLeave", hideTooltip)
		
		row.profit = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		row.profit:SetText("*")
		row.profit:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, -1)
		
		if( i > 1 ) then
			row:SetPoint("TOPLEFT", self.dateRows[i - 1], "BOTTOMLEFT", 0, -1)
		else
			row:SetPoint("TOPLEFT", self.leftFrame.scroll, "TOPLEFT", 4, 0)
		end
		
		self.dateRows[i] = row
	end

	-- Check data
	self.gather = CreateFrame("Frame", "AuctionStatsGUIGatherDropdown", self.frame, "UIDropDownMenuTemplate")
	self.gather:SetPoint("TOPLEFT", self.leftFrame, "TOPLEFT", -13, -2)
	self.gather:SetScript("OnEnter", showTooltip)
	self.gather:SetScript("OnLeave", hideTooltip)
	self.gather.tooltip = L["Choose which characters data should be gathered from, from BeanCounter."],
	self.gather:EnableMouse(true)
	self.gather:SetScript("OnShow", function(self)
		UIDropDownMenu_Initialize(self, AuctionStats.InitGatherDropdown)
		UIDropDownMenu_SetWidth(150, self)
	end)
	
	-- Top frame, around 70% width panel
	self.topFrame = CreateFrame("Frame", nil, self.frame)
	self.topFrame:SetWidth(352)
	self.topFrame:SetHeight(40)
	self.topFrame:SetBackdrop(backdrop)
	self.topFrame:SetBackdropColor(0, 0, 0, 0.65)
	self.topFrame:SetBackdropBorderColor(0.75, 0.75, 0.75, 0.90)
	self.topFrame:SetPoint("TOPLEFT", self.leftFrame, "TOPRIGHT", 0, 0)
	
	-- Middle-ish frame, remaining space
	self.middleFrame = CreateFrame("Frame", nil, self.frame)
	self.middleFrame:SetWidth(352)
	self.middleFrame:SetHeight(328)
	self.middleFrame:SetBackdrop(backdrop)
	self.middleFrame:SetBackdropColor(0, 0, 0, 0.65)
	self.middleFrame:SetBackdropBorderColor(0.75, 0.75, 0.75, 0.90)
	self.middleFrame:SetPoint("TOPLEFT", self.topFrame, "BOTTOMLEFT", 0, 0)
	
	-- Date scroll frame
	self.middleFrame.scroll = CreateFrame("ScrollFrame", "AuctionStatsGUIScrollMiddle", self.frame, "FauxScrollFrameTemplate")
	self.middleFrame.scroll:SetPoint("TOPLEFT", self.middleFrame, "TOPLEFT", 0, -4)
	self.middleFrame.scroll:SetPoint("BOTTOMRIGHT", self.middleFrame, "BOTTOMRIGHT", -26, 3)
	self.middleFrame.scroll:SetScript("OnVerticalScroll", function() FauxScrollFrame_OnVerticalScroll(22, self.ViewBreakdown) end)

	-- Sort tabs
	self.sortButtons = {}
	
	for i=1, MAX_DATA_COLUMNS do
		local button = CreateFrame("Button", nil, self.frame)
		button:SetScript("OnClick", sortBreakdownData)
		button:SetHeight(20)
		button:SetTextFontObject(GameFontNormalSmall)
		button:Show()
		
		self.sortButtons[i] = button
	end
	

	self.sortButtons[1].sortType = "itemName"
	self.sortButtons[1]:SetText(L["Item"])
	self.sortButtons[1]:SetWidth(self.sortButtons[1]:GetFontString():GetStringWidth() + 3)
	self.sortButtons[1]:SetPoint("TOPLEFT", self.middleFrame, "TOPLEFT", 4, -2)

	self.sortButtons[2].sortType = "totalMade"
	self.sortButtons[2]:SetText(L["Made"])
	self.sortButtons[2]:SetWidth(self.sortButtons[2]:GetFontString():GetStringWidth() + 3)
	self.sortButtons[2]:SetPoint("TOPLEFT", self.sortButtons[1], "TOPRIGHT", 150, 0)

	self.sortButtons[3].sortType = "totalSpent"
	self.sortButtons[3]:SetText(L["Spent"])
	self.sortButtons[3]:SetWidth(self.sortButtons[3]:GetFontString():GetStringWidth() + 3)
	self.sortButtons[3]:SetPoint("TOPLEFT", self.sortButtons[2], "TOPRIGHT", 15, 0)

	self.sortButtons[4].sortType = "totalProfit"
	self.sortButtons[4]:SetText(L["Profit"])
	self.sortButtons[4]:SetWidth(self.sortButtons[4]:GetFontString():GetStringWidth() + 3)
	self.sortButtons[4]:SetPoint("TOPLEFT", self.sortButtons[3], "TOPRIGHT", 15, 0)

	-- Rows
	self.rows = {}
		
	for i=1, MAX_DATA_ROWS do
		self.rows[i] = {}
		for j=1, MAX_DATA_COLUMNS do
			local row = CreateFrame("Button", nil, self.frame)
			row:SetHeight(15)
			row:SetScript("OnEnter", showTooltip)
			row:SetScript("OnLeave", hideTooltip)
			row:SetTextFontObject(GameFontHighlightSmall)
			row:SetPushedTextOffset(0, 0)
			row:SetText("*")
			row.fs = row:GetFontString()
			row.fs:SetPoint("LEFT", row, "LEFT", 0, 0)
			row.fs:SetHeight(15)
			row.fs:SetJustifyH("LEFT")
			row:Hide()
			
			self.rows[i][j] = row
			
			if( j > 1 ) then
				row:SetWidth(50)
			else
				row:SetWidth(180)
			end


			if( i > 1 ) then
				row:SetPoint("TOPLEFT", self.rows[i - 1][j], "BOTTOMLEFT", 0, -1)
			else
				row:SetPoint("TOPLEFT", self.sortButtons[j], "BOTTOMLEFT", 1, 1)
			end
		end
	end
	
	-- Positioning
	self.frame:SetPoint("CENTER")
end

function AuctionStats:DropdownClicked()
	local server, name = string.split(":", this.value)

	UIDropDownMenu_SetText(string.format("%s - %s", name, server), AuctionStats.gather)	
	AuctionStats.db.profile.gatherData[string.format("%s:%s", server,name)] = this.checked and true or nil
end

function AuctionStats:InitGatherDropdown()
	for server, charData in pairs(BeanCounterDB) do
		if( server ~= "settings" ) then
			for charName in pairs(charData) do
				local charID = string.format("%s:%s", server, charName)
				UIDropDownMenu_AddButton({ value = charID, text = string.format("%s - %s", charName, server), checked = AuctionStats.db.profile.gatherData[charID], keepShownOnClick = true, func = AuctionStats.DropdownClicked })
			end

		end
	end

	UIDropDownMenu_SetText(string.format("%s - %s", UnitName("player"), GetRealmName()), AuctionStats.gather)	
end

-- DEBUG
--[[
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function()
	AuctionStats:CreateGUI()
	AuctionStats.frame:Show()

	frame:UnregisterAllEvents()
end)
]]
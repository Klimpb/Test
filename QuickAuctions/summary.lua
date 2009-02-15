QA.Summary = {}

local Summary = QA.Summary
local L = QuickAuctionsLocals
local gettingData, selectedSummary
local displayData, createdCats, rowDisplay = {}, {}, {}
local MAX_SUMMARY_ROWS = 24
local ROW_HEIGHT = 20

Summary.displayData = displayData

local summaryCats = {
	["Gems"] = {
		text = L["Gems"],
		itemType = "Gem",
		notSubType = "Simple",
		groupedBy = "parent",
		showCatPrice = true,
		auctionClass = L["Gem"],
	}, -- Oh Blizzard, I love you and your fucking stupid inconsistency like "Bracer" vs "Bracers" for scrolls
	["Scrolls"] = {
		text = L["Enchant scrolls"],
		subType = "Item Enhancement",
		groupedBy = "match",
		filter = function(name) return string.match(name, L["Scroll of Enchant (.+)"]) end,
		match = function(name, itemType, subType) local type = string.match(name, L["Scroll of Enchant (.+) %- .+"]) if( type == L["Bracer"] ) then return L["Bracers"] end return type end,
		auctionClass = L["Consumable"],
		auctionSubClass = L["Item Enhancement"],
	},
	["Flasks"] = {
		text = L["Flasks"],
		subType = "Flask",
		groupedBy = "itemLevel",
		auctionClass = L["Consumable"],
		auctionSubClass = L["Flask"],
	},
	["Food"] = {
		text = L["Food"],
		subType = "Food & Drink",
		groupedBy = "itemLevel",
		auctionClass = L["Consumable"],
		auctionSubClass = L["Food & Drink"],
	},
	["Elixirs"] = {
		text = L["Elixirs"],
		subType = "Elixir",
		groupedBy = "itemLevel",
		auctionClass = L["Consumable"],
		auctionSubClass = L["Elixir"],
	},
	["Elemental"] = {
		text = L["Elemental"],
		subType = "Elemental",
		groupedBy = "itemLevel",
		auctionClass = L["Trade Goods"],
		auctionSubClass = L["Elemental"],
	},
	["Herbs"] = {
		text = L["Herbs"],
		subType = "Herb",
		groupedBy = "itemLevel",
		auctionClass = L["Trade Goods"],
		auctionSubClass = L["Herb"],
	},
	["Enchanting"] = {
		text = L["Enchant materials"],
		itemType = L["Trade Goods"],
		groupedBy = "itemLevel",
		auctionClass = L["Trade Goods"],
		auctionSubClass = L["Enchanting"],
	},
	["Glyphs"] = {
		text = L["Glyphs"],
		itemType = "Glyph",
		groupedBy = "subType",
		auctionClass = L["Glyph"],
	},
}

-- Find the ID of the auction categories
function Summary:GetCategoryIndex(searchFor)
	for i=1, select("#", GetAuctionItemClasses()) do
		if( select(i, GetAuctionItemClasses()) == searchFor ) then
			return i
		end
	end
	
	return nil
end

function Summary:GetSubCategoryIndex(parent, searchFor)
	for i=1, select("#", GetAuctionItemSubClasses(parent)) do
		if( select(i, GetAuctionItemSubClasses(parent)) == searchFor ) then
			return i
		end
	end
	
	return nil
end

function Summary:GetData(type)
	if( not AuctionFrame or not AuctionFrame:IsVisible() ) then
		QA:Print(L["Auction House must be visible for you to use this."])
		return
	end

	local data = summaryCats[type]
	
	local classIndex = self:GetCategoryIndex(data.auctionClass)
	local subClassIndex = classIndex and data.auctionSubClass and self:GetSubCategoryIndex(classIndex, data.auctionSubClass) or 0
	
	if( not classIndex or not subClassIndex ) then
		QA:Print(L["Cannot find class or sub class index, localization issue perhaps?"])
		return
	end
	
	gettingData = true
	QA:StartCategoryScan(classIndex, subClassIndex, "summary")
	
	-- Add some progressy bar stuff here
	self.getDataButton:Disable()
	self.stopButton:Enable()
	
	self.progressBar.lastValue = 0
end

-- Show highest price first
local function sortData(a, b)
	if( a.sortID and b.sortID ) then
		return a.sortID > b.sortID
	elseif( a.buyout and b.buyout ) then
		return a.buyout > b.buyout
	elseif( a.name and a.name ) then
		return a.name < b.name
	elseif( a.enabled ) then
		return true
	elseif( b.enabled ) then
		return false	
	end
end

-- Progress bar updating on scan status
local frame = CreateFrame("Frame")
frame:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
frame:SetScript("OnEvent", function()
	if( not gettingData ) then
		return
	end
	
	local self = Summary
	local total = select(2, GetNumAuctionItems("list"))
	local value = (AuctionFrameBrowse.page + 1) * NUM_AUCTION_ITEMS_PER_PAGE
	
	-- Due to retrying, it might go from page 5 -> 4 -> 5 -> 3 -> 5 so just do this to make it look smooth
	if( self.progressBar.lastValue < value ) then
		self.progressBar.lastValue = value
		
		self.progressBar:SetMinMaxValues(0, total)
		self.progressBar:SetValue(self.progressBar.lastValue)
	end
end)

-- We got all the data!
function Summary:Finished()
	gettingData = nil

	self:CompileData()

	-- And now let us rescan data if we want
	self.getDataButton:Enable()
	self.stopButton:Disable()
end

-- Parse it out into what we need
function Summary:CompileData()
	if( not selectedSummary ) then
		return
	end
		
	local summaryData = summaryCats[selectedSummary]
	local index = 0

	-- Reset
	for _, v in pairs(displayData) do v.enabled = nil; v.isParent = nil; v.parent = nil; v.bid = nil; v.buyout = nil; v.owner = nil; v.link = nil; v.sortID = nil; v.quantity = nil; end
	for k in pairs(createdCats) do createdCats[k] = nil end
	
	-- Make sure we got data we want
	for name, data in pairs(QA.auctionData) do
		local name, _, _, itemLevel, _, itemType, subType, stackCount = GetItemInfo(data.link)
		
		-- Is this data we want?
		if( name and ( not summaryData.itemType or summaryData.itemType == itemType ) and ( not summaryData.notSubType or summaryData.notSubType ~= subType ) and ( not summaryData.subType or summaryData.subType == subType ) ) then
			local parent, isParent, parentSort, isValid
			
			-- Cut gems, "Runed Scarlet Ruby" will be parented to "Scarlet Ruby"
			if( summaryData.groupedBy == "parent" ) then
				isValid = true
				parent = nil
				
				-- Stacks beyond 1, so it has to be a parent
				if( stackCount > 1 ) then
					isParent = true
				end
			
			-- Scroll of Enchant Cloak - Speed, will set the parent to "Cloak"
			elseif( summaryData.groupedBy == "match" ) then
				parent = summaryData.match(name, itemType, subType)
				isValid = parent
				
			-- Sub type, like Glyphs so grouped by class
			elseif( summaryData.groupedBy == "subType" ) then
				parent = subType
				isValid = true
			
			-- Grouped by item level
			elseif( summaryData.groupedBy == "itemLevel" ) then
				parent = tostring(itemLevel)
				parentSort = itemLevel
				isValid = true
			end
						
			-- Make sure it's the item we care about, for example Scrolls of Enchant category includes spell threads and such
			-- when we JUST want the scrolls
			if( isValid ) then
				index = index + 1
				if( not displayData[index] ) then displayData[index] = {} end

				local row = displayData[index]
				row.enabled = true
				row.name = name
				row.bid = data.minBid
				row.buyout = data.playerBuyout or data.buyout
				row.owner = data.owner
				row.link = data.link
				row.isParent = isParent
				row.parent = parent
				row.subType = subType
				row.quantity = data.totalFound
				row.itemLevel = itemLevel
				
				
				-- Create the category row now
				if( row.parent and not createdCats[row.parent] ) then
					createdCats[row.parent] = true

					index = index + 1
					if( not displayData[index] ) then displayData[index] = {} end
					local parentRow = displayData[index]
					parentRow.enabled = true
					parentRow.isParent = true
					parentRow.itemLevel = itemLevel
					parentRow.name = row.parent
					parentRow.sortID = parentSort
				end
			end
		end
	end
	
	-- If we're grouping it by the parent, go through and associate all of the parents since we actually know them now
	if( summaryData.groupedBy == "parent" ) then
		for id, data in pairs(displayData) do
			if( data.enabled and data.isParent ) then
				for _, childData in pairs(displayData) do
					if( not childData.parent and string.match(childData.name, data.name .. "$") ) then
						childData.parent = data.name
					end
				end
			end
		end
	end
	
	-- Sorting
	table.sort(displayData, sortData)
	
	-- Update display
	self:Update()
end

-- Text listing for backup things
function Summary:List()
	for _, parentData in pairs(displayData) do
		if( parentData.enabled and parentData.isParent ) then
			-- Print parent
			local link = parentData.link and select(2, GetItemInfo(parentData.link))
			if( parentData.bid and parentData.buyout ) then
				print(string.format("%s: buyout %s / bid %s", link or parentData.name, QA:FormatTextMoney(parentData.buyout), QA:FormatTextMoney(parentData.bid)))
			else
				print(link or parentData.name)
			end
			
			-- Nowwww find all the children
			for _, childData in pairs(displayData) do
				if( childData.enabled and not childData.isParent and childData.parent == parentData.name ) then
					local link = select(2, GetItemInfo(childData.link))
					print(string.format(" -- %s: buyout %s / bid %s", link or childData.name, QA:FormatTextMoney(childData.buyout), QA:FormatTextMoney(childData.bid)))
				end
			end
		end
	end
end

function Summary:Update()
	local self = Summary
	
	-- Reset
	for i=#(rowDisplay), 1, -1 do table.remove(rowDisplay, i) end
	for i=1, MAX_SUMMARY_ROWS do
		self.rows[i]:Hide()
	end
	
	-- Add the index we will want in the correct order, so we can do offsets easily
	for index, data in pairs(displayData) do
		-- Build parent
		if( data.enabled and data.isParent ) then
			table.insert(rowDisplay, index)
			
			-- Is the button supposed to be + or -?
			if( not QuickAuctionsDB.categoryToggle[data.name] ) then
				for index, childData in pairs(displayData) do
					if( childData.enabled and not childData.isParent and childData.parent == data.name ) then
						table.insert(rowDisplay, index)
					end
				end
			end
		end
	end
		
	-- Update scroll bar
	FauxScrollFrame_Update(self.middleFrame.scroll, #(rowDisplay), MAX_SUMMARY_ROWS - 1, ROW_HEIGHT)
	
	-- Figure out active auctions of ours
	QA:CheckActiveAuctions()

	-- Now display
	local summaryData = summaryCats[selectedSummary]
	local offset = FauxScrollFrame_GetOffset(self.middleFrame.scroll)
	local displayIndex = 0
	
	for index, dataID in pairs(rowDisplay) do
		if( index >= offset and displayIndex < MAX_SUMMARY_ROWS ) then
			displayIndex = displayIndex + 1
			
			local row = self.rows[displayIndex]
			local data = displayData[dataID]
			local itemName, link
			if( data.link ) then
				itemName, link = GetItemInfo(data.link)
			end

			row.link = data.link
			
			-- Displaying a parent
			if( data.isParent ) then
				row:SetText(link or data.name)
				row.parent = data.name
				row.button.parent = data.name
				row:ClearAllPoints()
				row:SetPoint("TOPLEFT", self.middleFrame.scroll, "TOPLEFT", row.offsetY + 14, row.offsetX)

				row.buyout:SetText(data.buyout and QA:FormatTextMoney(data.buyout, true) or "")
				row.buyout:SetPoint("TOPRIGHT", row, "TOPRIGHT", -14, -4)
				
				if( data.quantity and QA.activeAuctions[data.name] and QA.activeAuctions[data.name] > 0 ) then
					row.quantity:SetFormattedText("%d (|cff20ff20%d|r)", data.quantity, QA.activeAuctions[data.name])
				elseif( data.quantity ) then
					row.quantity:SetText(data.quantity)
				else
					row.quantity:SetText("")
				end
				
				row.quantity:SetPoint("TOPRIGHT", row, "TOPRIGHT", -134, -4)

				row.button:Show()
				row:Show()

				-- Is the button supposed to be + or -?
				if( QuickAuctionsDB.categoryToggle[data.name] ) then
					row.button:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-UP")
					row.button:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-DOWN")
					row.button:SetHighlightTexture("Interface\\Buttons\\UI-MinusButton-Hilight", "ADD")
				else
					row.button:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-UP")
					row.button:SetPushedTexture("Interface\\Buttons\\UI-PlusButton-DOWN")
					row.button:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight", "ADD")
				end
			-- Orrr a child
			else
				row:SetText(" " .. (summaryData.filter and summaryData.filter(data.name) or data.name))

				row.buyout:SetText(data.buyout and QA:FormatTextMoney(data.buyout, true) or "")
				row.buyout:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, -4)

				if( data.quantity and QA.activeAuctions[data.name] and QA.activeAuctions[data.name] > 0 ) then
					row.quantity:SetFormattedText("%d (|cff20ff20%d|r)", data.quantity, QA.activeAuctions[data.name])
				elseif( data.quantity ) then
					row.quantity:SetText(data.quantity)
				else
					row.quantity:SetText("")
				end
				row.quantity:SetPoint("TOPRIGHT", row, "TOPRIGHT", -120, -4)

				row:ClearAllPoints()
				row:SetPoint("TOPLEFT", self.middleFrame.scroll, "TOPLEFT", row.offsetY, row.offsetX)

				row.button:Hide()
				row:Show()
			end
		end
	end
end

function Summary:CreateGUI()
	if( self.frame ) then
		return
	end
	
	self.frame = CreateFrame("Frame", "QASummaryGUI", UIParent)
	self.frame:SetWidth(550)
	self.frame:SetHeight(474)
	self.frame:SetMovable(true)
	self.frame:EnableMouse(true)
	self.frame:SetClampedToScreen(true)
	self.frame:SetFrameStrata("HIGH")
	self.frame:SetToplevel(true)
	self.frame:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		edgeSize = 26,
		insets = {left = 9, right = 9, top = 9, bottom = 9},
	})
	self.frame:SetScript("OnShow", function(self)
		selectedSummary = "Gems"
		Summary:Update()
	end)
	
	self.frame:Hide()
	
	-- Make it act like a real frame
	table.insert(UISpecialFrames, "QASummaryGUI")
	
	-- Create the title/movy thing
	local texture = self.frame:CreateTexture(nil, "ARTWORK")
	texture:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
	texture:SetPoint("TOP", 0, 12)
	texture:SetWidth(250)
	texture:SetHeight(60)
	
	local title = CreateFrame("Button", nil, self.frame)
	title:SetPoint("TOP", 0, 4)
	title:SetText(L["Quick Auctions"])
	title:SetPushedTextOffset(0, 0)

	title:SetNormalFontObject(GameFontNormal)
	title:SetHeight(20)
	title:SetWidth(200)
	title:RegisterForDrag("LeftButton")
	title:SetScript("OnDragStart", function(self)
		self.isMoving = true
		Summary.frame:StartMoving()
	end)
	
	title:SetScript("OnDragStop", function(self)
		if( self.isMoving ) then
			self.isMoving = nil
			Summary.frame:StopMovingOrSizing()
		end
	end)
	
	-- Close button, this needs more work not too happy with how it looks
	local button = CreateFrame("Button", nil, self.frame, "UIPanelCloseButton")
	button:SetHeight(27)
	button:SetWidth(27)
	button:SetPoint("TOPRIGHT", -1, -1)
	button:SetScript("OnClick", function()
		HideUIPanel(Summary.frame)
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
	self.leftFrame:SetWidth(140)
	self.leftFrame:SetHeight(442)
	self.leftFrame:SetBackdrop(backdrop)
	self.leftFrame:SetBackdropColor(0, 0, 0, 0.65)
	self.leftFrame:SetBackdropBorderColor(0.75, 0.75, 0.75, 0.90)
	self.leftFrame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 12, -20)
	
	-- Top frame, around 70% width panel
	self.topFrame = CreateFrame("Frame", nil, self.frame)
	self.topFrame:SetWidth(387)
	self.topFrame:SetHeight(20)
	self.topFrame:SetBackdrop(backdrop)
	self.topFrame:SetBackdropColor(0, 0, 0, 0.65)
	self.topFrame:SetBackdropBorderColor(0.75, 0.75, 0.75, 0.90)
	self.topFrame:SetPoint("TOPLEFT", self.leftFrame, "TOPRIGHT", 0, 0)
	
	-- Middle-ish frame, remaining space
	self.middleFrame = CreateFrame("Frame", nil, self.frame)
	self.middleFrame:SetWidth(387)
	self.middleFrame:SetHeight(422)
	self.middleFrame:SetBackdrop(backdrop)
	self.middleFrame:SetBackdropColor(0, 0, 0, 0.65)
	self.middleFrame:SetBackdropBorderColor(0.75, 0.75, 0.75, 0.90)
	self.middleFrame:SetPoint("TOPLEFT", self.topFrame, "BOTTOMLEFT", 0, 0)
	
	-- Date scroll frame
	self.middleFrame.scroll = CreateFrame("ScrollFrame", "QASummaryGUIScrollMiddle", self.frame, "FauxScrollFrameTemplate")
	self.middleFrame.scroll:SetPoint("TOPLEFT", self.middleFrame, "TOPLEFT", 0, -4)
	self.middleFrame.scroll:SetPoint("BOTTOMRIGHT", self.middleFrame, "BOTTOMRIGHT", -26, 3)
	self.middleFrame.scroll:SetScript("OnVerticalScroll", function(self, value) FauxScrollFrame_OnVerticalScroll(self, value, ROW_HEIGHT, Summary.Update) end)
	
	-- Progress bar!
	self.progressBar = CreateFrame("StatusBar", nil, self.topFrame)
	self.progressBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-TargetingFrame-BarFill")
	self.progressBar:SetStatusBarColor(0.10, 1.0, 0.10)
	self.progressBar:SetHeight(5)
	self.progressBar:SetHeight(12)
	self.progressBar:SetWidth(360)
	self.progressBar:SetPoint("TOPLEFT", self.topFrame, "TOPLEFT", 4, -4)
	self.progressBar:SetPoint("TOPRIGHT", self.topFrame, "TOPRIGHT", -4, 0)
	self.progressBar:SetMinMaxValues(0, 100)
	self.progressBar:SetValue(0)

	-- Create the select category buttons
	self.catButtons = {}
	
	local function selectType(self)
		for _, button in pairs(Summary.catButtons) do
			button:UnlockHighlight()
		end
		
		selectedSummary = self.id
		
		self:LockHighlight()
		
		if( not gettingData ) then
			Summary.getDataButton:Enable()
		end
		
		Summary:CompileData()
		Summary:Update()
	end
	
	local index = 1
	for id, data in pairs(summaryCats) do
		local row = CreateFrame("Button", nil, self.leftFrame, "UIPanelButtonTemplate")
		row:SetHeight(16)
		row:SetWidth(130)
		row:SetText(data.text)
		row:SetScript("OnClick", selectType)
		row:SetNormalFontObject(GameFontNormalSmall)
		row:SetHighlightFontObject(GameFontHighlightSmall)
		row:SetDisabledFontObject(GameFontDisableSmall)
		row:GetFontString():SetPoint("LEFT", row, "LEFT", 8, 0)
		row.id = id
		
		if( index > 1 ) then
			row:SetPoint("TOPLEFT", self.catButtons[index - 1], "BOTTOMLEFT", 0, -2)
		else
			row:SetPoint("TOPLEFT", self.leftFrame, "TOPLEFT", 6, -6)
		end
		
		self.catButtons[index] = row	
		index = index + 1
	end

	-- And now create our "Get data button"
	local row = CreateFrame("Button", nil, self.leftFrame, "UIPanelButtonTemplate")
	row:SetHeight(16)
	row:SetWidth(90)
	row:SetNormalFontObject(GameFontNormalSmall)
	row:SetHighlightFontObject(GameFontHighlightSmall)
	row:SetDisabledFontObject(GameFontDisableSmall)
	row:SetText(L["Get Data"])
	row:SetScript("OnClick", function()
		if( selectedSummary ) then
			Summary:GetData(selectedSummary)
		end
	end)
	row:SetPoint("TOPLEFT", self.catButtons[index - 1], "BOTTOMLEFT", 0, -4)
	row:Disable()
	
	self.getDataButton = row

	-- And then the stop request one
	local row = CreateFrame("Button", nil, self.leftFrame, "UIPanelButtonTemplate")
	row:SetHeight(16)
	row:SetWidth(40)
	row:SetNormalFontObject(GameFontNormalSmall)
	row:SetHighlightFontObject(GameFontHighlightSmall)
	row:SetDisabledFontObject(GameFontDisableSmall)
	row:SetText(L["Stop"])
	row:SetScript("OnClick", function()
		QA:ForceQueryStop()
	end)
	row:SetPoint("TOPLEFT", self.getDataButton, "TOPRIGHT", 0, 0)
	row:Disable()
	
	self.stopButton = row
	
	-- Rows
	local function toggleCategory(self)
		if( self.parent ) then
			QuickAuctionsDB.categoryToggle[self.parent] = not QuickAuctionsDB.categoryToggle[self.parent]
			Summary:Update()
		end
	end
	
	local function showTooltip(self)
		if( self.link ) then
			if( self.button:IsVisible() ) then
				GameTooltip:SetOwner(self.button, "ANCHOR_LEFT")
			else
				GameTooltip:SetOwner(self, "ANCHOR_LEFT")
			end
			
			GameTooltip:SetHyperlink(self.link)
		end
	end
	
	local function hideTooltip(self)
		GameTooltip:Hide()
	end
		
	self.rows = {}
		
	local offset = 0
	for i=1, MAX_SUMMARY_ROWS do
		local row = CreateFrame("Button", nil, self.middleFrame)
		row:SetWidth(355)
		row:SetHeight(ROW_HEIGHT)
		row:SetNormalFontObject(GameFontHighlightSmall)
		row:SetText("*")
		row:GetFontString():SetPoint("LEFT", row, "LEFT", 0, 0)
		row:SetScript("OnClick", toggleCategory)
		row:SetPushedTextOffset(0, 0)
		--row:SetScript("OnClick", toggleParent)
		row:SetScript("OnEnter", showTooltip)
		row:SetScript("OnLeave", hideTooltip)
		row.offsetY = 6
		
		row.buyout = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		row.bid = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		row.quantity = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		
		row.button = CreateFrame("Button", nil, row)
		row.button:SetScript("OnClick", toggleCategory)
		row.button:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-UP")
		row.button:SetPushedTexture("Interface\\Buttons\\UI-PlusButton-DOWN")
		row.button:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight", "ADD")
		row.button:SetPoint("TOPLEFT", row, "TOPLEFT", -16, -4)
		row.button:SetHeight(14)
		row.button:SetWidth(14)
		
		if( i > 1 ) then
			offset = offset + ROW_HEIGHT - 3
			row.offsetX = -offset
		else
			row.offsetX = 1
		end
		
		row.button:Hide()
		row:Hide()

		self.rows[i] = row
	end
	
	-- Positioning
	self.frame:SetPoint("CENTER")
end	
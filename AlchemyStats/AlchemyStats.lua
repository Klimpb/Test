AlchemyStats = LibStub("AceAddon-3.0"):NewAddon("AlchemyStats", "AceEvent-3.0")

local L = AlchemyStatLocals
local createdMulti
local createdSingle

local tradeNumName = {}

local itemType = {
	["Flask"] = L["Elixir Master"],
	["Elixir"] = L["Elixir Master"],
	["Potion"] = L["Potion Master"],
	["Elemental"] = L["Transmutation Master"],
	["Meta"] = L["Transmutation Master"],
}

function AlchemyStats:OnInitialize()
	self:RegisterEvent("CHAT_MSG_LOOT")
	self:RegisterEvent("TRADE_SKILL_UPDATE")
	self:RegisterEvent("TRADE_SKILL_SHOW", "TRADE_SKILL_UPDATE")

	-- Log messages
	createdMulti = self:Format(LOOT_ITEM_CREATED_SELF_MULTIPLE)
	createdSingle = self:Format(LOOT_ITEM_CREATED_SELF)

	-- Setup basic DB
	self.crtProfile = string.format("%s:%s:%s", GetRealmName(), UnitFactionGroup("player"), UnitName("player"))
	self.stats = {}

	if( not AlchemyStatsData ) then
		AlchemyStatsData = {}
	end

	-- Create our db for this char
	if( not AlchemyStatsData[self.crtProfile] ) then
		AlchemyStatsData[self.crtProfile] = {}
	end
	
	-- Now config DB!
	if( not AlchemyStatsDB ) then
		AlchemyStatsDB = {}
	end
	
	-- Slash commands
	SLASH_ALCHEMYSTAT1 = "/alchemy"
	SLASH_ALCHEMYSTAT2 = "/alchemystats"
	SLASH_ALCHEMYSTAT3 = "/alchemystat"
	SlashCmdList["ALCHEMYSTAT"] = function()
		self:CreateGUI()
		self:UpdateStats()
		self:UpdateGUI()
		self.frame:Show()
	end
end

-- Record number of items made from each skill
function AlchemyStats:TRADE_SKILL_UPDATE()
	if( GetTradeSkillLine() ~= L["Alchemy"] ) then
		return

	end
	

	for i=1, GetNumTradeSkills() do
		local itemLink = GetTradeSkillItemLink(i)
		if( itemLink ) then
			local itemid = string.match(itemLink, "item:([0-9]+):")
			itemid = tonumber(itemid)

			if( itemid ) then
				tradeNumName[itemid] = GetTradeSkillNumMade(i)
			end
		end
	end
end

-- Record things created
function AlchemyStats:CHAT_MSG_LOOT(event, msg)
	local name, amount = string.match(msg, createdMulti)
	if( not name and not amount ) then
		name = string.match(msg, createdSingle)
		amount = 1
	end

	-- No match found, not a creation
	if( not name ) then
		return
	end

	-- Parse out the item id
	local itemid = string.match(name, "item:([0-9]+):")
	local subType = select(7, GetItemInfo(itemid))

	amount = tonumber(amount)
	itemid = tonumber(itemid)

	-- Something messed up
	if( not itemid or not amount or not tradeNumName[itemid] or not itemType[subType] ) then
		return
	end

	local crtItem = itemid
	local totalCreated, totalNumMade, totalProc, noProc, oneProc, twoProc, threeProc, fourProc = 0, 0, 0, 0, 0, 0, 0, 0

	-- We already have stats saved
	if( AlchemyStatsData[self.crtProfile][itemid] ) then
		totalCreated, totalNumMade, totalProc, noProc, oneProc, twoProc, threeProc, fourProc = string.split(":", AlchemyStatsData[self.crtProfile][itemid])
	end

	-- totalCreated = Actual amount of potions made
	totalCreated = totalCreated + amount
	-- totalNumMade = How much we've made not counting procs
	totalNumMade = totalNumMade + tradeNumName[itemid]

	-- Quick and hackish, I'll clean it up later
	if( amount > tradeNumName[itemid] ) then
		local proc = amount - tradeNumName[itemid]
		totalProc = totalProc + proc
		if( proc == 1 ) then
			oneProc = oneProc + 1
		elseif( proc == 2 ) then
			twoProc = twoProc + 1
		elseif( proc == 3 ) then
			threeProc = threeProc + 1
		elseif( proc == 4 ) then
			fourProc = fourProc + 1
		end
	else
		noProc = noProc + 1
	end
	
	-- Store if we could dup these through masteries
	local mastery = self:GetMastery()
	local hasMastery = "no"
	if( mastery and itemType[subType] and itemType[subType] == mastery ) then
		hasMastery = "yes"
	end

	-- Store!
	AlchemyStatsData[self.crtProfile][itemid] = string.format("%s:%s:%s:%s:%s:%s:%s:%s:%s", totalCreated, totalNumMade, totalProc, noProc, oneProc, twoProc, threeProc, fourProc, hasMastery)
end

-- Update our cache of stats
local tempData = {}
function AlchemyStats:UpdateStats()
	-- Restore data
	for i=#(self.stats), 1, -1 do
		table.remove(self.stats, i)
	end
	
	-- Summerize everything
	for id, skillData in pairs(AlchemyStatsData) do
		for itemid, data in pairs(skillData) do
			local totalCreated, totalNumMade, totalProc, noProc, oneProc, twoProc, threeProc, fourProc, hasMastery = string.split(":", data)
			

			if( not tempData[itemid] ) then
				tempData[itemid] = {total = 0, totalMade = 0, numMade = 0, totalProcs = 0, noProc = 0, oneProc = 0, twoProc = 0, threeProc = 0, fourProc = 0}
			end
			
			local name, link = GetItemInfo(itemid)
			
			tempData[itemid].total = tempData[itemid].total + totalCreated
			tempData[itemid].link = link
			tempData[itemid].name = name
			tempData[itemid].itemid = itemid
			tempData[itemid].numMade = tempData[itemid].numMade + totalNumMade
			
			if( hasMastery == "yes" ) then
				totalProc = oneProc + twoProc + threeProc + fourProc
				
				tempData[itemid].isMastery = true
				tempData[itemid].totalMade = tempData[itemid].totalMade + totalProc + noProc
				tempData[itemid].totalProcs = tempData[itemid].totalProcs + totalProc
				tempData[itemid].noProc = tempData[itemid].noProc + noProc
				tempData[itemid].oneProc = tempData[itemid].oneProc + oneProc
				tempData[itemid].twoProc = tempData[itemid].twoProc + twoProc
				tempData[itemid].threeProc = tempData[itemid].threeProc + threeProc
				tempData[itemid].fourProc = tempData[itemid].fourProc + fourProc
			end
		end
	end
	
	-- Now calculate totals
	for itemid, data in pairs(tempData) do
		data.procChance = 0
		data.oneChance = 0
		data.twoChance = 0
		data.threeChance = 0
		data.fourChance = 0

		if( data.totalMade > 0 ) then
			if( data.totalProcs > 0 ) then
				data.procChance = data.totalProcs / data.numMade * 100
			end
			
			if( data.oneProc > 0 ) then
				data.oneChance = data.oneProc / data.totalProcs * 100
			end
			
			if( data.twoProc > 0 ) then
				data.twoChance = data.twoProc / data.totalProcs * 100
			end

			if( data.threeProc > 0 ) then
				data.threeChance = data.threeProc / data.totalProcs * 100
			end

			if( data.fourProc > 0 ) then
				data.fourChance = data.fourProc / data.totalProcs * 100
			end
		end
		
		-- Annd now add everything
		table.insert(self.stats, data)
		tempData[itemid] = nil
	end
end

function AlchemyStats:Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99" .. L["Alchemy"] .. "|r: " .. msg)
end

function AlchemyStats:Format(text)
	text = string.gsub(text, "([%^%(%)%.%[%]%*%+%-%?])", "%%%1")
	text = string.gsub(text, "%%s", "(.+)")
	text = string.gsub(text, "%%d", "(%-?%%d+)")
	return text
end

function AlchemyStats:GetMastery()
	if( not self.tooltip ) then
		self.tooltip = CreateFrame("GameTooltip", "AlchStatTooltip", UIParent, "GameTooltipTemplate")
		self.tooltip:SetOwner(UIParent, "ANCHOR_NONE")
	end

	local _, _, offset, numSpells = GetSpellTabInfo(1)
	for i=1, numSpells do
		self.tooltip:SetSpell(offset + i, BOOKTYPE_SPELL)
		local spell = self.tooltip:GetSpell()
		
		if( spell == L["Elixir Master"] or spell == L["Potion Master"] or spell == L["Transmutation Master"] ) then
			return spell
		end
	end
	
	return nil
end

-- GUI
local function sortColumns(self)
	if( self.type ) then
		if( self.type ~= AlchemyStats.frame.sortType ) then
			AlchemyStats.frame.sortOrder = false
			AlchemyStats.frame.sortType = self.type
		else
			AlchemyStats.frame.sortOrder = not AlchemyStats.frame.sortOrder
		end

		AlchemyStats:UpdateGUI()
	end
end

local function sortList(a, b)
	if( not a ) then
		return true
	elseif( not b ) then
		return false
	end
	
	if( AlchemyStats.frame.sortOrder ) then
		local type = AlchemyStats.frame.sortType
		if( a[type] and b[type] ) then
			if( a[type] == b[type] ) then
				return a.name > b.name
			end
			
			return a[type] < b[type]
		end
		
		return a.name < b.name
	else
		local type = AlchemyStats.frame.sortType
		if( a[type] and b[type] ) then
			if( a[type] == b[type] ) then
				return a.name > b.name
			end
			
			return a[type] > b[type]
		end
		
		return a.name > b.name
	end
end

local function createHeader(text, id, offset)
	local header = CreateFrame("Button", nil, AlchemyStats.frame)
	header:SetPoint("TOPLEFT", offset, -20)
	header:SetScript("OnClick", sortColumns)
	header:SetTextFontObject(GameFontNormal)
	header:SetText(text)
	header:SetHeight(20)
	header:SetWidth(header:GetFontString():GetStringWidth() + 2)
	header.type = id
	
	return header
end

local function OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
	GameTooltip:SetHyperlink(self.link)
end

local function OnLeave(self)
	GameTooltip:Hide()
end

function AlchemyStats:CreateGUI()
	if( self.frame ) then
		return
	end
	
	-- Container frame
	self.frame = CreateFrame("Frame", "AlchemyStatsFrame", UIParent)
	self.frame:SetWidth(700)
	self.frame:SetHeight(325)
	self.frame:SetMovable(true)
	self.frame:EnableMouse(true)
	self.frame:SetClampedToScreen(true)
	self.frame.sortType = "total"
	self.frame.sortOrder = false
	self.frame:Hide()
	
	self.frame:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true,
		tileSize = 32,
		edgeSize = 32,
		insets = {left = 10, right = 10, top = 10, bottom = 10},
	})
		
	-- Location
	self.frame:SetPoint("CENTER")
	
	-- Create the title/movy thing
	local texture = self.frame:CreateTexture(nil, "ARTWORK")
	texture:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
	texture:SetPoint("TOP", 0, 12)
	texture:SetWidth(200)
	texture:SetHeight(60)
	
	local title = CreateFrame("Button", nil, self.frame)
	title:SetPoint("TOP", 0, 4)
	title:SetText(L["Alchemy Stats"])
	title:SetPushedTextOffset(0, 0)

	title:SetTextFontObject(GameFontNormal)
	title:SetHeight(20)
	title:SetWidth(200)
	title:RegisterForDrag("LeftButton")
	title:SetScript("OnDragStart", function(self)
		self.isMoving = true
		AlchemyStats.frame:StartMoving()
	end)
	
	title:SetScript("OnDragStop", function(self)
		if( self.isMoving ) then
			self.isMoving = nil
			AlchemyStats.frame:StopMovingOrSizing()
		end
	end)
	
	-- Close button
	local button = CreateFrame("Button", nil, self.frame, "UIPanelCloseButton")
	button:SetPoint("TOPRIGHT", -4, -4)
	button:SetScript("OnClick", function()
		HideUIPanel(AlchemyStats.frame)
	end)
	
	-- Create our headers
	local itemHeader = createHeader(L["Item"], "name", 15)
	local createdHeader = createHeader(L["Created"], "total", 160)
	local procChanceHeader = createHeader(L["Procs"], "procChance", 225)
	local oneProcHeader = createHeader(L["One"], "oneChance", 310)
	local twoProcHeader = createHeader(L["Two"], "twoChance", 370)
	local threeProcHeader = createHeader(L["Three"], "threeChance", 420)
	local fourProcHeader = createHeader(L["Four"], "fourChance", 480)
	
	-- Our GUI rows
	self.rows = {}
	
	for i=1, 15 do
		local item = CreateFrame("Button", nil, self.frame)
		item:SetWidth(145)
		item:SetHeight(10)
		item:SetTextFontObject(GameFontHighlightSmall)
		item:SetText("*")
		item:GetFontString():SetPoint("LEFT", item, "LEFT", 0, 0)
		item:SetPushedTextOffset(0, 0)
		item:SetScript("OnEnter", OnEnter)
		item:SetScript("OnLeave", OnLeave)
		
		local created = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		local procChance = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		local oneProc = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		local twoProc = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		local threeProc = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		local fourProc = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		
		if( i > 1 ) then
			item:SetPoint("TOPLEFT", self.rows[i - 1], "TOPLEFT", 0, -18)
			created:SetPoint("TOPLEFT", self.rows[i - 1].created, "TOPLEFT", 0, -18)
			procChance:SetPoint("TOPLEFT", self.rows[i - 1].procChance, "TOPLEFT", 0, -18)
			oneProc:SetPoint("TOPLEFT", self.rows[i - 1].oneProc, "TOPLEFT", 0, -18)
			twoProc:SetPoint("TOPLEFT", self.rows[i - 1].twoProc, "TOPLEFT", 0, -18)
			threeProc:SetPoint("TOPLEFT", self.rows[i - 1].threeProc, "TOPLEFT", 0, -18)
			fourProc:SetPoint("TOPLEFT", self.rows[i - 1].fourProc, "TOPLEFT", 0, -18)
		else
			item:SetPoint("TOPLEFT", itemHeader, "TOPLEFT", 1, -25)
			created:SetPoint("TOPLEFT", createdHeader, "TOPLEFT", 1, -25)
			procChance:SetPoint("TOPLEFT", procChanceHeader, "TOPLEFT", 1, -25)
			oneProc:SetPoint("TOPLEFT", oneProcHeader, "TOPLEFT", 1, -25)
			twoProc:SetPoint("TOPLEFT", twoProcHeader, "TOPLEFT", 1, -25)
			threeProc:SetPoint("TOPLEFT", threeProcHeader, "TOPLEFT", 1, -25)
			fourProc:SetPoint("TOPLEFT", fourProcHeader, "TOPLEFT", 1, -25)
		end
		
		self.rows[i] = item
		self.rows[i].fs = item:GetFontString()
		self.rows[i].created = created
		self.rows[i].procChance = procChance
		self.rows[i].oneProc = oneProc
		self.rows[i].twoProc = twoProc
		self.rows[i].threeProc = threeProc
		self.rows[i].fourProc = fourProc
	end

	-- Scroll frame
	self.frame.scroll = CreateFrame("ScrollFrame", "AlchemyStatsScrollFrame", self.frame, "FauxScrollFrameTemplate")
	self.frame.scroll:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 25, -30)
	self.frame.scroll:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -35, 10)
	self.frame.scroll:SetScript("OnVerticalScroll", function() FauxScrollFrame_OnVerticalScroll(22, self.UpdateGUI) end)
		
	-- Make it act like a real frame
	self.frame:SetAttribute("UIPanelLayout-defined", true)
	self.frame:SetAttribute("UIPanelLayout-enabled", true)
 	self.frame:SetAttribute("UIPanelLayout-area", "doublewide")
	self.frame:SetAttribute("UIPanelLayout-whileDead", true)
	table.insert(UISpecialFrames, "AlchemyStatsFrame")
	
	local backdrop = {bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true,
			tileSize = 9,
			edgeSize = 9,
			insets = { left = 2, right = 2, top = 2, bottom = 2 }}
	
	-- Now make the two container backdrops for style
	self.leftContainer = CreateFrame("Frame", nil, self.frame)
	self.leftContainer:SetFrameStrata("LOW")
	self.leftContainer:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 10, -20)
	self.leftContainer:SetHeight(295)
	self.leftContainer:SetWidth(520)
	
	self.leftContainer:SetBackdrop(backdrop)	
	self.leftContainer:SetBackdropColor(0, 0, 0, 1)
	self.leftContainer:SetBackdropBorderColor(0.75, 0.75, 0.75, 1)

	-- Stat frame
	self.rightContainer = CreateFrame("Frame", nil, self.frame)
	self.rightContainer:SetFrameStrata("LOW")
	self.rightContainer:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -35, -20)
	self.rightContainer:SetHeight(295)
	self.rightContainer:SetWidth(130)
	
	self.rightContainer:SetBackdrop(backdrop)	
	self.rightContainer:SetBackdropColor(0, 0, 0, 1)
	self.rightContainer:SetBackdropBorderColor(0.75, 0.75, 0.75, 1)

	-- STATS
	-- Total made
	local text = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	text:SetPoint("TOPLEFT", self.rightContainer, "TOPLEFT", 8, -5)
	text:SetTextColor(GameFontNormal:GetTextColor())
	text:SetText(L["Total Made"])

	self.totalMade = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	self.totalMade:SetPoint("TOPLEFT", self.rightContainer, "TOPLEFT", 90, -5)

	-- Total made
	local text = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	text:SetPoint("TOPLEFT", self.rightContainer, "TOPLEFT", 8, -20)
	text:SetTextColor(GameFontNormal:GetTextColor())
	text:SetText(L["Total Procs"])

	self.totalProc = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	self.totalProc:SetPoint("TOPLEFT", self.rightContainer, "TOPLEFT", 90, -20)

	-- One Proc
	local text = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	text:SetPoint("TOPLEFT", self.rightContainer, "TOPLEFT", 8, -45)
	text:SetTextColor(GameFontNormal:GetTextColor())
	text:SetText(L["One Proc"])

	self.oneProc = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	self.oneProc:SetPoint("TOPLEFT", self.rightContainer, "TOPLEFT", 90, -45)

	-- Two Proc
	local text = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	text:SetPoint("TOPLEFT", self.rightContainer, "TOPLEFT", 8, -60)
	text:SetTextColor(GameFontNormal:GetTextColor())
	text:SetText(L["Two Proc"])

	self.twoProc = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	self.twoProc:SetPoint("TOPLEFT", self.rightContainer, "TOPLEFT", 90, -60)

	-- Three Proc
	local text = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	text:SetPoint("TOPLEFT", self.rightContainer, "TOPLEFT", 8, -75)
	text:SetTextColor(GameFontNormal:GetTextColor())
	text:SetText(L["Three Proc"])

	self.threeProc = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	self.threeProc:SetPoint("TOPLEFT", self.rightContainer, "TOPLEFT", 90, -75)

	-- Four Proc
	local text = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	text:SetPoint("TOPLEFT", self.rightContainer, "TOPLEFT", 8, -90)
	text:SetTextColor(GameFontNormal:GetTextColor())
	text:SetText(L["Four Proc"])

	self.fourProc = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	self.fourProc:SetPoint("TOPLEFT", self.rightContainer, "TOPLEFT", 90, -90)
end

function AlchemyStats:UpdateGUI()
	self = AlchemyStats
	if( not self.frame ) then
		return
	end
	

	table.sort(self.stats, sortList)
	FauxScrollFrame_Update(self.frame.scroll, #(self.stats), 15, 22)
	
	local potionsMade, totalProcs, oneProc, twoProc, threeProc, fourProc = 0, 0, 0, 0, 0, 0
	local usedRows = 0

	for id, data in pairs(self.stats) do
		potionsMade = potionsMade + data.total
		totalProcs = totalProcs + data.totalProcs
		oneProc = oneProc + data.oneProc
		twoProc = twoProc + data.twoProc
		threeProc = threeProc + data.threeProc
		fourProc = fourProc + data.fourProc
		
		if( id >= FauxScrollFrame_GetOffset(self.frame.scroll) and usedRows < 15 ) then
			usedRows = usedRows + 1
			
			local row = self.rows[usedRows]
			
			row:SetText(data.link)
			row.created:SetText(data.total)
			row.link = data.link
			
			if( data.isMastery ) then
				row.procChance:SetFormattedText("%.2f%% (%d)", data.procChance, data.totalProcs)
				row.oneProc:SetFormattedText("%.2f%%", data.oneChance)
				row.twoProc:SetFormattedText("%.2f%%", data.twoChance)
				row.threeProc:SetFormattedText("%.2f%%", data.threeChance)
				row.fourProc:SetFormattedText("%.2f%%", data.fourChance)
			else
				row.procChance:SetText("---")
				row.oneProc:SetText("---")
				row.twoProc:SetText("---")
				row.threeProc:SetText("---")
				row.fourProc:SetText("---")
			end
			
			-- Word wrapping
			row.fs:SetWidth(145)
			row.fs:SetHeight(10)
			row.fs:SetJustifyH("LEFT")
			
			row.created:Show()
			row.procChance:Show()
			row.oneProc:Show()
			row.twoProc:Show()
			row.threeProc:Show()
			row.fourProc:Show()
			row:Show()
		end
	end
	
	self.totalMade:SetText(potionsMade)
	self.totalProc:SetText(totalProcs)
	self.oneProc:SetText(oneProc)
	self.twoProc:SetText(twoProc)
	self.threeProc:SetText(threeProc)
	self.fourProc:SetText(fourProc)
	
	-- Hide unused
	for i=usedRows + 1, 15 do
		local row = self.rows[i]
		row.created:Show()
		row.procChance:Hide()
		row.oneProc:Hide()
		row.twoProc:Hide()
		row.threeProc:Hide()
		row.fourProc:Hide()
		row:Hide()
	end
end